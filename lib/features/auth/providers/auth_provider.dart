import 'package:family_budget/features/auth/models/auth_session.dart';
import 'package:family_budget/features/auth/providers/auth_session_revision_pod.dart';
import 'package:family_budget/features/auth/repository/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/talker_pod.dart';
import '../models/user.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<AuthSession?> build() async {
    ref.watch(authSessionRevisionProvider);
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).login(email: email, password: password);
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).loginWithGoogle();
    });
  }

  Future<void> loginWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).loginWithApple();
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> refreshUser() async {
    final currentSession = state.value;
    if (currentSession == null) return;

    try {
      final updatedUser = await ref.read(authRepositoryProvider).getUser();

      state = AsyncData(currentSession.copyWith(user: updatedUser));
    } catch (e, st) {
      ref.read(talkerProvider).error('Не вдалося оновити юзера після покупки', e, st);
    }
  }
}

@riverpod
AppUser? currentUser(Ref ref) {
  return ref.watch(authProvider).value?.user;
}
