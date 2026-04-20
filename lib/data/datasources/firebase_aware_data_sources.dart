import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/duel.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/profile.dart';
import '../models/duel_model.dart';

class FirebaseAwareProfileDataSource {
  FirebaseAwareProfileDataSource(this._dio, this._storage, this._store);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  Future<UserProfile> getMyProfile() async {
    final userId = await _storage.read(key: kUserIdKey);
    if (userId != null && userId.isNotEmpty) {
      final cached = await _store.readProfile(userId);
      if (cached != null) {
        return cached;
      }
    }

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

      final profile = UserProfile(
        id: data['id'] as String,
        username: data['username'] as String,
        email: data['email'] as String?,
        wins: data['wins'] as int,
        losses: data['losses'] as int,
        badges: badges,
      );

      await _store.upsertProfile(profile);
      return profile;
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

class FirebaseAwareLeaderboardDataSource {
  FirebaseAwareLeaderboardDataSource(this._dio, this._store);

  final Dio _dio;
  final HabitDuelFirestoreStore _store;

  Future<LeaderboardResult> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final cached = await _store.readLeaderboard(limit: limit, offset: offset);
      if (cached.entries.isNotEmpty) {
        return LeaderboardResult(entries: cached.entries, total: cached.total);
      }
    } catch (_) {
      // Firestore cache is best-effort; fall back to REST.
    }

    try {
      final response = await _dio.get(
        '/leaderboard/',
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
      await _store.mirrorLeaderboardUsers(entries);
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

class FirebaseAwareDuelDataSource {
  FirebaseAwareDuelDataSource(this._dio, this._storage, this._store);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  Future<DuelModel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  }) async {
    try {
      final response = await _dio.post('/duels/', data: {
        'habit_name': habitName,
        if (description != null) 'description': description,
        'duration_days': durationDays,
        if (opponentUsername != null) 'opponent_username': opponentUsername,
      });
      final duel = DuelModel.fromCreateJson(response.data as Map<String, dynamic>);
      await _mirrorCreateResponse(response.data as Map<String, dynamic>, duel);
      return duel;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<DuelModel> acceptDuel(String duelId) async {
    try {
      final response = await _dio.post('/duels/$duelId/accept');
      final data = response.data as Map<String, dynamic>;
      final duel = DuelModel(
        id: data['id'] as String,
        habitName: '',
        status: data['status'] as String,
        durationDays: 0,
        startsAt: data['starts_at'] != null
            ? DateTime.parse(data['starts_at'] as String)
            : null,
        endsAt: data['ends_at'] != null
            ? DateTime.parse(data['ends_at'] as String)
            : null,
      );
      await _mirrorFullDuel(duelId);
      return duel;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<DuelModel>> getMyDuels() async {
    final userId = await _storage.read(key: kUserIdKey);
    if (userId != null && userId.isNotEmpty) {
      try {
        final cached = await _store.readMyDuels(userId);
        if (cached.isNotEmpty) {
          return cached.map(_toDuelModel).toList();
        }
      } catch (_) {
        // Firestore cache is best-effort; fall back to REST.
      }
    }

    try {
      final response = await _dio.get('/duels/');
      final data = response.data as Map<String, dynamic>;
      final list = data['duels'] as List<dynamic>;
      final result = list
          .map((j) => DuelModel.fromListJson(j as Map<String, dynamic>))
          .toList();
      await _mirrorMyDuelsFromRest();
      return result;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<DuelModel> getDuelDetail(String duelId) async {
    try {
      final cached = await _store.readDuel(duelId);
      if (cached != null) {
        return _toDuelModel(cached);
      }
    } catch (_) {
      // fall through to REST
    }

    try {
      final response = await _dio.get('/duels/$duelId');
      final duel = DuelModel.fromDetailJson(response.data as Map<String, dynamic>);
      await _store.upsertDuel(duel);
      return duel;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> checkIn(String duelId, {String? note}) async {
    try {
      final response = await _dio.post(
        '/duels/$duelId/checkin',
        data: {if (note != null) 'note': note},
      );
      await _mirrorFullDuel(duelId);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> _mirrorCreateResponse(
    Map<String, dynamic> response,
    DuelModel duel,
  ) async {
    final creator = response['creator'] as Map<String, dynamic>?;
    final opponent = response['opponent'] as Map<String, dynamic>?;
    final participants = <DuelParticipant>[];

    if (creator != null) {
      participants.add(
        DuelParticipant(
          userId: creator['id'] as String? ?? '',
          username: creator['username'] as String? ?? '',
        ),
      );
    }
    if (opponent != null) {
      participants.add(
        DuelParticipant(
          userId: opponent['id'] as String? ?? '',
          username: opponent['username'] as String? ?? '',
        ),
      );
    }

    await _store.upsertDuel(
      Duel(
        id: duel.id,
        habitName: duel.habitName,
        description: duel.description,
        status: duel.status,
        durationDays: duel.durationDays,
        creatorId: creator?['id'] as String?,
        opponentId: opponent?['id'] as String?,
        createdAt: duel.createdAt,
        participants: participants,
      ),
    );
  }

  Future<void> _mirrorFullDuel(String duelId) async {
    final response = await _dio.get('/duels/$duelId');
    final duel = DuelModel.fromDetailJson(response.data as Map<String, dynamic>);
    await _store.upsertDuel(duel);
  }

  Future<void> _mirrorMyDuelsFromRest() async {
    final response = await _dio.get('/duels/');
    final data = response.data as Map<String, dynamic>;
    final list = data['duels'] as List<dynamic>;
    for (final item in list) {
      final duel = DuelModel.fromListJson(item as Map<String, dynamic>);
      await _store.upsertDuel(
        Duel(
          id: duel.id,
          habitName: duel.habitName,
          description: duel.description,
          status: duel.status,
          durationDays: duel.durationDays,
          creatorId: duel.creatorId,
          opponentId: duel.opponentId,
          myStreak: duel.myStreak,
          opponentStreak: duel.opponentStreak,
          startsAt: duel.startsAt,
          endsAt: duel.endsAt,
          createdAt: duel.createdAt,
        ),
      );
    }
  }

  DuelModel _toDuelModel(Duel duel) {
    return DuelModel(
      id: duel.id,
      habitName: duel.habitName,
      description: duel.description,
      status: duel.status,
      durationDays: duel.durationDays,
      creatorId: duel.creatorId,
      opponentId: duel.opponentId,
      myStreak: duel.myStreak,
      opponentStreak: duel.opponentStreak,
      startsAt: duel.startsAt,
      endsAt: duel.endsAt,
      createdAt: duel.createdAt,
      participants: duel.participants,
      checkins: duel.checkins,
    );
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