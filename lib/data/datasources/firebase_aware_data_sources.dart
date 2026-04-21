import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../../domain/entities/duel.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/profile.dart';
import 'leaderboard_remote_ds.dart';
import '../models/duel_model.dart';

DateTime? _apiUnavailableUntil;
const _apiRetryCooldown = Duration(seconds: 30);

bool get _shouldSkipApiCalls {
  final until = _apiUnavailableUntil;
  if (until == null) return false;
  return DateTime.now().isBefore(until);
}

void _markApiUnavailable() {
  _apiUnavailableUntil = DateTime.now().add(_apiRetryCooldown);
}

void _markApiAvailable() {
  _apiUnavailableUntil = null;
}

bool _isNetworkError(DioException e) {
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;
}

bool _isLocalApi(Uri uri) {
  final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
  return isLocalHost && uri.port == 8080;
}

class FirebaseAwareProfileDataSource {
  FirebaseAwareProfileDataSource(this._dio, this._storage, this._store);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final HabitDuelFirestoreStore _store;

  Future<UserProfile> getMyProfile() async {
    final userId = await _storage.read(key: kUserIdKey);
    final username = await _storage.read(key: kUsernameKey);

    UserProfile? cachedProfile;
    if (userId != null && userId.isNotEmpty) {
      try {
        cachedProfile = await _store.readProfile(userId);
        if (cachedProfile != null) {
          return cachedProfile;
        }
      } catch (_) {
        // Firestore cache is best-effort; fall back to REST.
      }
    }

    if (_shouldSkipApiCalls) {
      if (userId != null && userId.isNotEmpty) {
        return UserProfile(
          id: userId,
          username: username ?? '',
          wins: 0,
          losses: 0,
          badges: const [],
        );
      }
      throw const NetworkFailure();
    }

    try {
      final response = await _dio.get('/users/me');
      _markApiAvailable();
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

      unawaited(_store.upsertProfile(profile));
      return profile;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
        if (cachedProfile != null) {
          return cachedProfile;
        }
        if (userId != null && userId.isNotEmpty) {
          return UserProfile(
            id: userId,
            username: username ?? '',
            wins: 0,
            losses: 0,
            badges: const [],
          );
        }
      }
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
      if (_isLocalApi(e.requestOptions.uri)) {
        return const NetworkFailure(
          'Backend unavailable on localhost:8080. Start API server and retry.',
        );
      }
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
    LeaderboardResult? cachedResult;
    try {
      final cached = await _store.readLeaderboard(limit: limit, offset: offset);
      cachedResult = LeaderboardResult(entries: cached.entries, total: cached.total);
      if (cached.entries.isNotEmpty) {
        return cachedResult;
      }
    } catch (_) {
      // Firestore cache is best-effort; fall back to REST.
    }

    if (_shouldSkipApiCalls) {
      return cachedResult ?? const LeaderboardResult(entries: [], total: 0);
    }

    try {
      final response = await _dio.get(
        '/leaderboard/',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      _markApiAvailable();
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
      unawaited(_store.mirrorLeaderboardUsers(entries));
      return LeaderboardResult(
        entries: entries,
        total: data['total'] as int,
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
        return cachedResult ?? const LeaderboardResult(entries: [], total: 0);
      }
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
      if (_isLocalApi(e.requestOptions.uri)) {
        return const NetworkFailure(
          'Backend unavailable on localhost:8080. Start API server and retry.',
        );
      }
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
    if (_shouldSkipApiCalls) {
      throw const NetworkFailure('Backend is temporarily unavailable');
    }

    try {
      final response = await _dio.post('/duels/', data: {
        'habit_name': habitName,
        if (description != null) 'description': description,
        'duration_days': durationDays,
        if (opponentUsername != null) 'opponent_username': opponentUsername,
      });
      _markApiAvailable();
      final duel = DuelModel.fromCreateJson(response.data as Map<String, dynamic>);
      unawaited(
        _mirrorCreateResponse(response.data as Map<String, dynamic>, duel),
      );
      return duel;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
      }
      throw _mapError(e);
    }
  }

  Future<DuelModel> acceptDuel(String duelId) async {
    if (_shouldSkipApiCalls) {
      throw const NetworkFailure('Backend is temporarily unavailable');
    }

    try {
      final response = await _dio.post('/duels/$duelId/accept');
      _markApiAvailable();
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
      unawaited(_mirrorFullDuel(duelId));
      return duel;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
      }
      throw _mapError(e);
    }
  }

