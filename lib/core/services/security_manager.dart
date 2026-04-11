import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'token_manager.dart';
import 'inactivity_tracker.dart';
import '../utils/validators.dart';
import '../config/api_config.dart';

/// Centralized security manager for the application
/// Coordinates all security-related services and policies
/// 
/// Features:
/// - Token management with secure storage
/// - Auto-logout after inactivity
/// - Input validation
/// - Sensitive data encryption
/// - Security policy enforcement
/// 
/// Usage:
/// ```dart
/// final securityManager = SecurityManager(
///   secureStorage: secureStorageService,
///   tokenManager: tokenManager,
///   onAutoLogout: () async {
///     // Handle auto-logout
///   },
/// );
/// 
/// await securityManager.initialize();
/// ```
class SecurityManager {
  final SecureStorageService _secureStorage;
  final TokenManager _tokenManager;
  final Future<void> Function() onAutoLogout;
  
  InactivityTracker? _inactivityTracker;
  bool _isInitialized = false;
  
  // Security configuration
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  SecurityManager({
    required SecureStorageService secureStorage,
    required TokenManager tokenManager,
    required this.onAutoLogout,
  })  : _secureStorage = secureStorage,
        _tokenManager = tokenManager;
  
  /// Initialize security manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize inactivity tracker
      _inactivityTracker = InactivityTracker(
        inactivityDuration: _inactivityTimeout,
        onInactivityTimeout: _handleAutoLogout,
      );
      
      // Check if user has valid session
      final hasToken = await _tokenManager.hasToken();
      if (hasToken) {
        // Start inactivity tracking for authenticated users
        _inactivityTracker?.start();
      }
      
