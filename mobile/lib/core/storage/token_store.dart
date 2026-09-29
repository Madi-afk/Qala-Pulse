import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../shared/models/models.dart';

class SessionTokens {
  const SessionTokens(this.access, this.refresh, this.user);
  final String access;
  final String refresh;
  final AppUser user;
}

abstract interface class TokenStore {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;
  static const key = 'qalapulse.session.v1';
  @override
  Future<SessionTokens?> read() async {
    final raw = await storage.read(key: key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SessionTokens(
      json['access'] as String,
      json['refresh'] as String,
      AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> write(SessionTokens tokens) => storage.write(
    key: key,
    value: jsonEncode({
      'access': tokens.access,
      'refresh': tokens.refresh,
      'user': tokens.user.toJson(),
    }),
  );
  @override
  Future<void> clear() => storage.delete(key: key);
}
