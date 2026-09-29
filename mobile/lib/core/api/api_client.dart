import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/environment.dart';
import '../storage/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
final apiProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);

class ApiClient {
  ApiClient(this.tokens, {Dio? client, Dio? refreshClient})
    : dio = client ?? Dio(),
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
          final session = await tokens.read();
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
            final session = await tokens.read();
            if (session == null) return handler.next(error);
            if (error.requestOptions.headers['Authorization'] ==
                'Bearer ${session.access}') {
              _refreshing ??= _refresh(
                session,
              ).whenComplete(() => _refreshing = null);
              await _refreshing;
            }
            final options = error.requestOptions;
            options.extra['retried'] = true;
            if (options.data is FormData) {
              options.data = (options.data as FormData).clone();
            }
            final refreshed = await tokens.read();
            options.headers['Authorization'] = 'Bearer ${refreshed?.access}';
            handler.resolve(await dio.fetch<dynamic>(options));
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }
  final TokenStore tokens;
  final Dio dio;
  final Dio refreshDio;
  Future<void>? _refreshing;

  Future<void> _refresh(SessionTokens session) async {
    try {
      final result = (await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': session.refresh},
      )).data!;
      await tokens.write(
        SessionTokens(
          result['access_token'] as String,
          result['refresh_token'] as String,
          session.user,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) await tokens.clear();
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
