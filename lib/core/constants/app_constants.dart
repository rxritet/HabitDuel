/// Базовый URL API-сервера HabitDuel.
const String kBaseUrl = 'http://10.0.2.2:8080'; // Эмулятор Android → localhost

/// Тайм-ауты.
const Duration kConnectTimeout = Duration(seconds: 10);
const Duration kReceiveTimeout = Duration(seconds: 10);

/// Ключи защищённого хранилища.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
