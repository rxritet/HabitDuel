import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

/// Base URL for the HabitDuel API server.
///
/// Override it with `--dart-define=API_BASE_URL=https://...`.
/// Debug builds use local addresses for emulator and simulator workflows.
String get kBaseUrl {
  const overrideUrl = String.fromEnvironment('API_BASE_URL');
  if (overrideUrl.isNotEmpty) {
    return overrideUrl;
  }

  if (kIsWeb) {
    final webUri = Uri.base;
    final scheme = webUri.scheme == 'https' ? 'https' : 'http';
    final host = webUri.host.isEmpty ? 'localhost' : webUri.host;
    return '$scheme://$host:8080';
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

/// HTTP timeouts.
///
/// Debug builds fail fast so the UI does not hang on a stopped local backend.
Duration get kConnectTimeout =>
    kDebugMode ? const Duration(seconds: 3) : const Duration(seconds: 10);

Duration get kReceiveTimeout =>
    kDebugMode ? const Duration(seconds: 5) : const Duration(seconds: 10);

/// Secure storage keys.
const String kTokenKey = 'jwt_token';
const String kUserIdKey = 'user_id';
const String kUsernameKey = 'username';
