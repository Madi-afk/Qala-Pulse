import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/create_incident/draft_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('definitive refresh 401 updates auth provider', () async {
    final store = MemoryTokens(const SessionTokens('old', 'refresh', testUser));
    final api = ApiClient(
      store,
      client: Dio()
        ..httpClientAdapter = FakeAdapter((_) async => jsonBody({}, 401)),
      refreshClient: Dio()
        ..httpClientAdapter = FakeAdapter((_) async => jsonBody({}, 401)),
    );
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        apiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await expectLater(api.get('/users/me'), throwsA(isA<DioException>()));
    expect(store.value, isNull);
    expect(container.read(authProvider).asData?.value, isNull);
  });

  test(
    'disabled category rejection unlocks preserved draft after restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = MemoryTokens(
        const SessionTokens('access', 'refresh', testUser),
      );
      final api = ApiClient(
        store,
        client: Dio()
          ..httpClientAdapter = FakeAdapter(
            (_) async => jsonBody({
              'error': {'code': 'invalid_category'},
            }, 422),
          ),
      );
      final overrides = [
        preferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(store),
        apiProvider.overrideWithValue(api),
        repositoryProvider.overrideWithValue(IncidentRepository(api)),
      ];
      final container = ProviderContainer(overrides: overrides);
      await container.read(authProvider.future);
      final controller = container.read(draftProvider.notifier);
      await controller.update(
        const IncidentDraft(
          key: 'rejected-key',
          uploadId: 'image',
          photoPath: 'photo.jpg',
          latitude: 43.2,
          longitude: 76.8,
          title: 'Яма',
          description: 'Описание',
          reviewed: true,
          step: 6,
        ),
      );
      await expectLater(controller.publish(), throwsA(isA<DioException>()));
      container.dispose();
      final restarted = ProviderContainer(overrides: overrides);
      addTearDown(restarted.dispose);
      await restarted.read(authProvider.future);
      final saved = restarted.read(draftProvider);
      expect(saved.pendingPayload, isNull);
      expect(saved.step, 4);
      expect(saved.photoPath, 'photo.jpg');
      expect(saved.description, 'Описание');
      expect(saved.latitude, 43.2);
      expect(saved.key, isNot('rejected-key'));
    },
  );
}
