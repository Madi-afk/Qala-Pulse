import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/shared/models/models.dart';

const testUser = AppUser(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Тест',
);

class MemoryTokens implements TokenStore {
  MemoryTokens([this.value]);
  SessionTokens? value;
  @override
  Future<SessionTokens?> read() async => value;
  @override
  Future<void> write(SessionTokens tokens) async {
    value = tokens;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

Incident sampleIncident() => Incident(
  id: 'incident-1',
  authorId: testUser.id,
  categoryId: 'road_damage',
  title: 'Яма на дороге',
  description: 'Проверка',
  latitude: 43.2389,
  longitude: 76.8897,
  severity: 7,
  priorityScore: 70,
  status: 'published',
  confirmationCount: 2,
  createdAt: DateTime.utc(2026, 9, 15),
);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
