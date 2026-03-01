import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';

/// Middleware Shelf \u0434\u043b\u044f \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0438 Authorization: Bearer <jwt>.
///
/// \u041f\u0440\u0438 \u0443\u0441\u043f\u0435\u0445\u0435 \u0437\u0430\u043f\u0438\u0441\u044b\u0432\u0430\u0435\u0442 `userId`/`username` \u0432 `request.context`.
/// \u041f\u0440\u0438 \u043e\u0448\u0438\u0431\u043a\u0435 \u2014 401.
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

      final token = authHeader.substring(7); // \u0443\u0431\u0438\u0440\u0430\u0435\u043c "Bearer "

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

        // Передаём декодированные claims через контекст запроса
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
