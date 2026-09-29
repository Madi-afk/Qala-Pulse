import 'package:flutter/foundation.dart';

abstract final class Environment {
  static String mediaUrl(String url) {
    final uri = Uri.parse(url);
    return uri.path.startsWith('/api/v1/media/')
        ? Uri.parse(apiBaseUrl).resolve(uri.path).toString()
        : url;
  }

  static const configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl => configuredUrl.isNotEmpty
      ? configuredUrl
      : kIsWeb
      ? 'http://localhost:8000/api/v1'
      : 'http://10.0.2.2:8000/api/v1';
  static const firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );
}
