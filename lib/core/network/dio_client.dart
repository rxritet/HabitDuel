import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'jwt_interceptor.dart';

/// Создаёт и настраивает синглтон-экземпляр [Dio].
Dio createDioClient(FlutterSecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: kConnectTimeout,
      receiveTimeout: kReceiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    JwtInterceptor(storage),
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      // ignore: avoid_print
      logPrint: (o) => print('[DIO] $o'),
    ),
  ]);

  return dio;
}
