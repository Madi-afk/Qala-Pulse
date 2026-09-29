# QalaPulse Mobile

Flutter / Material 3, Riverpod, GoRouter и Dio. Интерфейс на русском и казахском.

Полные инструкции, тестовые аккаунты, конфигурация backend и ограничения приведены в [README проекта](../README.md).

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Адрес выше предназначен для Android Emulator. Для браузерной демонстрации используйте `http://localhost:8000/api/v1` и `flutter run -d chrome --web-port=8080`.

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

Фото и черновик сохраняются локально, токены — через `flutter_secure_storage`. Публикация требует проверки AI-предложения человеком. Mock AI доступен без ключей. Проверки на физических устройствах и iOS описаны в [отчёте](../docs/implementation-status.md).
