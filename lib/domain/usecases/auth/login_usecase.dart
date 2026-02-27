import '../../repositories/auth_repository.dart';

/// Use case: login with email + password.
class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<LoginResult> call({
    required String email,
    required String password,
  }) {
    return _repo.login(email: email, password: password);
  }
}
