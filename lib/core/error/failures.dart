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
  const DatabaseFailure([super.message = 'Database operation failed']);
}

/// Failure related to authentication operations
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication failed']);
}

/// Failure related to validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure when user is not authorized to perform an action
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access']);
}

/// Failure when user lacks required permissions (403 Forbidden)
class AuthorizationFailure extends Failure {
  const AuthorizationFailure([super.message = 'Access denied. Insufficient permissions.']);
}

/// Failure when user has insufficient funds
class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([super.message = 'Insufficient funds']);
}

/// Failure related to network operations
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Failure when a requested resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Failure related to server errors
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Failure related to cache operations
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache operation failed']);
}

/// Failure when session has expired
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Session has expired']);
}

/// Failure related to storage operations
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage operation failed']);
}

/// Failure related to synchronization operations
class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Synchronization failed']);
}

/// Failure related to API operations
class ApiFailure extends Failure {
  const ApiFailure([super.message = 'API operation failed']);
}

/// Failure when group code is invalid
class GroupCodeInvalidFailure extends Failure {
  const GroupCodeInvalidFailure([super.message = 'The selected group code is invalid']);
}

/// Failure when group code is required but missing
class GroupCodeRequiredFailure extends Failure {
  const GroupCodeRequiredFailure([super.message = 'The group code field is required']);
}

/// Failure when user is already in a group
class AlreadyInGroupFailure extends Failure {
  const AlreadyInGroupFailure([super.message = 'You are already in a group']);
}

/// Failure when admin tries to join another group
class AdminCannotJoinFailure extends Failure {
  const AdminCannotJoinFailure([super.message = 'Admins cannot join other groups']);
}

/// Failure when member is not found in the group
class MemberNotFoundFailure extends Failure {
  const MemberNotFoundFailure([super.message = 'User not found or not in your group']);
}

/// Failure when admin tries to remove themselves
class CannotRemoveSelfFailure extends Failure {
  const CannotRemoveSelfFailure([super.message = 'You cannot remove yourself from the group']);
}
