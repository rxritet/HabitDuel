import '../entities/user.dart';

/// Данные после успешной регистрации.
class RegisterResult {
  const RegisterResult({required this.user, required this.token});
  final User user;
  final String token;
}

/// Данные после успешной аутентификации.
class LoginResult {
  const LoginResult({required this.user, required this.token});
  final User user;
  final String token;
}

/// Абстрактный контракт аутентификации.
abstract class AuthRepository {
  /// Регистрирует аккаунт. Бросает [Failure] при ошибке.
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  });

  /// Аутентифицируется по email + пароль. Бросает [Failure] при ошибке.
  Future<LoginResult> login({
    required String email,
    required String password,
  });

  /// Возвращает `true`, если JWT-токен сохранён локально.
  Future<bool> hasToken();

  /// Удаляет данные аутентификации (выход).
  Future<void> logout();
}
