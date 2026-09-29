import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/app/router.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/localization/strings.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/auth/auth_screen.dart';
import 'package:qalapulse/features/create_incident/draft_controller.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final status in [200, 401]) {
    for (final replace in [false, true]) {
      test(
        'late refresh $status cannot change session after logout (replace: $replace)',
        () async {
          final store = MemoryTokens(
            const SessionTokens('old', 'old-refresh', testUser),
          );
          final started = Completer<void>(),
              response = Completer<ResponseBody>();
          final nextUser = testUser.copyWith(id: 'another-user');
          final api = ApiClient(
            store,
            client: Dio()
              ..httpClientAdapter = FakeAdapter(
                (r) async => r.path == '/auth/login'
                    ? jsonBody({
                        'access_token': 'replacement',
                        'refresh_token': 'replacement-refresh',
                        'user': nextUser.toJson(),
                      })
                    : jsonBody({}, r.path == '/auth/logout' ? 204 : 401),
              ),
            refreshClient: Dio()
              ..httpClientAdapter = FakeAdapter((_) {
                started.complete();
                return response.future;
              }),
          );
          final container = ProviderContainer(
            overrides: [
              tokenStoreProvider.overrideWithValue(store),
              apiProvider.overrideWithValue(api),
            ],
          );
          addTearDown(container.dispose);
          await container.read(authProvider.future);
          final pending = expectLater(
            api.get('/users/me'),
            throwsA(isA<DioException>()),
          );
          await started.future;
          await container.read(authProvider.notifier).logout();
          if (replace) {
            await container
                .read(authProvider.notifier)
                .authenticate(email: 'other@example.com', password: 'test');
          }
          response.complete(
            jsonBody({
              'access_token': 'stale',
              'refresh_token': 'stale-refresh',
            }, status),
          );
          await pending;
          expect(store.value?.access, replace ? 'replacement' : null);
          expect(
            container.read(authProvider).asData!.value?.id,
            replace ? 'another-user' : null,
          );
        },
      );
    }
  }

  test(
    'temporary refresh failure keeps auth and original owner draft',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = MemoryTokens(
        const SessionTokens('old', 'refresh', testUser),
      );
      final api = ApiClient(
        store,
        client: Dio()
          ..httpClientAdapter = FakeAdapter((_) async => jsonBody({}, 401)),
        refreshClient: Dio()
          ..httpClientAdapter = FakeAdapter(
            (r) async => throw DioException(
              requestOptions: r,
              type: DioExceptionType.connectionTimeout,
            ),
          ),
      );
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(store),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      await container
          .read(draftProvider.notifier)
          .update(
            const IncidentDraft(
              key: 'owner-key',
              description: 'Private owner draft',
            ),
          );
      await expectLater(api.get('/users/me'), throwsA(isA<DioException>()));
      expect(container.read(authProvider).asData!.value, testUser);
      expect(container.read(draftProvider).description, 'Private owner draft');
      expect(api.sessions.expired, isFalse);
    },
  );

  testWidgets(
    'expired session offers login and keeps draft isolated across accounts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = MemoryTokens(
        const SessionTokens('old', 'refresh', testUser),
      );
      var loginUser = testUser.copyWith(id: 'bob');
      final api = ApiClient(
        store,
        client: Dio()
          ..httpClientAdapter = FakeAdapter((r) async {
            if (r.path == '/auth/login') {
              return jsonBody({
                'access_token': 'new',
                'refresh_token': 'new-refresh',
                'user': loginUser.toJson(),
              });
            }
            if (r.path == '/users/me') return jsonBody({}, 401);
            return jsonBody({'items': []});
          }),
        refreshClient: Dio()
          ..httpClientAdapter = FakeAdapter((_) async => jsonBody({}, 401)),
      );
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(store),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      await container
          .read(draftProvider.notifier)
          .update(
            const IncidentDraft(
              key: 'alice-only',
              description: 'Original private draft',
            ),
          );
      final router = createRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Object? failure;
      try {
        await settleAction(tester, api.get('/users/me'));
      } catch (error) {
        failure = error;
      }
      expect(failure, isA<DioException>());
      await tester.pumpAndSettle();
      expect(
        find.text('Сессия завершена. Войдите снова; ваш черновик сохранён.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Войти'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await settleAction(
        tester,
        container
            .read(authProvider.notifier)
            .authenticate(email: 'bob@example.com', password: 'test'),
      );
      await tester.pumpAndSettle();
      expect(container.read(draftProvider).description, isEmpty);
      expect(
        DraftStore(prefs, testUser.id).load()!.description,
        'Original private draft',
      );
      loginUser = testUser;
      await settleAction(
        tester,
        container
            .read(authProvider.notifier)
            .authenticate(email: testUser.email, password: 'test'),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(draftProvider).description,
        'Original private draft',
      );
    },
  );
}
