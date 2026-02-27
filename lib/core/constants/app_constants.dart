/// Base URL for the HabitDuel API server.
const String kBaseUrl = 'http://10.0.2.2:8080'; // Android emulator → host localhost

/// Timeout durations.
const Duration kConnectTimeout = Duration(seconds: 10);
const Duration kReceiveTimeout = Duration(seconds: 10);

/// Secure storage keys.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
