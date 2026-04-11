# Security Implementation Guide

This guide explains the comprehensive security implementation for the multi-flavor finance application.

## Overview

The security implementation addresses all requirements from Requirement 33 (Security Requirements):

1. ✅ Store tokens in flutter_secure_storage
2. ✅ Implement auto-logout after 30 minutes inactivity
3. ✅ Encrypt sensitive data at rest
4. ✅ Use HTTPS for all API calls
5. ✅ Implement certificate pinning
6. ✅ Clear all data on logout
7. ✅ Validate all user inputs
8. ✅ Don't log sensitive information

## Components

### 1. Secure Storage Service

**File**: `lib/core/services/secure_storage_service.dart`

Provides secure storage for sensitive data using `flutter_secure_storage`:

```dart
final secureStorage = SecureStorageService(FlutterSecureStorage());

// Store auth token
await secureStorage.storeAuthToken(token);

// Store encrypted data
await secureStorage.storeValue(
  key: 'sensitive_data',
  value: data,
  encrypt: true,
);

// Clear all data on logout
await secureStorage.clearAll();
```

**Features**:
- Platform-specific secure storage (Keychain on iOS, KeyStore on Android)
- Encryption for sensitive data
- Credential management with "Remember Me" support
- Automatic cleanup on logout

### 2. Token Manager

**File**: `lib/core/services/token_manager.dart`

Manages authentication tokens securely:

```dart
final tokenManager = TokenManager();

// Save token
await tokenManager.saveToken(
  token: jwtToken,
  expiresAt: DateTime.now().add(Duration(hours: 24)),
);

// Get authorization header
final authHeader = await tokenManager.getAuthorizationHeader();

// Check if token is valid
final isValid = await tokenManager.isTokenValid();

// Clear tokens on logout
await tokenManager.clearTokens();
```

**Features**:
- Secure token storage
- Token expiration tracking
- Automatic token refresh detection
- Bearer token header generation

### 3. Inactivity Tracker

**File**: `lib/core/services/inactivity_tracker.dart`

Tracks user inactivity and triggers auto-logout:

```dart
final tracker = InactivityTracker(
  inactivityDuration: Duration(minutes: 30),
  onInactivityTimeout: () async {
    // Handle auto-logout
    await authBloc.logout();
    Navigator.pushReplacementNamed(context, '/login');
  },
);

// Start tracking
tracker.start();

// Record user activity
tracker.recordActivity();

// Stop tracking on logout
tracker.stop();
```

**Features**:
- 30-minute inactivity timeout
- App lifecycle awareness (pauses when app is in background)
- Automatic logout on timeout
- Activity recording on user interactions

### 4. Certificate Pinning Service

**File**: `lib/core/services/certificate_pinning_service.dart`

Implements SSL certificate pinning to prevent MITM attacks:

```dart
final dio = Dio();

// Configure certificate pinning
CertificatePinningService.configureCertificatePinning(
  dio,
  allowedSHA256Fingerprints: [
    'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
  ],
  allowSelfSigned: false, // Set to true only in development
);
```

**Features**:
- SHA-256 certificate fingerprint validation
- Self-signed certificate support for development
- Automatic certificate validation on all HTTPS requests
- Detailed logging for debugging

### 5. Security Manager

**File**: `lib/core/services/security_manager.dart`

Centralized security coordinator:

```dart
final securityManager = SecurityManager(
  secureStorage: secureStorageService,
  tokenManager: tokenManager,
  onAutoLogout: () async {
    // Handle auto-logout
  },
);

// Initialize
await securityManager.initialize();

// Start monitoring after login
await securityManager.startMonitoring();

// Record activity
securityManager.recordActivity();

// Validate input
final sanitized = securityManager.sanitizeInput(userInput);

// Check if re-authentication required
final needsReAuth = await securityManager.requiresReAuthentication();

// Clear all data on logout
await securityManager.clearAllData();
```

**Features**:
- Coordinates all security services
- Input validation and sanitization
- Login attempt tracking and lockout
- Sensitive data encryption
- Security policy enforcement
- Log message sanitization

### 6. Activity Detector Widget

**File**: `lib/core/widgets/activity_detector.dart`

Automatically tracks user activity:

```dart
MaterialApp(
  home: ActivityDetector(
    securityManager: securityManager,
    child: HomePage(),
  ),
);
```

**Features**:
- Wraps entire app to track all interactions
- Detects taps, scrolls, and gestures
- Automatically reports activity to SecurityManager
- Mixin available for individual widgets

## Integration

