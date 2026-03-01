/// Доменная сущность профиля пользователя.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    required this.wins,
    required this.losses,
    this.badges = const [],
  });

  final String id;
  final String username;
  final String? email;
  final int wins;
  final int losses;
  final List<ProfileBadge> badges;
}

class ProfileBadge {
  const ProfileBadge({required this.badgeType, required this.earnedAt});
  final String badgeType;
  final DateTime earnedAt;
}
