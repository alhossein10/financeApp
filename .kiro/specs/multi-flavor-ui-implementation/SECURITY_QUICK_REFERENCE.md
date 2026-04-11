# Security Implementation Quick Reference

## Quick Start

### 1. Initialize Security Manager

```dart
// In main.dart
final securityManager = SecurityManager(
  secureStorage: SecureStorageService(FlutterSecureStorage()),
  tokenManager: TokenManager(),
  onAutoLogout: () async {
    navigatorKey.currentState?.pushReplacementNamed('/login');
  },
);

await securityManager.initialize();
```

### 2. Wrap App with Activity Detector

```dart
MaterialApp(
  home: ActivityDetector(
    securityManager: securityManager,
    child: HomePage(),
  ),
);
```

### 3. Configure Secure API Client

```dart
final apiClient = DioApiClient(
  baseUrl: 'https://api.example.com', // HTTPS required
  tokenManager: tokenManager,
  enableCertificatePinning: true,
);
```

## Common Tasks

### Store Token Securely

```dart
await tokenManager.saveToken(
  token: jwtToken,
  expiresAt: DateTime.now().add(Duration(hours: 24)),
);
```

### Record User Activity

```dart
// Automatic with ActivityDetector
// Or manual:
securityManager.recordActivity();
```

### Validate Input

```dart
final sanitized = securityManager.sanitizeInput(userInput);
if (!securityManager.validateEmail(email)) {
  throw Exception('Invalid email');
}
```

### Clear Data on Logout

```dart
await securityManager.clearAllData();
```

### Check Re-Authentication

```dart
if (await securityManager.requiresReAuthentication()) {
  // Show re-auth dialog
}
```

## Security Features

| Feature | Status | Implementation |
|---------|--------|----------------|
| Secure Token Storage | ✅ | flutter_secure_storage |
| Auto-Logout (30 min) | ✅ | InactivityTracker |
| Data Encryption | ✅ | SecureStorageService |
| HTTPS Enforcement | ✅ | API Client validation |
| Certificate Pinning | ✅ | CertificatePinningService |
| Clear Data on Logout | ✅ | SecurityManager |
| Input Validation | ✅ | Validators + SecurityManager |
| No Sensitive Logging | ✅ | Log sanitization |

## Files

- `lib/core/services/security_manager.dart` - Main coordinator
- `lib/core/services/secure_storage_service.dart` - Secure storage
- `lib/core/services/token_manager.dart` - Token management
- `lib/core/services/inactivity_tracker.dart` - Auto-logout
- `lib/core/services/certificate_pinning_service.dart` - SSL pinning
- `lib/core/widgets/activity_detector.dart` - Activity tracking
- `lib/core/utils/validators.dart` - Input validation

## Testing

```bash
# Run security tests
flutter test test/core/services/security_manager_test.dart
flutter test test/core/services/inactivity_tracker_test.dart
```

## Troubleshooting

**Auto-logout not working?**
- Ensure ActivityDetector wraps your app
- Check SecurityManager is initialized
- Verify startMonitoring() called after login

**Certificate pinning errors?**
- Set allowSelfSigned: true for development
- Verify certificate fingerprints
- Check server certificate validity

**HTTPS validation failing?**
- Localhost allowed in debug mode only
- Use HTTPS URLs in production
- Check API_URL configuration
