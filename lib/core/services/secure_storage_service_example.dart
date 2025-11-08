/// Example usage of SecureStorageService
/// 
/// This file demonstrates how to use the SecureStorageService
/// for storing and retrieving sensitive data securely.
/// 
/// ⚠️ SECURITY WARNING ⚠️
/// DO NOT include this file in production builds.
/// This is for demonstration purposes only.
/// Sensitive data like tokens and passwords are redacted in print statements.
library;

import 'secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void exampleUsage() async {
  // Initialize the service
  final secureStorage = const FlutterSecureStorage();
  final secureStorageService = SecureStorageService(secureStorage);

  // ==================== Auth Token Examples ====================
  
  // Store auth token
  await secureStorageService.storeAuthToken('your-auth-token-here');
  
  // Retrieve auth token
  final token = await secureStorageService.getAuthToken();
  print('Auth Token: ${token != null ? "[REDACTED]" : "null"}');
  
  // Check if auth token exists
  final hasToken = await secureStorageService.hasAuthToken();
  print('Has Auth Token: $hasToken');

  // ==================== User ID Examples ====================
  
  // Store user ID
  await secureStorageService.storeUserId(123);
  
  // Retrieve user ID
  final userId = await secureStorageService.getUserId();
  print('User ID: $userId');

  // ==================== Remember Me / Credentials Examples ====================
  
  // Store credentials when "Remember Me" is checked
  await secureStorageService.storeCredentials(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  
  // Retrieve stored credentials
  final credentials = await secureStorageService.getStoredCredentials();
  if (credentials != null) {
    print('Email: ${credentials['email']}');
    print('Password: [REDACTED]'); // Never log passwords
  }
  
  // Check if remember me is enabled
  final rememberMeEnabled = await secureStorageService.isRememberMeEnabled();
  print('Remember Me Enabled: $rememberMeEnabled');
  
  // Clear stored credentials
  await secureStorageService.clearStoredCredentials();

  // ==================== Generic Storage Examples ====================
  
  // Store a value without encryption
  await secureStorageService.storeValue(
    key: 'user_preference',
    value: 'dark_mode',
    encrypt: false,
  );
  
  // Store a value with encryption
  await secureStorageService.storeValue(
    key: 'sensitive_data',
    value: 'confidential information',
    encrypt: true,
  );
  
  // Retrieve a value without decryption
  final preference = await secureStorageService.getValue(
    key: 'user_preference',
    encrypted: false,
  );
  print('User Preference: $preference');
  
  // Retrieve a value with decryption
  final sensitiveData = await secureStorageService.getValue(
    key: 'sensitive_data',
    encrypted: true,
  );
  print('Sensitive Data: ${sensitiveData != null ? "[REDACTED]" : "null"}');
  
  // Check if a key exists
  final exists = await secureStorageService.containsKey('user_preference');
  print('Key Exists: $exists');
  
  // Delete a specific value
  await secureStorageService.deleteValue('user_preference');

  // ==================== Clear All Examples ====================
  
  // Clear only authentication-related data
  await secureStorageService.clearAuthData();
  
  // Clear ALL secure storage data (use on logout)
  await secureStorageService.clearAll();
}

/// Example: Auto-login with stored credentials
Future<void> autoLoginExample(SecureStorageService secureStorageService) async {
  // Check if remember me is enabled
  if (await secureStorageService.isRememberMeEnabled()) {
    // Get stored credentials
    final credentials = await secureStorageService.getStoredCredentials();
    
    if (credentials != null) {
      final email = credentials['email']!;
      final password = credentials['password']!;
      
      // Use these credentials to auto-login
      print('Auto-logging in with email: $email');
      // Call your login function here
    }
  }
}

/// Example: Secure logout
Future<void> secureLogoutExample(SecureStorageService secureStorageService) async {
  // Clear all secure storage on logout
  await secureStorageService.clearAll();
  
  print('User logged out and all secure data cleared');
}
