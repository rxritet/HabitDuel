import '../../repositories/auth_repository.dart';

/// Вариант использования: аутентификация по email + пароль.
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
