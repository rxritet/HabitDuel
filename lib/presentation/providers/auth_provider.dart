import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'core_providers.dart';

// ─── Состояние аутентификации ───────────────────────────────────────────

/// Глобальное состояние аутентификации.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final User user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.error]);
  final String? error;
}

// ─── Обработчик аутентификации ─────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  /// Проверяет наличие сохранённой сессии при запуске.
  Future<void> checkSession() async {
    state = const AuthLoading();
    final hasToken = await _repo.hasToken();
    if (hasToken) {
      // Токен найден — считаем пользователя аутентифицированным.
      // Полная версия проверяла бы токен через /users/me,
      // но в MVP доверяем сохранённому токену.
      state = const Authenticated(User(id: '', username: ''));
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.register(
        username: username,
        email: email,
        password: password,
      );
      state = Authenticated(result.user);
    } on Failure catch (e) {
      state = Unauthenticated(e.message);
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.login(email: email, password: password);
      state = Authenticated(result.user);
    } on Failure catch (e) {
      state = Unauthenticated(e.message);
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const Unauthenticated();
  }
}

// ─── Провайдер ─────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