  Future<List<DuelModel>> getMyDuels() async {
    final userId = await _storage.read(key: kUserIdKey);
    List<DuelModel>? cachedDuels;
    if (userId != null && userId.isNotEmpty) {
      try {
        final cached = await _store.readMyDuels(userId);
        cachedDuels = cached.map(_toDuelModel).toList();
        if (cached.isNotEmpty) {
          return cachedDuels;
        }
      } catch (_) {
        // Firestore cache is best-effort; fall back to REST.
      }
    }

    if (_shouldSkipApiCalls) {
      return cachedDuels ?? const <DuelModel>[];
    }

    try {
      final response = await _dio.get('/duels/');
      _markApiAvailable();
      final data = response.data as Map<String, dynamic>;
      final list = data['duels'] as List<dynamic>;
      final result = list
          .map((j) => DuelModel.fromListJson(j as Map<String, dynamic>))
          .toList();
      unawaited(_mirrorMyDuelsFromRest());
      return result;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
        return cachedDuels ?? const <DuelModel>[];
      }
      throw _mapError(e);
    }
  }

  Future<DuelModel> getDuelDetail(String duelId) async {
    DuelModel? cachedDuel;
    try {
      final cached = await _store.readDuel(duelId);
      if (cached != null) {
        cachedDuel = _toDuelModel(cached);
        return cachedDuel;
      }
    } catch (_) {
      // fall through to REST
    }

    if (_shouldSkipApiCalls) {
      throw const NetworkFailure('Backend is temporarily unavailable');
    }

    try {
      final response = await _dio.get('/duels/$duelId');
      _markApiAvailable();
      final duel = DuelModel.fromDetailJson(response.data as Map<String, dynamic>);
      unawaited(_store.upsertDuel(duel));
      return duel;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
        if (cachedDuel != null) {
          return cachedDuel;
        }
      }
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> checkIn(String duelId, {String? note}) async {
    if (_shouldSkipApiCalls) {
      throw const NetworkFailure('Backend is temporarily unavailable');
    }

    try {
      final response = await _dio.post(
        '/duels/$duelId/checkin',
        data: {if (note != null) 'note': note},
      );
      _markApiAvailable();
      unawaited(_mirrorFullDuel(duelId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        _markApiUnavailable();
      }
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

    unawaited(_store.upsertDuel(
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
    ));
  }

  Future<void> _mirrorFullDuel(String duelId) async {
    final response = await _dio.get('/duels/$duelId');
    final duel = DuelModel.fromDetailJson(response.data as Map<String, dynamic>);
    unawaited(_store.upsertDuel(duel));
  }

  Future<void> _mirrorMyDuelsFromRest() async {
    final response = await _dio.get('/duels/');
    final data = response.data as Map<String, dynamic>;
    final list = data['duels'] as List<dynamic>;
    for (final item in list) {
      final duel = DuelModel.fromListJson(item as Map<String, dynamic>);
      unawaited(_store.upsertDuel(
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
      ));
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
      if (_isLocalApi(e.requestOptions.uri)) {
        return const NetworkFailure(
          'Backend unavailable on localhost:8080. Start API server and retry.',
        );
      }
      return const NetworkFailure();
    }
    return ServerFailure(message, statusCode: e.response?.statusCode);
  }
}