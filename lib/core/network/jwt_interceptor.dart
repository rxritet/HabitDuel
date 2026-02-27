import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Interceptor that attaches `Authorization: Bearer <jwt>` header
/// to every outgoing request if a token is stored.
///
/// On a 401 response the stored token is cleared — the UI layer
/// watches the auth state and will redirect to the login screen.
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
      // Clear persisted auth data — provider listener will redirect.
      await _storage.delete(key: kTokenKey);
      await _storage.delete(key: kUserIdKey);
      await _storage.delete(key: kUsernameKey);
    }
    handler.next(err);
  }
}
