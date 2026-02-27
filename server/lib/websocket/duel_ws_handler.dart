import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Manages per-duel WebSocket rooms.
///
/// Clients subscribe via `/ws/duels/:id?token=<jwt>`.
/// The hub broadcasts JSON events to all connected clients in a room.
class DuelWsHub {
  DuelWsHub(this._jwtSecret);

  final String _jwtSecret;

  /// duelId → set of connected sockets
  final Map<String, Set<WebSocket>> _rooms = {};

  // ─── Connection management ──────────────────────────────────────────

  /// Handles an incoming WebSocket upgrade request.
  Future<void> handleUpgrade(HttpRequest request) async {
    // Parse URI: /ws/duels/<duelId>?token=<jwt>
    final segments = request.uri.pathSegments;
    // Expected: ws, duels, <duelId>
    if (segments.length < 3 || segments[0] != 'ws' || segments[1] != 'duels') {
      request.response
        ..statusCode = 400
        ..write('Bad request')
        ..close();
      return;
    }

    final duelId = segments[2];
    final token = request.uri.queryParameters['token'];

    // Authenticate via JWT
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

    // Upgrade to WebSocket
    final socket = await WebSocketTransformer.upgrade(request);

    _rooms.putIfAbsent(duelId, () => {});
    _rooms[duelId]!.add(socket);

    // Send welcome event
    socket.add(jsonEncode({
      'event': 'connected',
      'duel_id': duelId,
      'user_id': userId,
    }));

    // Listen for close
    socket.listen(
      (_) {}, // we don't expect client→server messages
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

  // ─── Broadcasting ──────────────────────────────────────────────────

  /// Broadcast an event to all clients subscribed to [duelId].
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

    // Clean up broken connections
    for (final s in stale) {
      _remove(duelId, s);
    }
  }

  /// Convenience: broadcast `checkin_created` event.
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

  /// Convenience: broadcast `streak_broken` event.
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

  /// Convenience: broadcast `duel_completed` event.
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
