import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qalapulse/app/router.dart';
import 'package:qalapulse/core/api/api_client.dart';
import 'package:qalapulse/core/localization/locale_controller.dart';
import 'package:qalapulse/core/localization/strings.dart';
import 'package:qalapulse/core/theme/app_theme.dart';
import 'package:qalapulse/features/auth/auth_controller.dart';
import 'package:qalapulse/features/feed/incident_repository.dart';
import 'package:qalapulse/shared/models/models.dart';
import 'package:qalapulse/shared/widgets/incident_card.dart';
import 'package:qalapulse/shared/widgets/status_badge.dart';
import 'support.dart';

class PreviewAuth extends AuthController {
  PreviewAuth(this.user);
  final AppUser? user;
  @override
  Future<AppUser?> build() async => user;
}

Future<void> mountApp(
  WidgetTester tester, {
  String language = 'ru',
  double scale = 1,
  double width = 390,
  bool empty = false,
  bool guest = false,
  String path = '/home',
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({'language': language});
  final preferences = await SharedPreferences.getInstance();
  final router = createRouter();
  router.go(path);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        tokenStoreProvider.overrideWithValue(MemoryTokens()),
        authProvider.overrideWith(() => PreviewAuth(guest ? null : testUser)),
        feedProvider.overrideWith(
          (ref, sort) async => empty ? [] : [sampleIncident()],
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => RepaintBoundary(
          key: const ValueKey('preview'),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: ref.watch(localeProvider),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('build/redesign/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final language in ['ru', 'kk']) {
    for (final scale in [1.0, 1.8]) {
      testWidgets('home, profile and auth fit $language at text scale $scale', (
        tester,
      ) async {
        await mountApp(
          tester,
          language: language,
          scale: scale,
          width: scale == 1 ? 390 : 320,
        );
        expect(tester.takeException(), isNull);
        if (scale == 1) await capture(tester, 'home-$language');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('priority-incident-1')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byType(StatusBadge), findsWidgets);
        expect(tester.takeException(), isNull);
        if (scale == 1) await capture(tester, 'feed-$language');
        await tester.tap(find.byIcon(Icons.person_outline).last);
        await tester.pumpAndSettle();
        expect(find.text(testUser.email), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (scale == 1) await capture(tester, 'profile-$language');
        await tester.pumpWidget(const SizedBox.shrink());
        await mountApp(
          tester,
          language: language,
          scale: scale,
          width: scale == 1 ? 390 : 320,
          guest: true,
          path: '/auth',
        );
        expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (scale == 1) await capture(tester, 'auth-$language');
      });
    }
  }

  testWidgets('home report button reaches the guest sign-in flow', (
    tester,
  ) async {
    await mountApp(tester, guest: true, empty: true);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Сообщить о проблеме').first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
    await tester.tap(find.text('Войдите, чтобы продолжить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
  });

  testWidgets(
    'password visibility and register mode preserve entered credentials',
    (tester) async {
      await mountApp(tester, guest: true, path: '/auth');
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'resident@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'Test-password-123',
      );
      await tester.tap(find.byTooltip('Показать пароль'));
      await tester.pumpAndSettle();
      final passwordField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('auth-password')),
      );
      expect(passwordField.controller!.text, 'Test-password-123');
      expect(find.byTooltip('Скрыть пароль'), findsOneWidget);
      await tester.ensureVisible(find.text('Создать аккаунт'));
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-name')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
            .controller!
            .text,
        'resident@example.com',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('language changes from profile are persisted', (tester) async {
    await mountApp(tester, path: '/profile');
    await tester.ensureVisible(find.text('Қазақша'));
    await tester.tap(find.text('Қазақша'));
    await tester.pumpAndSettle();
    expect(find.text('Сіздің үлесіңіз'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('language'), 'kk');
  });

  testWidgets(
    'long resolution status and metadata fit narrow large-text cards',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('kk'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: IncidentCard(
                  sampleIncident().copyWith(
                    status: 'resolved_pending_confirmation',
                    confirmationCount: 12345,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('12345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