      _isInitialized = true;
      print('🔒 [SecurityManager] Initialized successfully');
    } catch (e) {
      print('🔴 [SecurityManager] Initialization error: $e');
      rethrow;
    }
  }
  
  /// Start security monitoring (after successful login)
  Future<void> startMonitoring() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    _inactivityTracker?.start();
    print('🔒 [SecurityManager] Security monitoring started');
  }
  
  /// Stop security monitoring (on logout)
  Future<void> stopMonitoring() async {
    _inactivityTracker?.stop();
    print('🔒 [SecurityManager] Security monitoring stopped');
  }
  
  /// Record user activity (call on user interactions)
  void recordActivity() {
    _inactivityTracker?.recordActivity();
  }
  
  /// Handle auto-logout due to inactivity
  Future<void> _handleAutoLogout() async {
    try {
      print('⚠️ [SecurityManager] Auto-logout triggered due to inactivity');
      
      // Clear all sensitive data
      await clearAllData();
      
      // Notify app to handle logout
      await onAutoLogout();
    } catch (e) {
      print('🔴 [SecurityManager] Error during auto-logout: $e');
    }
  }
  
  /// Clear all sensitive data (on logout)
  Future<void> clearAllData() async {
    try {
      // Stop monitoring
      _inactivityTracker?.stop();
      
      // Clear tokens
      await _tokenManager.clearTokens();
      
      // Clear secure storage
      await _secureStorage.clearAll();
      
      print('🔒 [SecurityManager] All sensitive data cleared');
    } catch (e) {
      print('🔴 [SecurityManager] Error clearing data: $e');
      rethrow;
    }
  }
  
  /// Validate and sanitize user input
  /// Prevents injection attacks and ensures data integrity
  String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    String sanitized = input.trim();
    
    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    
    // Remove control characters (except newline and tab)
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized;
  }
  
  /// Validate email input
  bool validateEmail(String email) {
    return Validators.isValidEmail(email);
  }
  
  /// Validate password strength
  bool validatePassword(String password) {
    return Validators.isValidPassword(password);
  }
  
  /// Validate amount for financial transactions
  bool validateAmount(double amount, {double minAmount = 0.01}) {
    return Validators.validateAmount(amount, minAmount: minAmount) == null;
  }
  
  /// Check if sensitive operation requires re-authentication
  /// Returns true if user should be prompted to re-authenticate
  Future<bool> requiresReAuthentication() async {
    // Check if token is still valid
    final isValid = await _tokenManager.isTokenValid();
    if (!isValid) {
      return true;
    }
    
    // Check if token will expire soon
    final needsRefresh = await _tokenManager.needsRefresh();
    if (needsRefresh) {
      return true;
    }
    
    // Check inactivity time
    final timeSinceActivity = _inactivityTracker?.getTimeSinceLastActivity();
    if (timeSinceActivity != null && timeSinceActivity > Duration(minutes: 10)) {
      // Require re-auth if inactive for more than 10 minutes
      return true;
    }
    
    return false;
  }
  
  /// Encrypt sensitive data before storage
  Future<void> storeSensitiveData(String key, String value) async {
    await _secureStorage.storeValue(
      key: key,
      value: value,
      encrypt: true,
    );
  }
  
  /// Decrypt and retrieve sensitive data
  Future<String?> retrieveSensitiveData(String key) async {
    return await _secureStorage.getValue(
      key: key,
      encrypted: true,
    );
  }
  
  /// Check login attempts and enforce lockout
  Future<bool> checkLoginAttempts(String email) async {
    final key = 'login_attempts_$email';
    final attemptsStr = await _secureStorage.getValue(key: key);
    
    if (attemptsStr == null) {
      return true; // No previous attempts
    }
    
    final attempts = int.tryParse(attemptsStr) ?? 0;
    
    if (attempts >= _maxLoginAttempts) {
      // Check if lockout period has passed
      final lockoutKey = 'lockout_time_$email';
      final lockoutTimeStr = await _secureStorage.getValue(key: lockoutKey);
      
      if (lockoutTimeStr != null) {
        final lockoutTime = DateTime.tryParse(lockoutTimeStr);
        if (lockoutTime != null) {
          final now = DateTime.now();
          if (now.isBefore(lockoutTime.add(_lockoutDuration))) {
            print('⚠️ [SecurityManager] Account locked due to too many login attempts');
            return false; // Still locked out
          } else {
            // Lockout period expired, reset attempts
            await _secureStorage.deleteValue(key);
            await _secureStorage.deleteValue(lockoutKey);
            return true;
          }
        }
      }
    }
    
    return true; // Not locked out
  }
  
  /// Record failed login attempt
  Future<void> recordFailedLogin(String email) async {
    final key = 'login_attempts_$email';
    final attemptsStr = await _secureStorage.getValue(key: key);
    final attempts = (int.tryParse(attemptsStr ?? '0') ?? 0) + 1;
    
    await _secureStorage.storeValue(
      key: key,
      value: attempts.toString(),
    );
    
    if (attempts >= _maxLoginAttempts) {
      // Set lockout time
      final lockoutKey = 'lockout_time_$email';
      await _secureStorage.storeValue(
        key: lockoutKey,
        value: DateTime.now().toIso8601String(),
      );
      print('⚠️ [SecurityManager] Account locked after $attempts failed attempts');
    }
  }
  
  /// Clear login attempts (on successful login)
  Future<void> clearLoginAttempts(String email) async {
    final key = 'login_attempts_$email';
    final lockoutKey = 'lockout_time_$email';
    
    await _secureStorage.deleteValue(key);
    await _secureStorage.deleteValue(lockoutKey);
  }
  
  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime(String email) async {
    final lockoutKey = 'lockout_time_$email';
    final lockoutTimeStr = await _secureStorage.getValue(key: lockoutKey);
    
    if (lockoutTimeStr == null) return null;
    
    final lockoutTime = DateTime.tryParse(lockoutTimeStr);
    if (lockoutTime == null) return null;
    
    final unlockTime = lockoutTime.add(_lockoutDuration);
    final now = DateTime.now();
    
    if (now.isAfter(unlockTime)) {
      return null; // Lockout expired
    }
    
    return unlockTime.difference(now);
  }
  
  /// Validate that all API calls use HTTPS
  bool validateSecureUrl(String url) {
    // Allow localhost and local IPs in debug mode or development environment
    if (kDebugMode || ApiConfig.environment == 'development') {
      if (url.contains('localhost') || 
          url.contains('127.0.0.1') || 
          url.contains('10.0.2.2') ||  // Android emulator
          url.startsWith('http://192.168.') ||  // Local network
          url.startsWith('http://172.') ||  // Docker/local network
          url.startsWith('http://10.')) {  // Local network
        print('⚠️ [SecurityManager] Allowing insecure local URL in debug/development mode: $url');
        return true;
      }
    }
    
    if (!url.startsWith('https://')) {
      print('🔴 [SecurityManager] Insecure URL detected: $url');
      return false;
    }
    
    return true;
  }
  
  /// Check if logging sensitive information
  /// Returns true if the log message contains sensitive data
  bool containsSensitiveData(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check for common sensitive patterns
    final sensitivePatterns = [
      'password',
      'token',
      'secret',
      'api_key',
      'apikey',
      'authorization',
      'bearer',
      'credit_card',
      'ssn',
      'social_security',
    ];
    
    for (final pattern in sensitivePatterns) {
      if (lowerMessage.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Sanitize log message to remove sensitive data
  String sanitizeLogMessage(String message) {
    if (!containsSensitiveData(message)) {
      return message;
    }
    
    // Redact sensitive information
    String sanitized = message;
    
    // Redact tokens
    sanitized = sanitized.replaceAll(
      RegExp(r'(token|bearer|authorization)[\s:=]+[^\s,}]+', caseSensitive: false),
      r'$1: [REDACTED]',
    );
    
    // Redact passwords
    sanitized = sanitized.replaceAll(
      RegExp(r'(password|pwd)[\s:=]+[^\s,}]+', caseSensitive: false),
      r'$1: [REDACTED]',
    );
    
    return sanitized;
  }
  
  /// Get security status for debugging
  Map<String, dynamic> getSecurityStatus() {
    return {
      'isInitialized': _isInitialized,
      'isTracking': _inactivityTracker?.isTracking ?? false,
      'isAppInForeground': _inactivityTracker?.isAppInForeground ?? false,
      'timeSinceLastActivity': _inactivityTracker?.getTimeSinceLastActivity()?.inMinutes,
      'remainingTime': _inactivityTracker?.getRemainingTime()?.inMinutes,
      'inactivityTimeoutMinutes': _inactivityTimeout.inMinutes,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _inactivityTracker?.dispose();
    _isInitialized = false;
  }
}
