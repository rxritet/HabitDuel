/// Базовый класс всех ошибок приложения.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Сервер вернул ошибочный ответ.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

/// Ошибки аутентификации.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Сеть недоступна.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Непредвиденная / пойманная ошибка.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
