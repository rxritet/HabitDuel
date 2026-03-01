import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';

/// Обрабатывает CRUD дуэлей: создание, принятие, список, детали.
class DuelsHandler {
  Router get router {
    final r = Router();
    r.post('/', _createDuel);
    r.get('/', _listDuels);
    r.get('/<id>', _getDuel);
    r.post('/<id>/accept', _acceptDuel);
    return r;
  }

  // ---------------------------------------------------------------------------
  // POST /duels — создать дуэль
  // ---------------------------------------------------------------------------
  Future<Response> _createDuel(Request request) async {
    final userId = request.context['userId'] as String;
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final habitName = (body['habit_name'] as String?)?.trim();
    final description = (body['description'] as String?)?.trim();
    final durationDays = body['duration_days'] as int?;
    final opponentUsername = (body['opponent_username'] as String?)?.trim();

    if (habitName == null || habitName.isEmpty) {
      return _json({'error': 'habit_name_required'}, 400);
    }
    if (durationDays == null || ![7, 14, 21, 30].contains(durationDays)) {
      return _json({'error': 'invalid_duration'}, 400);
    }

    final conn = await Database.connection;

    // Находим противника если указан username
    String? opponentId;
    if (opponentUsername != null && opponentUsername.isNotEmpty) {
      final oppResult = await conn.execute(
        Sql.named('SELECT id FROM users WHERE username = @u'),
        parameters: {'u': opponentUsername},
      );
      if (oppResult.isEmpty) {
        return _json({'error': 'opponent_not_found'}, 404);
      }
      opponentId = oppResult.first.toColumnMap()['id'] as String;
    }

    // Вставляем дуэль в БД
    final duelResult = await conn.execute(
      Sql.named('''
        INSERT INTO duels (habit_name, description, creator_id, opponent_id, duration_days)
        VALUES (@habit, @desc, @creator::uuid, ${opponentId != null ? '@opponent::uuid' : 'NULL'}, @days)
        RETURNING id, habit_name, description, creator_id, opponent_id, status, duration_days, created_at
      '''),
      parameters: {
        'habit': habitName,
        'desc': description,
        'creator': userId,
        if (opponentId != null) 'opponent': opponentId,
        'days': durationDays,
      },
    );

    final duel = duelResult.first.toColumnMap();
    final duelId = duel['id'] as String;

    // Добавляем создателя как участника
    await conn.execute(
      Sql.named(
        'INSERT INTO duel_participants (duel_id, user_id) VALUES (@d::uuid, @u::uuid)',
      ),
      parameters: {'d': duelId, 'u': userId},
    );

    // Получаем данные создателя
    final creatorRow = await _fetchUser(conn, userId);

    // Получаем данные противника, если указан
    Map<String, dynamic>? opponentInfo;
    if (opponentId != null) {
      opponentInfo = await _fetchUser(conn, opponentId);
    }

    return _json({
      'id': duelId,
      'habit_name': duel['habit_name'],
      'description': duel['description'],
      'status': duel['status'],
      'creator': creatorRow,
      'opponent': opponentInfo,
      'duration_days': duel['duration_days'],
      'created_at': (duel['created_at'] as DateTime).toUtc().toIso8601String(),
    }, 201);
  }

