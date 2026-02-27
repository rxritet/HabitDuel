import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/database.dart';

/// GET /leaderboard?limit=50&offset=0
///
/// Returns top users sorted by wins DESC with correct dense ranking
/// (users with the same win count share the same rank).
class LeaderboardHandler {
  Router get router {
    final r = Router();
    r.get('/', _getLeaderboard);
    return r;
  }

  Future<Response> _getLeaderboard(Request request) async {
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '50')?.clamp(1, 100) ?? 50;
    final offset = int.tryParse(params['offset'] ?? '0')?.clamp(0, 10000) ?? 0;

    final conn = await Database.connection;

    final result = await conn.execute(
      Sql.named('''
        SELECT
          id,
          username,
          wins,
          losses,
          DENSE_RANK() OVER (ORDER BY wins DESC) AS rank
        FROM users
        ORDER BY wins DESC, username ASC
        LIMIT @limit
        OFFSET @offset
      '''),
      parameters: {'limit': limit, 'offset': offset},
    );

    final entries = result.map((r) {
      final row = r.toColumnMap();
      return {
        'rank': row['rank'],
        'user_id': row['id'],
        'username': row['username'],
        'wins': row['wins'],
        'losses': row['losses'],
      };
    }).toList();

    // Also get total count for pagination
    final countResult = await conn.execute(
      Sql.named('SELECT COUNT(*)::int AS total FROM users'),
    );
    final total = countResult.first.toColumnMap()['total'] as int;

    return Response.ok(
      jsonEncode({
        'leaderboard': entries,
        'total': total,
        'limit': limit,
        'offset': offset,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
