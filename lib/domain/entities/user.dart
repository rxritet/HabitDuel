/// Доменная сущность аутентифицированного пользователя.
class User {
  const User({
    required this.id,
    required this.username,
    this.email,
    this.wins = 0,
    this.losses = 0,
  });

  final String id;
  final String username;
  final String? email;
  final int wins;
  final int losses;

  @override
  String toString() => 'User($username, W:$wins L:$losses)';
}
