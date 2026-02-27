import '../../domain/entities/user.dart';

/// Data-layer model for the User entity.
/// Handles JSON serialization / deserialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    super.wins,
    super.losses,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        if (email != null) 'email': email,
        'wins': wins,
        'losses': losses,
      };
}
