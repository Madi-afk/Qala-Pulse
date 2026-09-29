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

class FlakyRepository extends IncidentRepository {
  FlakyRepository() : super(ApiClient(MemoryTokens()));
  final keys = <String>[];
  final payloads = <Map<String, dynamic>>[];
  @override
  Future<Incident> publish(Map<String, dynamic> payload, String key) async {
    keys.add(key);
    payloads.add(payload);
    if (keys.length == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/incidents'),
        type: DioExceptionType.connectionError,
      );
    }
    return sampleIncident();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'draft restores photo, coordinates, content and owner isolation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DraftStore(prefs, 'alice');
      const draft = IncidentDraft(
        key: 'stable-key',
        photoPath: '/photos/one.jpg',
        latitude: 43.2,
        longitude: 76.8,
        description: 'Люк открыт',
        title: 'Люк',
        step: 4,
      );
      await store.save(draft);
      expect(DraftStore(prefs, 'alice').load(), draft);
      expect(DraftStore(prefs, 'bob').load(), isNull);
      await store.clear();
      expect(store.load(), isNull);
    },
  );

  test(
    'network failure preserves frozen payload and retry creates only one logical incident',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = FlakyRepository();
      final tokens = MemoryTokens(
        const SessionTokens('access', 'refresh', testUser),
      );
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(tokens),
          repositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      final controller = container.read(draftProvider.notifier);
      await controller.update(
        const IncidentDraft(
          key: 'publication-key',
          uploadId: 'upload-id',
          photoPath: 'photo.jpg',
          latitude: 43.2,
          longitude: 76.8,
          title: 'Яма на дороге',
          description: 'Глубокая яма',
          categoryId: 'road_damage',
          severity: 7,
          reviewed: true,
          step: 6,
        ),
      );
      await expectLater(controller.publish(), throwsA(isA<DioException>()));
      final saved = DraftStore(prefs, testUser.id).load()!;
      expect(saved.waitingToSend, isTrue);
      expect(saved.pendingPayload, isNotNull);
      expect(saved.photoPath, 'photo.jpg');
      // Simulate a process restart before retry.
      final restarted = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(tokens),
          repositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(restarted.dispose);
      await restarted.read(authProvider.future);
      final result = await restarted.read(draftProvider.notifier).publish();
      expect(result.id, 'incident-1');
      expect(repository.keys, ['publication-key', 'publication-key']);
      expect(repository.payloads[1], repository.payloads[0]);
      expect(DraftStore(prefs, testUser.id).load(), isNull);
    },
  );

  test('rapid edits persist the final value in order', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(MemoryTokens()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    final controller = container.read(draftProvider.notifier);
    final draft = container.read(draftProvider);
    await Future.wait(
      List.generate(
        20,
        (index) =>
            controller.update(draft.copyWith(description: 'edit-$index')),
      ),
    );
    expect(DraftStore(prefs, 'guest').load()!.description, 'edit-19');
  });
}
