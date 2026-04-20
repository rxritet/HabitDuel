import '../../domain/entities/duel.dart';
import '../../domain/repositories/duel_repository.dart';
import '../../core/firebase/habitduel_firestore_store.dart';
import '../datasources/firebase_aware_data_sources.dart';

class DuelRepositoryImpl implements DuelRepository {
  const DuelRepositoryImpl(this._remoteDS, this._store);
  final FirebaseAwareDuelDataSource _remoteDS;
  final HabitDuelFirestoreStore _store;

  @override
  Future<Duel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  }) async {
    final duel = await _remoteDS.createDuel(
      habitName: habitName,
      description: description,
      durationDays: durationDays,
      opponentUsername: opponentUsername,
    );
    await _store.upsertDuel(duel);
    return duel;
  }

  @override
  Future<Duel> acceptDuel(String duelId) async {
    final duel = await _remoteDS.acceptDuel(duelId);
    await _store.upsertDuel(duel);
    return duel;
  }

  @override
  Future<List<Duel>> getMyDuels() => _remoteDS.getMyDuels();

  @override
  Future<Duel> getDuelDetail(String duelId) => _remoteDS.getDuelDetail(duelId);

  @override
  Future<CheckInResult> checkIn(String duelId, {String? note}) async {
    final data = await _remoteDS.checkIn(duelId, note: note);
    return CheckInResult(
      checkinId: data['checkin_id'] as String,
      duelId: data['duel_id'] as String,
      newStreak: (data['new_streak'] as num).toInt(),
      checkedAt: DateTime.parse(data['checked_at'] as String),
    );
  }
}
