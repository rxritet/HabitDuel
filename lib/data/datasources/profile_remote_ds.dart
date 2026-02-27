import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';

/// Handles GET /users/me for full profile.
class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<UserProfile> getMyProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data as Map<String, dynamic>;
      final badgesRaw = data['badges'] as List<dynamic>? ?? [];
      final badges = badgesRaw.map((b) {
        final m = b as Map<String, dynamic>;
        return ProfileBadge(
          badgeType: m['badge_type'] as String,
          earnedAt: DateTime.parse(m['earned_at'] as String),
        );
      }).toList();

      return UserProfile(
        id: data['id'] as String,
        username: data['username'] as String,
        email: data['email'] as String?,
        wins: data['wins'] as int,
        losses: data['losses'] as int,
        badges: badges,
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
