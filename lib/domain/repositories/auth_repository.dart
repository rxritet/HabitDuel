import '../entities/user.dart';

/// Result returned after a successful registration.
class RegisterResult {
  const RegisterResult({required this.user, required this.token});
  final User user;
  final String token;
}

/// Result returned after a successful login.
class LoginResult {
  const LoginResult({required this.user, required this.token});
  final User user;
  final String token;
}

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  /// Register a new account. Throws [Failure] on error.
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  });

  /// Login with email + password. Throws [Failure] on error.
  Future<LoginResult> login({
    required String email,
    required String password,
  });

  /// Returns `true` if a JWT token is persisted locally.
  Future<bool> hasToken();

  /// Clears persisted auth data (logout).
  Future<void> logout();
}
