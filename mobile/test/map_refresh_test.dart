import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/create_incident/draft_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'package:qalapulse/features/map/city_map.dart';
import 'package:qalapulse/features/map/map_screen.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'support.dart';
import 'publication_recovery_test.dart' show readyDraft, otherCategory;
import 'widgets_test.dart' show localized;

void main() {
  testWidgets(
    'open map updates after publication and confirmation, and allows manual refresh',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var incidents = <Incident>[];
      var queries = 0;
      final store = MemoryTokens(
        const SessionTokens('access', 'refresh', testUser),
      );
      final api = ApiClient(
        store,
        client: Dio()
          ..httpClientAdapter = FakeAdapter((r) async {
            if (r.path == '/incidents/nearby') {
              queries++;
              return jsonBody({
                'items': incidents.map((i) => i.toJson()).toList(),
                'has_more': false,
              });
            }
            if (r.path == '/incidents') {
              incidents = [sampleIncident()];
              return jsonBody(incidents.single.toJson(), 201);
            }
            incidents = [incidents.single.copyWith(status: 'resolved')];
            return jsonBody({'status': 'resolved'}, 201);
          }),
      );
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(api),
          tokenStoreProvider.overrideWithValue(store),
          preferencesProvider.overrideWithValue(prefs),
          categoriesProvider.overrideWith((_) async => []),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localized(const SizedBox(height: 600, child: MapScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CityMap>(find.byType(CityMap)).incidents, isEmpty);
      await settleAction(
        tester,
        container.read(draftProvider.notifier).update(readyDraft),
      );
      await settleAction(
        tester,
        container.read(draftProvider.notifier).publish(),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CityMap>(find.byType(CityMap)).incidents.single.id,
        'incident-1',
      );
      await settleAction(
        tester,
        container.read(repositoryProvider).confirm('incident-1', 'resolved'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CityMap>(find.byType(CityMap)).incidents.single.status,
        'resolved',
      );
      final before = queries;
      await tester.tap(find.byTooltip('Обновить карту'));
      await tester.pumpAndSettle();
      expect(queries, before + 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search follows viewport and category; late previous result cannot replace new markers; error retries',
    (tester) async {
      final delayed = Completer<ResponseBody>();
      final requests = <RequestOptions>[];
      var fail = false;
      final api = ApiClient(
        MemoryTokens(),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((r) async {
            requests.add(r);
            if (r.queryParameters['latitude'] == 44.0) return delayed.future;
            if (fail) {
              return jsonBody({
                'error': {'code': 'unavailable'},
              }, 503);
            }
            return jsonBody({
              'items': [sampleIncident().copyWith(id: 'new-view').toJson()],
              'has_more': true,
            });
          }),
      );
      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(api),
          categoriesProvider.overrideWith((_) async => [otherCategory]),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: localized(const SizedBox(height: 600, child: MapScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Показаны первые 200'), findsOneWidget);
      tester.widget<CityMap>(find.byType(CityMap)).onViewportChanged!(
        const LatLng(44, 77),
        3500,
      );
      await tester.pump();
      await tester.tap(find.text('Искать здесь'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(requests.last.queryParameters['latitude'], 44);
      expect(requests.last.queryParameters['radius'], 3500);
      tester.widget<CityMap>(find.byType(CityMap)).onViewportChanged!(
        const LatLng(45, 78),
        2500,
      );
      await tester.pump();
      await tester.tap(find.text('Искать здесь'));
      await tester.pumpAndSettle();
      delayed.complete(
        jsonBody({
          'items': [sampleIncident().copyWith(id: 'old-view').toJson()],
        }),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CityMap>(find.byType(CityMap)).incidents.single.id,
        'new-view',
      );
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Другое').last);
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['latitude'], 45);
      expect(requests.last.queryParameters['category_id'], 'other');
      fail = true;
      await tester.tap(find.byTooltip('Обновить карту'));
      await tester.pumpAndSettle();
      expect(find.text('Повторить'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CityMap>(find.byType(CityMap)).incidents.single.id,
        'new-view',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dragging CityMap reports a new viewport to its screen', (
    tester,
  ) async {
    LatLng? moved;
    double? radius;
    await tester.pumpWidget(
      localized(
        SizedBox(
          height: 400,
          child: CityMap(
            center: const LatLng(43.2, 76.8),
            onViewportChanged: (point, distance) {
              moved = point;
              radius = distance;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CityMap), const Offset(180, 0));
    await tester.pumpAndSettle();
    expect(moved, isNotNull);
    expect(moved, isNot(const LatLng(43.2, 76.8)));
    expect(radius, inInclusiveRange(100, 20000));
  });
}
