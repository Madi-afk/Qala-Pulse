import 'dart:async';
import 'token_store.dart';

/// Serializes secure-store writes and fences responses belonging to old sessions.
class SessionManager {
  SessionManager(this.tokens);
  final TokenStore tokens;
  final changes = StreamController<SessionTokens?>.broadcast(sync: true);
  Future<void> _writes = Future.value();
  int generation = 0;
  bool expired = false;

  int beginChange() => ++generation;
  Future<SessionTokens?> read() async {
    final before = generation;
    await _writes;
    final result = await tokens.read();
    return before == generation ? result : read();
  }

  Future<bool> replace(
    SessionTokens next,
    int expectedGeneration, {
    String? expectedRefresh,
  }) async {
    var applied = false;
    _writes = _writes.catchError((Object _) {}).then((_) async {
      if (generation != expectedGeneration) return;
      if (expectedRefresh != null &&
          (await tokens.read())?.refresh != expectedRefresh) {
        return;
      }
      if (generation != expectedGeneration) return;
      await tokens.write(next);
      if (generation != expectedGeneration) return;
      expired = false;
      applied = true;
      changes.add(next);
    });
    await _writes;
    return applied;
  }

  Future<void> clear({bool expiration = false, int? expectedGeneration}) async {
    if (expectedGeneration != null && generation != expectedGeneration) return;
    final operation = ++generation;
    expired = expiration;
    changes.add(null);
    _writes = _writes.catchError((Object _) {}).then((_) async {
      await tokens.clear();
      if (generation == operation) changes.add(null);
    });
    await _writes;
  }
}
