/// Base class for all application failures.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Server returned an error response.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

/// Auth-specific failures.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Network not reachable.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Unexpected / catch-all failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
