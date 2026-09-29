import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/token_store.dart';
import '../../shared/models/models.dart';

final authProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final sessions = ref.read(apiProvider).sessions;
    final subscription = sessions.changes.stream.listen((session) {
      state = AsyncData(session?.user);
    });
    ref.onDispose(subscription.cancel);
    return (await sessions.read())?.user;
  }

  Future<void> authenticate({
    required String email,
    required String password,
    String? name,
    String language = 'ru',
  }) async {
    final sessions = ref.read(apiProvider).sessions;
    final generation = sessions.beginChange();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final response = await ref
          .read(apiProvider)
          .post(name == null ? '/auth/login' : '/auth/register', {
            'email': email.trim(),
            'password': password,
            if (name != null) 'display_name': name.trim(),
            if (name != null) 'preferred_language': language,
          });
      final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
      await sessions.replace(
        SessionTokens(
          response['access_token'] as String,
          response['refresh_token'] as String,
          user,
        ),
        generation,
      );
      return user;
    });
    if (sessions.generation == generation) state = result;
  }

  Future<void> logout() async {
    final api = ref.read(apiProvider);
    final session = await api.sessions.read();
    await api.sessions.clear();
    if (session != null) {
      await ref
          .read(apiProvider)
          .dio
          .post<void>('/auth/logout', data: {'refresh_token': session.refresh});
    }
  }
}
