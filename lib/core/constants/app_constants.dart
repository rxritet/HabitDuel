import 'package:flutter/foundation.dart' show kIsWeb;

/// Базовый URL API-сервера HabitDuel.
/// Web: localhost, Android-эмулятор: 10.0.2.2
String get kBaseUrl => kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

/// Тайм-ауты.
const Duration kConnectTimeout = Duration(seconds: 10);
const Duration kReceiveTimeout = Duration(seconds: 10);

/// Ключи защищённого хранилища.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
