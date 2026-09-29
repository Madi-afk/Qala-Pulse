import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/create_incident/create_screen.dart';
import 'package:qalapulse/features/create_incident/draft_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'support.dart';
import 'widgets_test.dart' show localized;

const readyDraft = IncidentDraft(
  key: 'stable-request-key',
  uploadId: 'image-id',
  photoPath: 'photo.jpg',
  latitude: 43.2,
  longitude: 76.8,
  categoryId: 'road_damage',
  title: 'Сохранённая яма',
  description: 'Сохранённое описание',
  reviewed: true,
  step: 6,
);
const otherCategory = IncidentCategory(
  id: 'other',
  code: 'other',
  nameRu: 'Другое',
  nameKk: 'Басқа',
  description: '',
  baseSeverity: 3,
  icon: 'other',
  color: '#087E70',
);

ProviderContainer scope(SharedPreferences prefs, ApiClient api) =>
    ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(api.tokens),
        apiProvider.overrideWithValue(api),
        categoriesProvider.overrideWith((_) async => [otherCategory]),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'server commits then times out; restart retries same payload and creates one record',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final records = <String, String>{};
      final keys = <String>[];
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((request) async {
            final key = request.headers['Idempotency-Key'] as String;
            keys.add(key);
            final payload = jsonEncode(request.data);
            if (records.containsKey(key)) expect(records[key], payload);
            records.putIfAbsent(key, () => payload);
            if (keys.length == 1) {
              throw DioException(
                requestOptions: request,
                type: DioExceptionType.receiveTimeout,
              );
            }
            return jsonBody(sampleIncident().toJson(), 201);
          }),
      );
      var container = scope(prefs, api);
      await container.read(authProvider.future);
      await container.read(draftProvider.notifier).update(readyDraft);
      await expectLater(
        container.read(draftProvider.notifier).publish(),
        throwsA(isA<DioException>()),
      );
      container.dispose();
      container = scope(prefs, api);
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      await container.read(draftProvider.notifier).publish();
      expect(keys, [readyDraft.key, readyDraft.key]);
      expect(records.length, 1);
      expect(DraftStore(prefs, testUser.id).load(), isNull);
    },
  );

  for (final code in ['idempotency_conflict', 'upload_already_used']) {
    test('$code preserves key until cancellation is confirmed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var offline = true;
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((r) async {
            if (r.path.endsWith('/cancel')) {
              if (offline) {
                throw DioException(
                  requestOptions: r,
                  type: DioExceptionType.connectionError,
                );
              }
              return jsonBody({'status': 'cancelled'});
            }
            return jsonBody({
              'error': {'code': code},
            }, 409);
          }),
      );
      final container = scope(prefs, api);
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      final controller = container.read(draftProvider.notifier);
      await controller.update(readyDraft);
      await expectLater(controller.publish(), throwsA(isA<DioException>()));
      expect(container.read(draftProvider).key, readyDraft.key);
      expect(container.read(draftProvider).pendingPayload, isNotNull);
      await expectLater(
        controller.cancelPending(discard: true),
        throwsA(isA<DioException>()),
      );
      expect(DraftStore(prefs, testUser.id).load()!.key, readyDraft.key);
      offline = false;
      await controller.cancelPending();
      final editable = container.read(draftProvider);
      expect(editable.key, isNot(readyDraft.key));
      expect(editable.pendingPayload, isNull);
      expect(editable.photoPath, readyDraft.photoPath);
      expect(editable.step, 4);
    });
  }

  test(
    'cancel of an already committed attempt recovers the incident without deleting it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((r) async {
            expect(r.path, '/incidents/publications/stable-request-key/cancel');
            return jsonBody({
              'status': 'published',
              'incident': sampleIncident().toJson(),
            });
          }),
      );
      await DraftStore(prefs, testUser.id).save(
        readyDraft.copyWith(
          pendingPayload: {'title': readyDraft.title},
          waitingToSend: true,
        ),
      );
      final container = scope(prefs, api);
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      final result = await container
          .read(draftProvider.notifier)
          .cancelPending(discard: true);
      expect(result!.id, 'incident-1');
      expect(DraftStore(prefs, testUser.id).load(), isNull);
    },
  );

  testWidgets(
    '422 returns to editable form with saved data and explanation after restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter(
            (_) async => jsonBody({
              'error': {'code': 'invalid_category'},
            }, 422),
          ),
      );
      final first = scope(prefs, api);
      await first.read(authProvider.future);
      await first.read(draftProvider.notifier).update(readyDraft);
      Object? failure;
      try {
        await settleAction(
          tester,
          first.read(draftProvider.notifier).publish(),
        );
      } catch (error) {
        failure = error;
      }
      expect(failure, isA<DioException>());
      first.dispose();
      final restored = scope(prefs, api);
      addTearDown(restored.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: restored,
          child: localized(const SizedBox(height: 1000, child: CreateScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Категория больше недоступна'),
        findsOneWidget,
      );
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Заголовок',
      );
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Исправленный заголовок');
      await tester.pumpAndSettle();
      final draft = DraftStore(prefs, testUser.id).load()!;
      expect(draft.title, 'Исправленный заголовок');
      expect(draft.description, readyDraft.description);
      expect(draft.photoPath, readyDraft.photoPath);
      expect(draft.latitude, readyDraft.latitude);
      expect(draft.pendingPayload, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
