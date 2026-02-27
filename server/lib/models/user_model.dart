/// Dart model for the `users` table.
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.wins,
    required this.losses,
    required this.createdAt,
  });

  /// Construct a [UserModel] from a PostgreSQL row map.
  factory UserModel.fromRow(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      username: row['username'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      wins: row['wins'] as int,
      losses: row['losses'] as int,
      createdAt: row['created_at'] is DateTime
          ? row['created_at'] as DateTime
          : DateTime.parse(row['created_at'].toString()),
    );
  }

  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final int wins;
  final int losses;
  final DateTime createdAt;

  /// Public JSON representation (never exposes password_hash).
  Map<String, dynamic> toPublicJson() {
    return {
      'id': id,
      'username': username,
      'wins': wins,
      'losses': losses,
    };
  }

  /// Extended public JSON that also includes email (for /users/me).
  Map<String, dynamic> toPrivateJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'wins': wins,
      'losses': losses,
    };
  }
}