  // ---------------------------------------------------------------------------
  // POST /duels/<id>/accept — принять дуэль
  // ---------------------------------------------------------------------------
  Future<Response> _acceptDuel(Request request, String id) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    // Получаем дуэль
    final duelResult = await conn.execute(
      Sql.named('SELECT * FROM duels WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    final status = duel['status'] as String;
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;

    if (status != 'pending') {
      return _json({'error': 'duel_not_pending'}, 409);
    }

    // Нельзя принять свою же дуэль
    if (creatorId == userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    // Если дуэль адресная — только указанный противник может принять
    if (opponentId != null && opponentId != userId) {
      return _json({'error': 'forbidden'}, 403);
    }

    final now = DateTime.now().toUtc();
    final durationDays = duel['duration_days'] as int;
    final endsAt = now.add(Duration(days: durationDays));

    // Активируем дуэль
    await conn.execute(
      Sql.named('''
        UPDATE duels
        SET status = 'active',
            opponent_id = @opp::uuid,
            starts_at = @start,
            ends_at = @end
        WHERE id = @id::uuid
      '''),
      parameters: {
        'id': id,
        'opp': userId,
        'start': now,
        'end': endsAt,
      },
    );

    // Добавляем противника как участника
    await conn.execute(
      Sql.named('''
        INSERT INTO duel_participants (duel_id, user_id)
        VALUES (@d::uuid, @u::uuid)
        ON CONFLICT (duel_id, user_id) DO NOTHING
      '''),
      parameters: {'d': id, 'u': userId},
    );

    return _json({
      'id': id,
      'status': 'active',
      'starts_at': now.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
    }, 200);
  }

  // ---------------------------------------------------------------------------
  // GET /duels — список дуэлей пользователя
  // ---------------------------------------------------------------------------
  Future<Response> _listDuels(Request request) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    final result = await conn.execute(
      Sql.named('''
        SELECT d.id, d.habit_name, d.status, d.ends_at, d.duration_days,
               dp_me.streak AS my_streak,
               dp_opp.streak AS opponent_streak,
               CASE WHEN d.creator_id = @uid::uuid THEN d.opponent_id ELSE d.creator_id END AS opponent_id
        FROM duels d
        LEFT JOIN duel_participants dp_me
          ON dp_me.duel_id = d.id AND dp_me.user_id = @uid::uuid
        LEFT JOIN duel_participants dp_opp
          ON dp_opp.duel_id = d.id AND dp_opp.user_id != @uid::uuid
        WHERE d.creator_id = @uid::uuid OR d.opponent_id = @uid::uuid
        ORDER BY d.created_at DESC
      '''),
      parameters: {'uid': userId},
    );

    final duels = result.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'habit_name': row['habit_name'],
        'status': row['status'],
        'my_streak': row['my_streak'] ?? 0,
        'opponent_streak': row['opponent_streak'] ?? 0,
        'duration_days': row['duration_days'],
        'ends_at': row['ends_at'] != null
            ? (row['ends_at'] as DateTime).toUtc().toIso8601String()
            : null,
      };
    }).toList();

    return _json({'duels': duels}, 200);
  }

  // ---------------------------------------------------------------------------
  // GET /duels/<id> — детали дуэли
  // ---------------------------------------------------------------------------
  Future<Response> _getDuel(Request request, String id) async {
    final userId = request.context['userId'] as String;
    final conn = await Database.connection;

    final duelResult = await conn.execute(
      Sql.named('SELECT * FROM duels WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    if (duelResult.isEmpty) return _json({'error': 'not_found'}, 404);

    final duel = duelResult.first.toColumnMap();
    final creatorId = duel['creator_id'] as String;
    final opponentId = duel['opponent_id'] as String?;

    // Только участники могут просматривать
    if (creatorId != userId && opponentId != userId) {
      // Открытые дуэли видны всем
      if (opponentId != null) {
        return _json({'error': 'forbidden'}, 403);
      }
    }

    // Получаем участников со статистикой серий
    final partResult = await conn.execute(
      Sql.named('''
        SELECT dp.user_id, dp.streak, dp.last_checkin, u.username
        FROM duel_participants dp
        JOIN users u ON u.id = dp.user_id
        WHERE dp.duel_id = @id::uuid
      '''),
      parameters: {'id': id},
    );

    final participants = partResult.map((r) {
      final row = r.toColumnMap();
      return {
        'user_id': row['user_id'],
        'username': row['username'],
        'streak': row['streak'],
        'last_checkin': row['last_checkin']?.toString(),
      };
    }).toList();

    // Получаем последние отметки (10 штук)
    final checkinsResult = await conn.execute(
      Sql.named('''
        SELECT c.id, c.user_id, u.username, c.checked_at, c.note
        FROM checkins c
        JOIN users u ON u.id = c.user_id
        WHERE c.duel_id = @id::uuid
        ORDER BY c.checked_at DESC
        LIMIT 10
      '''),
      parameters: {'id': id},
    );

    final checkins = checkinsResult.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'user_id': row['user_id'],
        'username': row['username'],
        'checked_at': (row['checked_at'] as DateTime).toUtc().toIso8601String(),
        'note': row['note'],
      };
    }).toList();

    return _json({
      'id': duel['id'],
      'habit_name': duel['habit_name'],
      'description': duel['description'],
      'status': duel['status'],
      'creator_id': creatorId,
      'opponent_id': opponentId,
      'duration_days': duel['duration_days'],
      'starts_at': duel['starts_at'] != null
          ? (duel['starts_at'] as DateTime).toUtc().toIso8601String()
          : null,
      'ends_at': duel['ends_at'] != null
          ? (duel['ends_at'] as DateTime).toUtc().toIso8601String()
          : null,
      'created_at': (duel['created_at'] as DateTime).toUtc().toIso8601String(),
      'participants': participants,
      'checkins': checkins,
    }, 200);
  }

  // ---------------------------------------------------------------------------
  // Вспомогательные методы
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchUser(Connection conn, String userId) async {
    final r = await conn.execute(
      Sql.named('SELECT id, username FROM users WHERE id = @id::uuid'),
      parameters: {'id': userId},
    );
    final row = r.first.toColumnMap();
    return {'id': row['id'], 'username': row['username']};
  }

  Response _json(Map<String, dynamic> data, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
