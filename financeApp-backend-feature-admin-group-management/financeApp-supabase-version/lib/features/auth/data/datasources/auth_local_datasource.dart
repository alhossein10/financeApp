import '../models/session_model.dart';
import '../models/user_model.dart';

/// Abstract interface for authentication local data source
/// Defines contracts for local authentication operations
abstract class AuthLocalDataSource {
  /// Login with email and password
  /// Returns [UserModel] if credentials are valid
  /// Throws [AuthenticationException] if credentials are invalid
  /// Throws [DatabaseException] if database operation fails
  Future<UserModel> login(String email, String password);

  /// Register a new user with username, email, and password
  /// Returns [UserModel] for the newly created user
  /// Throws [ValidationException] if validation fails
  /// Throws [DatabaseException] if database operation fails
  Future<UserModel> register(String username, String email, String password);

  /// Logout the current user
  /// Clears cached user data and auth token
  /// Throws [DatabaseException] if operation fails
  Future<void> logout();

  /// Get cached user from secure storage
  /// Returns [UserModel] if user is cached, null otherwise
  Future<UserModel?> getCachedUser();

  /// Cache user data in secure storage
  /// Throws [CacheException] if caching fails
  Future<void> cacheUser(UserModel user);

  /// Cache authentication token in secure storage
  /// Throws [CacheException] if caching fails
  Future<void> cacheAuthToken(String token);

  /// Get cached authentication token
  /// Returns token string if cached, null otherwise
  Future<String?> getAuthToken();

  /// Clear all authentication data from cache
  /// Removes user data and auth token
  Future<void> clearAuthData();

  /// Create a new session for a user
  /// Returns [SessionModel] for the created session
  /// Throws [DatabaseException] if operation fails
  Future<SessionModel> createSession(int userId, String token, Duration duration);

  /// Get session by token
  /// Returns [SessionModel] if session exists, null otherwise
  Future<SessionModel?> getSessionByToken(String token);

  /// Update session last activity timestamp
  /// Throws [DatabaseException] if operation fails
  Future<void> updateSessionActivity(String token);

  /// Delete session by token
  /// Throws [DatabaseException] if operation fails
  Future<void> deleteSession(String token);

  /// Delete all sessions for a user
  /// Throws [DatabaseException] if operation fails
  Future<void> deleteAllUserSessions(int userId);

  /// Get user by ID
  /// Returns [UserModel] if user exists
  /// Throws [NotFoundException] if user not found
  Future<UserModel> getUserById(int userId);

  /// Get user by email
  /// Returns [UserModel] if user exists, null otherwise
  Future<UserModel?> getUserByEmail(String email);

  /// Get user by username
  /// Returns [UserModel] if user exists, null otherwise
  Future<UserModel?> getUserByUsername(String username);

  /// Update user's last login timestamp
  /// Throws [DatabaseException] if operation fails
  Future<void> updateLastLogin(int userId);

  /// Update user password
  /// Throws [DatabaseException] if operation fails
  Future<void> updatePassword(int userId, String newPasswordHash);

  /// Create password reset token
  /// Returns the generated token
  /// Throws [DatabaseException] if operation fails
  Future<String> createPasswordResetToken(int userId);

  /// Validate password reset token
  /// Returns user ID if token is valid
  /// Throws [ValidationException] if token is invalid or expired
  Future<int> validatePasswordResetToken(String token);

  /// Mark password reset token as used
  /// Throws [DatabaseException] if operation fails
  Future<void> markPasswordResetTokenAsUsed(String token);

  /// Hash a password for storage
  /// Returns the hashed password string
  String hashPassword(String password);
}
