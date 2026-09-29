import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'support.dart';

void main() {
  test(
    'repository parses real wire format and passes pagination filters',
    () async {
      late RequestOptions request;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) async {
          request = options;
          return jsonBody({
            'items': [sampleIncident().toJson()],
          });
        });
      final repository = IncidentRepository(
        ApiClient(MemoryTokens(), client: dio),
      );
      final result = await repository.feed(
        page: 2,
        sort: 'priority',
        authorId: 'user-1',
      );
      expect(result.single.title, 'Яма на дороге');
      expect(request.queryParameters['page'], 2);
      expect(request.queryParameters['author_id'], 'user-1');
      expect(request.queryParameters['sort'], 'priority');
    },
  );

  test(
    'parallel expired requests rotate tokens once and retry with new access token',
    () async {
      final store = MemoryTokens(
        const SessionTokens('old-access', 'old-refresh', testUser),
      );
      var refreshCount = 0;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) async {
          if (options.headers['Authorization'] == 'Bearer old-access') {
            return jsonBody({
              'error': {'code': 'invalid_token'},
            }, 401);
          }
          return jsonBody({'ok': true});
        });
      final refresh = Dio()
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return jsonBody({
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        });
      final api = ApiClient(store, client: dio, refreshClient: refresh);
      final results = await Future.wait([
        api.get('/users/me'),
        api.get('/users/me'),
        api.get('/users/me'),
      ]);
      expect(results.every((r) => r['ok'] == true), isTrue);
      expect(refreshCount, 1);
      expect(store.value!.refresh, 'new-refresh');
    },
  );

  test(
    'temporary refresh failure preserves secure session for later retry',
    () async {
      final store = MemoryTokens(
        const SessionTokens('old', 'refresh', testUser),
      );
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((_) async => jsonBody({}, 401));
      final refresh = Dio()
        ..httpClientAdapter = FakeAdapter(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
      await expectLater(
        ApiClient(store, client: dio, refreshClient: refresh).get('/users/me'),
        throwsA(isA<DioException>()),
      );
      expect(store.value, isNotNull);
    },
  );

  test(
    'auth provider has loading, success and error and stores tokens only via TokenStore',
    () async {
      final store = MemoryTokens();
      var fail = false;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter(
          (_) async => fail
              ? jsonBody({
                  'error': {'code': 'invalid_credentials'},
                }, 401)
              : jsonBody({
                  'access_token': 'access',
                  'refresh_token': 'refresh',
                  'user': testUser.toJson(),
                }),
        );
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          apiProvider.overrideWithValue(ApiClient(store, client: dio)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      final loading = <bool>[];
      container.listen(
        authProvider,
        (previous, next) => loading.add(next.isLoading),
      );
      await container
          .read(authProvider.notifier)
          .authenticate(email: 'test@example.com', password: 'password');
      expect(loading, contains(true));
      expect(container.read(authProvider).asData!.value!.id, 'user-1');
      expect(store.value!.access, 'access');
      fail = true;
      await container
          .read(authProvider.notifier)
          .authenticate(email: 'test@example.com', password: 'wrong');
      expect(container.read(authProvider).hasError, isTrue);
    },
  );
}
