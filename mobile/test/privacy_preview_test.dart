import 'dart:convert';
import 'dart:io';
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

const photoDraft = IncidentDraft(
  key: 'privacy-key',
  uploadId: 'first-image',
  photoPath: 'sample.png',
  title: 'Test',
  description: 'Keep this description',
  step: 6,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File(
    '../backend/tests/fixtures/privacy/astronaut.png',
  ).readAsBytesSync();

  test(
    'full frame reupload persists new id, requires review and respects publication lock',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((request) async {
            calls++;
            expect(request.path, '/uploads/images');
            final fields = Map.fromEntries((request.data as FormData).fields);
            expect(fields['full_frame'], 'true');
            return jsonBody({'id': 'new-masked-image'}, 201);
          }),
      );
      final scope = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(api.tokens),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(scope.dispose);
      await scope.read(authProvider.future);
      final controller = scope.read(draftProvider.notifier);
      await controller.update(
        photoDraft.copyWith(photoBase64: base64Encode(bytes), reviewed: true),
      );
      expect(await controller.uploadPhoto(), 'first-image');
      expect(calls, 0);
      expect(await controller.uploadPhoto(fullFrame: true), 'new-masked-image');
      final saved = DraftStore(prefs, testUser.id).load()!;
      expect(saved.uploadId, 'new-masked-image');
      expect(saved.reviewed, false);
      expect(saved.description, photoDraft.description);
      await controller.update(
        saved.copyWith(
          pendingPayload: {
            'upload_ids': ['new-masked-image'],
          },
        ),
      );
      await expectLater(
        controller.uploadPhoto(fullFrame: true),
        throwsStateError,
      );
      expect(calls, 1);
    },
  );

  test(
    'failed full frame upload preserves the local photo and existing upload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final api = ApiClient(
        MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((request) async {
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            );
          }),
      );
      final scope = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(api.tokens),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(scope.dispose);
      await scope.read(authProvider.future);
      final controller = scope.read(draftProvider.notifier);
      await controller.update(
        photoDraft.copyWith(photoBase64: base64Encode(bytes), reviewed: true),
      );
      await expectLater(
        controller.uploadPhoto(fullFrame: true),
        throwsA(isA<DioException>()),
      );
      final saved = DraftStore(prefs, testUser.id).load()!;
      expect(saved.uploadId, 'first-image');
      expect(saved.reviewed, false);
      expect(saved.photoBase64, base64Encode(bytes));
      expect(saved.description, photoDraft.description);
    },
  );

  for (final language in ['ru', 'kk']) {
    testWidgets(
      'public preview must load before confirming privacy ($language)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await DraftStore(
          prefs,
          testUser.id,
        ).save(photoDraft.copyWith(photoBase64: base64Encode(bytes)));
        var failPreview = true;
        final api = ApiClient(
          MemoryTokens(const SessionTokens('access', 'refresh', testUser)),
          client: Dio()
            ..httpClientAdapter = FakeAdapter((request) async {
              if (request.path.endsWith('/preview')) {
                if (failPreview) {
                  return jsonBody({
                    'error': {'code': 'storage_unavailable'},
                  }, 503);
                }
                return ResponseBody.fromBytes(
                  bytes,
                  200,
                  headers: {
                    Headers.contentTypeHeader: ['image/png'],
                  },
                );
              }
              return jsonBody({
                'id': 'first-image',
                'privacy_method': 'local_opencv_no_regions_v1',
              });
            }),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(prefs),
              tokenStoreProvider.overrideWithValue(api.tokens),
              apiProvider.overrideWithValue(api),
              categoriesProvider.overrideWith((_) async => []),
            ],
            child: localized(
              const SizedBox(height: 1400, child: CreateScreen()),
              language: language,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNull,
        );
        final loader = find.byWidgetPredicate(
          (w) => w is OutlinedButton && w.child is Text,
        );
        await tester.ensureVisible(loader.first);
        await tester.tap(loader.first);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNull,
        );
        failPreview = false;
        await tester.tap(loader.first);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile))
              .onChanged,
          isNotNull,
        );
        expect(find.byType(Image), findsWidgets);
        final images = tester.widgetList<Image>(find.byType(Image));
        expect(images.any((image) => image.fit == BoxFit.contain), true);
        expect(
          find.textContaining(language == 'ru' ? 'не гарантирует' : 'кепілдік'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
