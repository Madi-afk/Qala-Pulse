import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalapulse/core/storage/token_store.dart';
import 'package:qalapulse/shared/models/models.dart';

const testUser = AppUser(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Тест',
);

/// Drive Dio's queued events using the widget test clock rather than real I/O.
Future<T> settleAction<T>(WidgetTester tester, Future<T> action) async {
  var done = false;
  late T result;
  Object? failure;
  StackTrace? trace;
  action.then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object error, StackTrace stack) {
      failure = error;
      trace = stack;
      done = true;
    },
  );
  for (var tick = 0; tick < 100 && !done; tick++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done, isTrue, reason: 'Asynchronous widget action did not settle');
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return result;
}

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
