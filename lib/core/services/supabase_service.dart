import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Main Supabase service for authentication and basic operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  
  late final SupabaseClient client;
  
  /// Initialize Supabase client
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: true, // Enable debug logging during development
    );
    client = Supabase.instance.client;
    
    print('[SupabaseService] Initialized with URL: ${SupabaseConfig.supabaseUrl}');
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;
  
  /// Get current user
  User? get currentUser => client.auth.currentUser;
  
  /// Get current user ID
  String? get currentUserId => currentUser?.id;
  
  /// Get current user email
  String? get currentUserEmail => currentUser?.email;
  
  /// Check if current user is admin
  Future<bool> get isAdmin async {
    if (!isAuthenticated) return false;
    
    try {
      final profile = await getUserProfile(currentUserId!);
      return profile?['role'] == 'admin';
    } catch (e) {
      print('[SupabaseService] Error checking admin status: $e');
      return false;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('[SupabaseService] Attempting sign in for: $email');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('[SupabaseService] Sign in successful for: ${response.user!.email}');
        
        // Get user profile to check role
        final profile = await getUserProfile(response.user!.id);
        print('[SupabaseService] User role: ${profile?['role']}');
      }
      
      return response;
    } catch (e) {
      print('[SupabaseService] Sign in failed: $e');
      rethrow;
    }
  }
  
  /// Sign up with email, password, and username
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('[SupabaseService] Attempting sign up for: $email');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );
      
      if (response.user != null) {
        print('[SupabaseService] Sign up successful for: ${response.user!.email}');
        
        // Create user profile
        await createUserProfile(
          userId: response.user!.id,
          username: username,
          email: email,
          role: 'user', // Default role
        );
        
        print('[SupabaseService] User profile created');
      }
      
      return response;
    } catch (e) {
      print('[SupabaseService] Sign up failed: $e');
      rethrow;
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      print('[SupabaseService] Signing out user: ${currentUserEmail}');
      await client.auth.signOut();
      print('[SupabaseService] Sign out successful');
    } catch (e) {
      print('[SupabaseService] Sign out failed: $e');
      rethrow;
    }
  }
  
  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String username,
    required String email,
    required String role,
  }) async {
    try {
      await client.from(SupabaseConfig.userProfilesTable).insert({
        'id': userId,
        'username': username,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('[SupabaseService] User profile created for: $username');
    } catch (e) {
      print('[SupabaseService] Failed to create user profile: $e');
      rethrow;
    }
  }
  
  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('[SupabaseService] Failed to get user profile: $e');
      return null;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? email,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      
      await client
          .from(SupabaseConfig.userProfilesTable)
          .update(updates)
          .eq('id', userId);
      
      print('[SupabaseService] User profile updated for: $userId');
    } catch (e) {
      print('[SupabaseService] Failed to update user profile: $e');
      rethrow;
    }
  }
  
  /// Change password
  Future<void> changePassword(String newPassword) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      print('[SupabaseService] Password changed successfully');
    } catch (e) {
      print('[SupabaseService] Failed to change password: $e');
      rethrow;
    }
  }
  
  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      print('[SupabaseService] Uploading file to: $bucket/$path');
      
      await client.storage.from(bucket).upload(path, file);
      
      print('[SupabaseService] File uploaded successfully');
      return path;
    } catch (e) {
      print('[SupabaseService] Failed to upload file: $e');
      rethrow;
    }
  }
  
  /// Get public URL for file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return client.storage.from(bucket).getPublicUrl(path);
  }
  
  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
      print('[SupabaseService] File deleted: $bucket/$path');
    } catch (e) {
      print('[SupabaseService] Failed to delete file: $e');
      rethrow;
    }
  }
  
  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Get database client for direct queries
  SupabaseQueryBuilder from(String table) => client.from(table);
  
  /// Get storage client
  SupabaseStorageClient get storage => client.storage;
  
  /// Get realtime client
  RealtimeClient get realtime => client.realtime;
}