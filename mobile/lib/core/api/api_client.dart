import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/environment.dart';
import '../storage/token_store.dart';
import '../storage/session_manager.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
final apiProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);

class ApiClient {
  ApiClient(this.tokens, {Dio? client, Dio? refreshClient})
    : sessions = SessionManager(tokens),
      dio = client ?? Dio(),
      refreshDio = refreshClient ?? Dio() {
    for (final client in [dio, refreshDio]) {
      client.options = BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 110),
        sendTimeout: const Duration(seconds: 30),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final startedGeneration = sessions.generation;
          final session = await sessions.read();
          options.extra.putIfAbsent(
            'sessionGeneration',
            () => startedGeneration,
          );
          options.extra.putIfAbsent('sessionUser', () => session?.user.id);
          if (options.extra['sessionGeneration'] != sessions.generation ||
              options.extra['sessionUser'] != session?.user.id) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          }
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.access}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 ||
              error.requestOptions.extra['retried'] == true ||
              error.requestOptions.path.startsWith('/auth/')) {
            return handler.next(error);
          }
          try {
            final generation = error.requestOptions.extra['sessionGeneration'];
            if (generation != sessions.generation) return handler.next(error);
            final session = await sessions.read();
            if (session == null) return handler.next(error);
            if (session.user.id != error.requestOptions.extra['sessionUser']) {
              return handler.next(error);
            }
            if (error.requestOptions.headers['Authorization'] ==
                'Bearer ${session.access}') {
              if (_refreshGeneration != generation || _refreshing == null) {
                _refreshGeneration = generation as int;
                final pending = _refresh(session, generation);
                _refreshing = pending;
                pending.whenComplete(() {
                  if (identical(_refreshing, pending)) _refreshing = null;
                }).ignore();
              }
              await _refreshing;
            }
            final options = error.requestOptions;
            options.extra['retried'] = true;
            if (options.data is FormData) {
              options.data = (options.data as FormData).clone();
            }
            final refreshed = await sessions.read();
            if (sessions.generation != generation ||
                refreshed == null ||
                refreshed.user.id != session.user.id) {
              return handler.next(error);
            }
            options.headers['Authorization'] = 'Bearer ${refreshed.access}';
            handler.resolve(await dio.fetch<dynamic>(options));
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }
  final TokenStore tokens;
  final SessionManager sessions;
  final Dio dio;
  final Dio refreshDio;
  Future<void>? _refreshing;
  int? _refreshGeneration;

  Future<void> _refresh(SessionTokens session, int generation) async {
    try {
      final result = (await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': session.refresh},
      )).data!;
      await sessions.replace(
        SessionTokens(
          result['access_token'] as String,
          result['refresh_token'] as String,
          session.user,
        ),
        generation,
        expectedRefresh: session.refresh,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await sessions.clear(expiration: true, expectedGeneration: generation);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async =>
      (await dio.get<Map<String, dynamic>>(path, queryParameters: query)).data!;
  Future<Map<String, dynamic>> post(
    String path,
    Object data, {
    String? key,
  }) async => (await dio.post<Map<String, dynamic>>(
    path,
    data: data,
    options: Options(headers: key == null ? null : {'Idempotency-Key': key}),
  )).data!;
}
