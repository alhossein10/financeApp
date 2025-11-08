/// Base class for all failures in the application
/// Failures represent errors that have been handled and converted to a domain-friendly format
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Failure related to database operations
class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Database operation failed']) : super(message);
}

/// Failure related to authentication operations
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed']) : super(message);
}

/// Failure related to validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure when user is not authorized to perform an action
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Unauthorized access']) : super(message);
}

/// Failure when user has insufficient funds
class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([String message = 'Insufficient funds']) : super(message);
}

/// Failure related to network operations
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

/// Failure when a requested resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) : super(message);
}

/// Failure related to server errors
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// Failure related to cache operations
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache operation failed']) : super(message);
}

/// Failure when session has expired
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([String message = 'Session has expired']) : super(message);
}

/// Failure related to storage operations
class StorageFailure extends Failure {
  const StorageFailure([String message = 'Storage operation failed']) : super(message);
}

/// Failure related to synchronization operations
class SyncFailure extends Failure {
  const SyncFailure([String message = 'Synchronization failed']) : super(message);
}
