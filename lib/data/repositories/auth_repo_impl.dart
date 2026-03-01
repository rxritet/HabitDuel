import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';

/// Реализация [AuthRepository].
///
/// Вызывает удалённый источник данных и сохраняет/удаляет JWT-токен
/// через [FlutterSecureStorage].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDS, this._storage);

  final AuthRemoteDataSource _remoteDS;
  final FlutterSecureStorage _storage;

  @override
  Future<RegisterResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDS.register(
      username: username,
      email: email,
      password: password,
    );

    // Сохраняем токен
    await _storage.write(key: kTokenKey, value: response.token);
    await _storage.write(key: kUserIdKey, value: response.user.id);
    await _storage.write(key: kUsernameKey, value: response.user.username);

    return RegisterResult(user: response.user, token: response.token);
  }

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDS.login(
      email: email,
      password: password,
    );

    // Сохраняем токен
    await _storage.write(key: kTokenKey, value: response.token);
    await _storage.write(key: kUserIdKey, value: response.user.id);
    await _storage.write(key: kUsernameKey, value: response.user.username);

    return LoginResult(user: response.user, token: response.token);
  }

  @override
  Future<bool> hasToken() async {
    final token = await _storage.read(key: kTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kUserIdKey);
    await _storage.delete(key: kUsernameKey);
  }
}
