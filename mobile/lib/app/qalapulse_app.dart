import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/strings.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class QalaPulseApp extends ConsumerStatefulWidget {
  const QalaPulseApp({super.key});
  @override
  ConsumerState<QalaPulseApp> createState() => _QalaPulseAppState();
}

class _QalaPulseAppState extends ConsumerState<QalaPulseApp> {
  late final GoRouter router = createRouter();
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'QalaPulse',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: router,
    locale: ref.watch(localeProvider),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
