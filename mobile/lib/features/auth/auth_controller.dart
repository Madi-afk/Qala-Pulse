import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/token_store.dart';
import '../../shared/models/models.dart';

final authProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async =>
      (await ref.read(tokenStoreProvider).read())?.user;

  Future<void> authenticate({
    required String email,
    required String password,
    String? name,
    String language = 'ru',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref
          .read(apiProvider)
          .post(name == null ? '/auth/login' : '/auth/register', {
            'email': email.trim(),
            'password': password,
            if (name != null) 'display_name': name.trim(),
            if (name != null) 'preferred_language': language,
          });
      final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      await ref
          .read(tokenStoreProvider)
          .write(
            SessionTokens(
              response['access_token'] as String,
              response['refresh_token'] as String,
              user,
            ),
          );
      return user;
    });
  }

  Future<void> logout() async {
    final store = ref.read(tokenStoreProvider);
    final session = await store.read();
    try {
      if (session != null) {
        await ref
            .read(apiProvider)
            .dio
            .post<void>(
              '/auth/logout',
              data: {'refresh_token': session.refresh},
            );
      }
    } finally {
      await store.clear();
      state = const AsyncData(null);
    }
  }
}
