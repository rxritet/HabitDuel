import '../../repositories/auth_repository.dart';

/// Use case: register a new user.
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
