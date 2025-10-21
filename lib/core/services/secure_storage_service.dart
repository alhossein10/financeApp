import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

/// Service for securely storing and retrieving sensitive data
/// Provides encryption for sensitive data before storage
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  
  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _encryptionKeyKey = 'encryption_key';
  
  SecureStorageService(this._secureStorage);
  
  // ==================== Auth Token Methods ====================
  
  /// Store authentication token securely
  Future<void> storeAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }
  
  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }
  
  /// Check if auth token exists
  Future<bool> hasAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
  
  // ==================== User ID Methods ====================
  
  /// Store user ID
  Future<void> storeUserId(int userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId.toString());
  }
  
  /// Retrieve user ID
  Future<int?> getUserId() async {
    final userIdStr = await _secureStorage.read(key: _userIdKey);
    if (userIdStr == null) return null;
    return int.tryParse(userIdStr);
  }
  
  // ==================== Remember Me / Credentials Methods ====================
  
  /// Store user credentials when "Remember Me" is checked
  /// Credentials are encrypted before storage
  Future<void> storeCredentials({
    required String email,
    required String password,
  }) async {
    // Mark that remember me is enabled
    await _secureStorage.write(key: _rememberMeKey, value: 'true');
    
    // Get or create encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();
    
    // Encrypt and store email
    final encryptedEmail = _encryptData(email, encryptionKey);
    await _secureStorage.write(key: _savedEmailKey, value: encryptedEmail);
    
    // Encrypt and store password
    final encryptedPassword = _encryptData(password, encryptionKey);
    await _secureStorage.write(key: _savedPasswordKey, value: encryptedPassword);
  }
  
  /// Retrieve stored credentials if "Remember Me" was enabled
  /// Returns null if credentials are not stored or remember me is disabled
  Future<Map<String, String>?> getStoredCredentials() async {
    final rememberMe = await _secureStorage.read(key: _rememberMeKey);
    if (rememberMe != 'true') return null;
    
    final encryptionKey = await _getOrCreateEncryptionKey();
    
    final encryptedEmail = await _secureStorage.read(key: _savedEmailKey);
    final encryptedPassword = await _secureStorage.read(key: _savedPasswordKey);
    
    if (encryptedEmail == null || encryptedPassword == null) return null;
    
    try {
      final email = _decryptData(encryptedEmail, encryptionKey);
      final password = _decryptData(encryptedPassword, encryptionKey);
      
      return {
        'email': email,
        'password': password,
      };
    } catch (e) {
      // If decryption fails, clear stored credentials
      await clearStoredCredentials();
      return null;
    }
  }
  
  /// Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final rememberMe = await _secureStorage.read(key: _rememberMeKey);
    return rememberMe == 'true';
  }
  
  /// Clear stored credentials
  Future<void> clearStoredCredentials() async {
    await _secureStorage.delete(key: _rememberMeKey);
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
  }
  
  // ==================== Clear All Methods ====================
  
  /// Clear all secure storage data (used on logout)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
  
  /// Clear only authentication-related data (keeps other app data)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await clearStoredCredentials();
  }
  
  // ==================== Encryption Methods ====================
  
  /// Get or create a device-specific encryption key
  Future<String> _getOrCreateEncryptionKey() async {
    String? key = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (key == null) {
      // Generate a new encryption key
      key = _generateEncryptionKey();
      await _secureStorage.write(key: _encryptionKeyKey, value: key);
    }
    
    return key;
  }
  
  /// Generate a random encryption key
  String _generateEncryptionKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$timestamp-$random';
    
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// Encrypt data using simple XOR cipher with the encryption key
  /// For production, consider using more robust encryption like AES
  String _encryptData(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    
    final encryptedBytes = <int>[];
    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    // Convert to base64 for safe storage
    return base64.encode(encryptedBytes);
  }
  
  /// Decrypt data using simple XOR cipher with the encryption key
  String _decryptData(String encryptedData, String key) {
    final encryptedBytes = base64.decode(encryptedData);
    final keyBytes = utf8.encode(key);
    
    final decryptedBytes = <int>[];
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decryptedBytes);
  }
  
  // ==================== Generic Secure Storage Methods ====================
  
  /// Store any string value securely with optional encryption
  Future<void> storeValue({
    required String key,
    required String value,
    bool encrypt = false,
  }) async {
    if (encrypt) {
      final encryptionKey = await _getOrCreateEncryptionKey();
      final encryptedValue = _encryptData(value, encryptionKey);
      await _secureStorage.write(key: key, value: encryptedValue);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }
  
  /// Retrieve any string value with optional decryption
  Future<String?> getValue({
    required String key,
    bool encrypted = false,
  }) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    
    if (encrypted) {
      try {
        final encryptionKey = await _getOrCreateEncryptionKey();
        return _decryptData(value, encryptionKey);
      } catch (e) {
        return null;
      }
    }
    
    return value;
  }
  
  /// Delete a specific value
  Future<void> deleteValue(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }
}
