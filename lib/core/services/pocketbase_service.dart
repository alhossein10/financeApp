import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';

/// PocketBase service for authentication and basic operations
class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();
  
  late final PocketBase pb;
  
  /// Initialize PocketBase client
  void initialize() {
    pb = PocketBase(PocketBaseConfig.baseUrl);
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => pb.authStore.isValid;
  
  /// Get current user record
  RecordModel? get currentUser => pb.authStore.model;
  
  /// Get current user ID
  String? get currentUserId => currentUser?.id;
  
  /// Check if current user is admin
  bool get isAdmin {
    if (!isAuthenticated) return false;
    final role = currentUser?.data['role'];
    return role == 'admin';
  }
  
  /// Login with email and password
  Future<RecordAuth> login(String email, String password) async {
    try {
      return await pb
          .collection(PocketBaseConfig.usersCollection)
          .authWithPassword(email, password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  /// Register new user
  Future<RecordModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'username': username,
        'role': 'user', // Always create as regular user
      };
      
      return await pb
          .collection(PocketBaseConfig.usersCollection)
          .create(body: body);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  /// Logout current user
  void logout() {
    pb.authStore.clear();
  }
  
  /// Get user by ID
  Future<RecordModel?> getUserById(String userId) async {
    try {
      return await pb
          .collection(PocketBaseConfig.usersCollection)
          .getOne(userId);
    } catch (e) {
      return null;
    }
  }
  
  /// Update user profile
  Future<RecordModel> updateProfile({
    required String userId,
    String? username,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      
      return await pb
          .collection(PocketBaseConfig.usersCollection)
          .update(userId, body: body);
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
  
  /// Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      await pb
          .collection(PocketBaseConfig.usersCollection)
          .update(currentUserId!, body: {
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': newPassword,
      });
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }
}
