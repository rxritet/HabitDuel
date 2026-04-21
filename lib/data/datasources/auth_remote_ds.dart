import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../models/user_model.dart';

/// DTO-результаты, возвращаемые [AuthRemoteDataSource].
class RegisterResponse {
  const RegisterResponse({required this.user, required this.token});
  final UserModel user;
  final String token;
}

class LoginResponse {
  const LoginResponse({required this.user, required this.token});
  final UserModel user;
  final String token;
}

/// Выполняет HTTP-запросы к эндпоинтам `/auth/*`.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  bool _isLocalApi(Uri uri) {
    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    return isLocalHost && uri.port == 8080;
  }

  /// POST /auth/register — регистрация пользователя
  Future<RegisterResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserModel(
        id: data['id'] as String,
        username: data['username'] as String,
        email: data['email'] as String?,
      );

      return RegisterResponse(user: user, token: data['token'] as String);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// POST /auth/login — вход пользователя
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return LoginResponse(user: user, token: data['token'] as String);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Преобразует ошибки Dio в доменные [Failure].
  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Server error';
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'] as String;
    }

    switch (statusCode) {
      case 401:
        throw AuthFailure(message);
      case 409:
        throw ServerFailure(message, statusCode: 409);
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          final requestUri = e.requestOptions.uri;
          if (_isLocalApi(requestUri)) {
            throw const NetworkFailure(
              'Backend unavailable on localhost:8080. Start API server and retry.',
            );
          }
          throw const NetworkFailure();
        }
        throw ServerFailure(message, statusCode: statusCode);
    }
  }
}
