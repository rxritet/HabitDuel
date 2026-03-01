import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';

/// Обрабатывает `/auth/register` и `/auth/login`.
class AuthHandler {
  AuthHandler(this._env);

  final DotEnv _env;

  Router get router {
    final r = Router();
    r.post('/register', _register);
    r.post('/login', _login);
    return r;
  }

  // ---------------------------------------------------------------------------
  // POST /auth/register — регистрация
  // ---------------------------------------------------------------------------
  Future<Response> _register(Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return _json({'error': 'invalid_json'}, 400);
    }

    final username = (json['username'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim();
    final password = json['password'] as String?;

    // --- Валидация ---
    if (username == null || username.isEmpty) {
      return _json({'error': 'username_required'}, 400);
    }
    if (email == null || email.isEmpty) {
      return _json({'error': 'email_required'}, 400);
    }
    if (password == null || password.length < 8) {
      return _json({'error': 'password_min_8'}, 400);
    }

    final passwordHash = _hashPassword(password);
    final conn = await Database.connection;

    try {
      final result = await conn.execute(
        Sql.named(
          '''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, @hash)
          RETURNING id, username, email, wins, losses, created_at
          ''',
        ),
        parameters: {
          'username': username,
          'email': email,
          'hash': passwordHash,
        },
      );

      final row = result.first.toColumnMap();
      final userId = row['id'] as String;

      final token = _generateToken(userId, username);

      return _json({
        'id': userId,
        'username': row['username'],
        'email': row['email'],
        'token': token,
      }, 201);
    } on ServerException catch (e) {
      // Код PostgreSQL unique_violation = 23505
      if (e.message.contains('23505') ||
          e.message.contains('unique') ||
          e.message.contains('duplicate key')) {
        return _json({'error': 'username_taken'}, 409);
      }
      return _json({'error': 'server_error', 'detail': e.message}, 500);
    } catch (e) {
      return _json({'error': 'server_error', 'detail': e.toString()}, 500);
    }
  }

  // ---------------------------------------------------------------------------
  // POST /auth/login — вход
  // ---------------------------------------------------------------------------
  Future<Response> _login(Request request) async {
    final body = await request.readAsString();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return _json({'error': 'invalid_json'}, 400);
    }

    final email = (json['email'] as String?)?.trim();
    final password = json['password'] as String?;

    if (email == null || email.isEmpty || password == null) {
      return _json({'error': 'invalid_credentials'}, 401);
    }

    final conn = await Database.connection;

    final result = await conn.execute(
      Sql.named(
        'SELECT id, username, email, password_hash, wins, losses '
        'FROM users WHERE email = @email',
      ),
      parameters: {'email': email},
    );

    if (result.isEmpty) {
      return _json({'error': 'invalid_credentials'}, 401);
    }

    final row = result.first.toColumnMap();
    final storedHash = row['password_hash'] as String;

    if (storedHash != _hashPassword(password)) {
      return _json({'error': 'invalid_credentials'}, 401);
    }

    final userId = row['id'] as String;
    final username = row['username'] as String;
    final token = _generateToken(userId, username);

    return _json({
      'token': token,
      'user': {
        'id': userId,
        'username': username,
        'wins': row['wins'],
        'losses': row['losses'],
      },
    }, 200);
  }

  // ---------------------------------------------------------------------------
  // Вспомогательные методы
  // ---------------------------------------------------------------------------

  /// SHA-256 хеш пароля (для MVP; в production лучше bcrypt).
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Генерирует JWT с `sub` (userId) и `username` сроком на 30 дней.
  String _generateToken(String userId, String username) {
    final secret = _env['JWT_SECRET'] ?? 'default_secret';
    final jwt = JWT(
      {
        'sub': userId,
        'username': username,
      },
    );
    return jwt.sign(
      SecretKey(secret),
      expiresIn: const Duration(days: 30),
    );
  }

  /// Краткий метод для JSON-ответа.
  Response _json(Map<String, dynamic> data, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
