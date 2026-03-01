import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Управляет WebSocket-комнатами по дуэлям.
///
/// Клиенты подписываются через `/ws/duels/:id?token=<jwt>`.
/// Хаб рассылает JSON-события всем подключённым в комнату.
class DuelWsHub {
  DuelWsHub(this._jwtSecret);

  final String _jwtSecret;

  /// duelId → множество подключённых сокетов
  final Map<String, Set<WebSocket>> _rooms = {};

  // ─── Управление подключениями ─────────────────────────────────────────

  /// Обрабатывает входящий запрос на WebSocket-апгрейд.
  Future<void> handleUpgrade(HttpRequest request) async {
  // Разбираем URI: /ws/duels/<duelId>?token=<jwt>
    final segments = request.uri.pathSegments;
    // Ожидаем: ws, duels, <duelId>
    if (segments.length < 3 || segments[0] != 'ws' || segments[1] != 'duels') {
      request.response
        ..statusCode = 400
        ..write('Bad request')
        ..close();
      return;
    }

    final duelId = segments[2];
    final token = request.uri.queryParameters['token'];

    // Аутентификация через JWT
    if (token == null || token.isEmpty) {
      request.response
        ..statusCode = 401
        ..write('Missing token')
        ..close();
      return;
    }

    String userId;
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      userId = payload['sub'] as String;
    } catch (_) {
      request.response
        ..statusCode = 401
        ..write('Invalid token')
        ..close();
      return;
    }

    // Переводим соединение на WebSocket
    final socket = await WebSocketTransformer.upgrade(request);

    _rooms.putIfAbsent(duelId, () => {});
    _rooms[duelId]!.add(socket);

    // Отправляем приветственное событие
    socket.add(jsonEncode({
      'event': 'connected',
      'duel_id': duelId,
      'user_id': userId,
    }));

    // Слушаем закрытие соединения
    socket.listen(
      (_) {}, // сообщения от клиента не ожидаются
      onDone: () => _remove(duelId, socket),
      onError: (_) => _remove(duelId, socket),
    );
  }

  void _remove(String duelId, WebSocket socket) {
    _rooms[duelId]?.remove(socket);
    if (_rooms[duelId]?.isEmpty ?? false) {
      _rooms.remove(duelId);
    }
    try {
      socket.close();
    } catch (_) {}
  }

  // ─── Рассылка событий ──────────────────────────────────────────────────

  /// Рассылает событие всем клиентам в комнате [duelId].
  void broadcast(String duelId, Map<String, dynamic> event) {
    final room = _rooms[duelId];
    if (room == null || room.isEmpty) return;

    final payload = jsonEncode(event);
    final stale = <WebSocket>[];

    for (final socket in room) {
      try {
        socket.add(payload);
      } catch (_) {
        stale.add(socket);
      }
    }

  // Удаляем оборванные соединения
    for (final s in stale) {
      _remove(duelId, s);
    }
  }

  /// Простая рассылка события `checkin_created`.
  void notifyCheckinCreated({
    required String duelId,
    required String userId,
    required String username,
    required int newStreak,
    required String checkinId,
    required DateTime checkedAt,
  }) {
    broadcast(duelId, {
      'event': 'checkin_created',
      'duel_id': duelId,
      'user_id': userId,
      'username': username,
      'new_streak': newStreak,
      'checkin_id': checkinId,
      'checked_at': checkedAt.toUtc().toIso8601String(),
    });
  }

  /// Простая рассылка события `streak_broken`.
  void notifyStreakBroken({
    required String duelId,
    required String userId,
    required String username,
    required int oldStreak,
  }) {
    broadcast(duelId, {
      'event': 'streak_broken',
      'duel_id': duelId,
      'user_id': userId,
      'username': username,
      'old_streak': oldStreak,
    });
  }

  /// Простая рассылка события `duel_completed`.
  void notifyDuelCompleted({
    required String duelId,
    required String? winnerId,
    required String? winnerUsername,
  }) {
    broadcast(duelId, {
      'event': 'duel_completed',
      'duel_id': duelId,
      'winner_id': winnerId,
      'winner_username': winnerUsername,
    });
  }
}
