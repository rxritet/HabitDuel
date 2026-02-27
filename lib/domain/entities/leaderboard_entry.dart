/// Domain entity for a leaderboard entry.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.wins,
    required this.losses,
  });

  final int rank;
  final String userId;
  final String username;
  final int wins;
  final int losses;
}
