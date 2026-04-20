import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

/// Базовый URL API-сервера HabitDuel.
///
/// Можно переопределить через `--dart-define=API_BASE_URL=https://...`.
/// В debug используются локальные адреса для эмулятора/симулятора.
String get kBaseUrl {
  const overrideUrl = String.fromEnvironment('API_BASE_URL');
  if (overrideUrl.isNotEmpty) {
    return overrideUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:8080';
  }

  if (kDebugMode) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'http://localhost:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  throw StateError(
    'API_BASE_URL must be provided for non-debug mobile builds via --dart-define',
  );
}

/// Тайм-ауты.
const Duration kConnectTimeout = Duration(seconds: 10);
const Duration kReceiveTimeout = Duration(seconds: 10);

/// Ключи защищённого хранилища.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
