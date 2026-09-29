import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Initialize at startup'),
);
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() =>
      Locale(ref.read(preferencesProvider).getString('language') ?? 'ru');
  Future<void> setLanguage(String language) async {
    await ref.read(preferencesProvider).setString('language', language);
    state = Locale(language);
  }
}
