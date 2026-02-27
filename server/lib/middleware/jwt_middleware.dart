import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';

/// Shelf middleware that validates `Authorization: Bearer <jwt>`.
///
/// On success the decoded claims are stored in `request.context` under
/// keys `userId` and `username` so downstream handlers can access them.
///
/// On failure returns 401 immediately.
Middleware jwtMiddleware(DotEnv env) {
  final secret = env['JWT_SECRET'] ?? 'default_secret';

  return (Handler innerHandler) {
    return (Request request) {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'missing_token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7); // strip "Bearer "

      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        final payload = jwt.payload as Map<String, dynamic>;

        final userId = payload['sub'] as String?;
        final username = payload['username'] as String?;

        if (userId == null) {
          return Response(
            401,
            body: jsonEncode({'error': 'invalid_token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Forward decoded claims via request context
        final updatedRequest = request.change(context: {
          'userId': userId,
          'username': username ?? '',
        });

        return innerHandler(updatedRequest);
      } on JWTExpiredException {
        return Response(
          401,
          body: jsonEncode({'error': 'token_expired'}),
          headers: {'Content-Type': 'application/json'},
        );
      } on JWTException {
        return Response(
          401,
          body: jsonEncode({'error': 'invalid_token'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (_) {
        return Response(
          401,
          body: jsonEncode({'error': 'invalid_token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}
