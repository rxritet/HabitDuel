/// Доменная сущность профиля пользователя.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    required this.wins,
    required this.losses,
    this.badges = const [],
    this.bio,
    this.favoriteHabit,
    this.avatarEmoji = '🔥',
  });

  final String id;
  final String username;
  final String? email;
  final int wins;
  final int losses;
  final List<ProfileBadge> badges;
  final String? bio;
  final String? favoriteHabit;
  final String avatarEmoji;

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    int? wins,
    int? losses,
    List<ProfileBadge>? badges,
    String? bio,
    String? favoriteHabit,
    String? avatarEmoji,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      badges: badges ?? this.badges,
      bio: bio ?? this.bio,
      favoriteHabit: favoriteHabit ?? this.favoriteHabit,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
}

class ProfileBadge {
  const ProfileBadge({required this.badgeType, required this.earnedAt});
  final String badgeType;
  final DateTime earnedAt;
}
