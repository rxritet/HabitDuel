import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Прикрепляет `Authorization: Bearer <jwt>` ко всем исходящим запросам.
///
/// При ответе 401 сохранённый токен удаляется, UI переходит на экран входа.
class JwtInterceptor extends Interceptor {
  JwtInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: kTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Удаляем данные аутентификации — провайдер перенаправит на экран входа.
      await _storage.delete(key: kTokenKey);
      await _storage.delete(key: kUserIdKey);
      await _storage.delete(key: kUsernameKey);
    }
    handler.next(err);
  }
}
