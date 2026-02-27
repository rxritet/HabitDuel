/// Domain entity for a user badge.
class Badge {
  const Badge({
    required this.badgeType,
    required this.earnedAt,
  });

  final String badgeType;
  final DateTime earnedAt;
}
