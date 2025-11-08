/// Base class for all exceptions in the application
/// Exceptions represent unexpected errors that need to be caught and converted to Failures
class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => 'AppException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Exception thrown when a database operation fails
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.cause]);
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.cause]);
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}

/// Exception thrown when user is not authorized
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, [super.cause]);
}

/// Exception thrown when a network operation fails
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Exception thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.cause]);
}

/// Exception thrown when a server error occurs
class ServerException extends AppException {
  const ServerException(super.message, [super.cause]);
}

/// Exception thrown when a cache operation fails
class CacheException extends AppException {
  const CacheException(super.message, [super.cause]);
}

/// Exception thrown when session has expired
class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message, [super.cause]);
}

/// Exception thrown when user has insufficient funds
class InsufficientFundsException extends AppException {
  const InsufficientFundsException(super.message, [super.cause]);
}

/// Exception thrown when invalid credentials are provided
class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException([super.message = 'Invalid credentials provided']);
}

/// Exception thrown when a user already exists
class UserAlreadyExistsException extends AuthenticationException {
  const UserAlreadyExistsException([super.message = 'User already exists']);
}

/// Exception thrown when a token is invalid or expired
class InvalidTokenException extends AuthenticationException {
  const InvalidTokenException([super.message = 'Invalid or expired token']);
}
