import '../entities/duel.dart';

/// Абстрактный контракт дуэлей.
abstract class DuelRepository {
  /// Создать дуэль.
  Future<Duel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  });

  /// Принять ожидающий дуэль.
  Future<Duel> acceptDuel(String duelId);

  /// Список дуэлей пользователя.
  Future<List<Duel>> getMyDuels();

  /// Полная информация о дуэле по id.
  Future<Duel> getDuelDetail(String duelId);

  /// Выполнить check-in в дуэле.
  Future<CheckInResult> checkIn(String duelId, {String? note});
}

class CheckInResult {
  const CheckInResult({
    required this.checkinId,
    required this.duelId,
    required this.newStreak,
    required this.checkedAt,
  });

  final String checkinId;
  final String duelId;
  final int newStreak;
  final DateTime checkedAt;
}
