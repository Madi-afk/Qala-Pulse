import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/strings.dart';
import 'package:qalapulse/features/auth/recovery_screen.dart';
import 'support.dart';

void main() {
  testWidgets(
    'Recovery preserves email on failure, loads, retries and succeeds',
    (tester) async {
      final pending = Completer<ResponseBody>();
      var requests = 0;
      final api = ApiClient(
        MemoryTokens(),
        client: Dio()
          ..httpClientAdapter = FakeAdapter((options) async {
            expect(options.path, '/auth/forgot-password');
            expect(options.data['email'], 'resident@example.com');
            requests++;
            if (requests == 1) return pending.future;
            return jsonBody({'status': 'accepted'}, 202);
          }),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiProvider.overrideWithValue(api)],
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RecoveryScreen(),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'resident@example.com',
      );
      await tester.tap(find.text('Отправить ссылку'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.complete(
        jsonBody({
          'error': {'code': 'service_unavailable'},
        }, 503),
      );
      await tester.pumpAndSettle();
      expect(find.text('resident@example.com'), findsOneWidget);
      await tester.tap(find.text('Отправить ссылку'));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(
        find.textContaining('Если активная учётная запись существует'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
    },
  );
}
