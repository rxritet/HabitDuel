import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Result container for leaderboard fetch.
class LeaderboardResult {
  const LeaderboardResult({
    required this.entries,
    required this.total,
  });
  final List<LeaderboardEntry> entries;
  final int total;
}

/// Handles GET /leaderboard.
class LeaderboardRemoteDataSource {
  const LeaderboardRemoteDataSource(this._dio);
  final Dio _dio;

  Future<LeaderboardResult> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/leaderboard',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['leaderboard'] as List<dynamic>;
      final entries = list.map((j) {
        final m = j as Map<String, dynamic>;
        return LeaderboardEntry(
          rank: m['rank'] as int,
          userId: m['user_id'] as String,
          username: m['username'] as String,
          wins: m['wins'] as int,
          losses: m['losses'] as int,
        );
      }).toList();
      return LeaderboardResult(
        entries: entries,
        total: data['total'] as int,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException e) {
    final data = e.response?.data;
    String message = 'Server error';
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    return ServerFailure(message, statusCode: e.response?.statusCode);
  }
}