### 1. Setup in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage
  final secureStorage = SecureStorageService(FlutterSecureStorage());
  
  // Initialize token manager
  final tokenManager = TokenManager();
  
  // Initialize security manager
  final securityManager = SecurityManager(
    secureStorage: secureStorage,
    tokenManager: tokenManager,
    onAutoLogout: () async {
      // Navigate to login
      navigatorKey.currentState?.pushReplacementNamed('/login');
    },
  );
  
  await securityManager.initialize();
  
  runApp(MyApp(
    securityManager: securityManager,
  ));
}
```

### 2. Wrap App with Activity Detector

```dart
class MyApp extends StatelessWidget {
  final SecurityManager securityManager;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ActivityDetector(
        securityManager: securityManager,
        child: HomePage(),
      ),
    );
  }
}
```

### 3. Configure API Client with Security

```dart
final apiClient = DioApiClient(
  baseUrl: ApiConfig.apiUrl, // Must be HTTPS
  tokenManager: tokenManager,
  enableCertificatePinning: true,
  allowedCertificateFingerprints: [
    // Add your server's certificate fingerprints
  ],
  onTokenRefreshFailed: () async {
    await securityManager.clearAllData();
  },
);
```

### 4. Handle Login

```dart
Future<void> login(String email, String password) async {
  // Validate input
  final sanitizedEmail = securityManager.sanitizeInput(email);
  final sanitizedPassword = securityManager.sanitizeInput(password);
  
  // Check login attempts
  final canLogin = await securityManager.checkLoginAttempts(sanitizedEmail);
  if (!canLogin) {
    final remaining = await securityManager.getRemainingLockoutTime(sanitizedEmail);
    throw Exception('Account locked. Try again in ${remaining?.inMinutes} minutes');
  }
  
  try {
    // Attempt login
    final response = await authService.login(sanitizedEmail, sanitizedPassword);
    
    // Save token
    await tokenManager.saveToken(
      token: response.token,
      expiresAt: response.expiresAt,
    );
    
    // Clear login attempts
    await securityManager.clearLoginAttempts(sanitizedEmail);
    
    // Start security monitoring
    await securityManager.startMonitoring();
    
  } catch (e) {
    // Record failed attempt
    await securityManager.recordFailedLogin(sanitizedEmail);
    rethrow;
  }
}
```

### 5. Handle Logout

```dart
Future<void> logout() async {
  // Stop security monitoring
  await securityManager.stopMonitoring();
  
  // Clear all sensitive data
  await securityManager.clearAllData();
  
  // Navigate to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

## Security Best Practices

### 1. Input Validation

Always validate and sanitize user input:

```dart
// Email validation
if (!securityManager.validateEmail(email)) {
  throw Exception('Invalid email format');
}

// Password validation
if (!securityManager.validatePassword(password)) {
  throw Exception('Password does not meet requirements');
}

// Amount validation
if (!securityManager.validateAmount(amount)) {
  throw Exception('Invalid amount');
}

// Sanitize input
final sanitized = securityManager.sanitizeInput(userInput);
```

### 2. Sensitive Operations

Require re-authentication for sensitive operations:

```dart
Future<void> performSensitiveOperation() async {
  // Check if re-authentication required
  if (await securityManager.requiresReAuthentication()) {
    // Show re-authentication dialog
    final authenticated = await showReAuthDialog();
    if (!authenticated) {
      throw Exception('Re-authentication required');
    }
  }
  
  // Proceed with operation
  await sensitiveOperation();
}
```

### 3. Logging

Never log sensitive information:

```dart
// Bad - logs sensitive data
print('User password: $password');
print('Auth token: $token');

// Good - sanitizes logs
final message = 'User logged in with token';
final sanitized = securityManager.sanitizeLogMessage(message);
print(sanitized);

// Check if message contains sensitive data
if (securityManager.containsSensitiveData(message)) {
  print('[REDACTED]');
} else {
  print(message);
}
```

### 4. HTTPS Enforcement

All API calls automatically use HTTPS:

```dart
// API client validates URLs
final apiClient = DioApiClient(
  baseUrl: 'https://api.example.com', // ✅ HTTPS
);

// This will throw an error in production:
final apiClient = DioApiClient(
  baseUrl: 'http://api.example.com', // ❌ HTTP
);
```

### 5. Certificate Pinning

Configure certificate pinning for production:

```dart
// Get your server's certificate fingerprint:
// openssl s_client -connect api.example.com:443 < /dev/null | openssl x509 -fingerprint -sha256 -noout

final apiClient = DioApiClient(
  enableCertificatePinning: true,
  allowedCertificateFingerprints: [
    'YOUR_CERTIFICATE_SHA256_FINGERPRINT',
  ],
);
```

## Testing

### 1. Test Inactivity Timeout

```dart
test('should logout after 30 minutes of inactivity', () async {
  final tracker = InactivityTracker(
    inactivityDuration: Duration(seconds: 5), // Short duration for testing
    onInactivityTimeout: () async {
      loggedOut = true;
    },
  );
  
  tracker.start();
  
  await Future.delayed(Duration(seconds: 6));
  
  expect(loggedOut, true);
});
```

### 2. Test Secure Storage

```dart
test('should encrypt and decrypt sensitive data', () async {
  final storage = SecureStorageService(FlutterSecureStorage());
  
  await storage.storeValue(
    key: 'test',
    value: 'sensitive',
    encrypt: true,
  );
  
  final retrieved = await storage.getValue(
    key: 'test',
    encrypted: true,
  );
  
  expect(retrieved, 'sensitive');
});
```

### 3. Test Input Validation

```dart
test('should validate email format', () {
  final securityManager = SecurityManager(...);
  
  expect(securityManager.validateEmail('test@example.com'), true);
  expect(securityManager.validateEmail('invalid'), false);
});
```

## Troubleshooting

### Issue: Auto-logout not working

**Solution**: Ensure ActivityDetector wraps your app and SecurityManager is initialized:

```dart
MaterialApp(
  home: ActivityDetector(
    securityManager: securityManager,
    child: HomePage(),
  ),
);
```

### Issue: Certificate pinning errors

**Solution**: 
1. Verify certificate fingerprints are correct
2. Set `allowSelfSigned: true` for development
3. Check server certificate is valid

### Issue: HTTPS validation failing for localhost

**Solution**: Localhost is automatically allowed in debug mode. For production, use HTTPS.

## Security Checklist

- [x] Tokens stored in flutter_secure_storage
- [x] Auto-logout after 30 minutes inactivity
- [x] Sensitive data encrypted at rest
- [x] HTTPS enforced for all API calls
- [x] Certificate pinning implemented
- [x] All data cleared on logout
- [x] User input validated and sanitized
- [x] Sensitive information not logged
- [x] Login attempt tracking and lockout
- [x] Re-authentication for sensitive operations

## Additional Resources

- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Certificate Pinning Guide](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
