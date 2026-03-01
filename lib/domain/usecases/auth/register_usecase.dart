import '../../repositories/auth_repository.dart';

/// Вариант использования: регистрация нового пользователя.
class RegisterUseCase {
  const RegisterUseCase(this._repo);
  final AuthRepository _repo;

  Future<RegisterResult> call({
    required String username,
    required String email,
    required String password,
  }) {
    return _repo.register(
      username: username,
      email: email,
      password: password,
    );
  }
}
