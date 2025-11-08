# Token Management Guide

## Overview
This guide explains how to use the enhanced token management system in the Finance App.

## Quick Start

### 1. Check if User is Authenticated

```dart
import 'package:finance_app/injection_container.dart' as di;

// Quick local check (no server call)
final tokenManager = di.sl<TokenManager>();
final isValid = await tokenManager.isTokenValid();

if (isValid) {
  // User has valid token
  print('User is authenticated');
} else {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

### 2. Validate Token with Server

```dart
// Validate with server (includes auto-refresh if needed)
final authService = di.sl<LaravelAuthService>();
final isValid = await authService.validateToken();

if (!isValid) {
  // Token invalid, redirect to login
  Navigator.pushReplacementNamed(context, '/login');
}
```

### 3. Check if Token Needs Refresh

```dart
final tokenManager = di.sl<TokenManager>();

if (await tokenManager.needsRefresh()) {
  // Token expired or expiring soon
  final authService = di.sl<LaravelAuthService>();
  final refreshed = await authService.autoRefreshToken();
  
  if (!refreshed) {
    // Refresh failed, redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

### 4. Get Token Info for Debugging

```dart
final tokenManager = di.sl<TokenManager>();
final tokenInfo = await tokenManager.getTokenInfo();

print('Token Status:');
print('  Has Token: ${tokenInfo['hasToken']}');
print('  Expires At: ${tokenInfo['expiresAt']}');
print('  Is Expired: ${tokenInfo['isExpired']}');
print('  Will Expire Soon: ${tokenInfo['willExpireSoon']}');
print('  Needs Refresh: ${tokenInfo['needsRefresh']}');
print('  Last Validated: ${tokenInfo['lastValidated']}');
```

## Token Lifecycle

### 1. Login/Registration
```dart
// Token is automatically saved and set in API client
final authService = di.sl<LaravelAuthService>();
final user = await authService.login(
  email: 'user@example.com',
  password: 'password',
);
// Token is now stored and ready for API calls
```

### 2. App Start
```dart
// Token is automatically restored from secure storage
// This happens in main.dart before the app starts
// No action needed from developers
```

### 3. API Requests
```dart
// Bearer token is automatically injected in all API requests
final apiClient = di.sl<ApiClient>();
final response = await apiClient.get('/expenses');
// Authorization: Bearer {token} header is automatically added
```

### 4. Token Expiration
```dart
// Tokens are automatically refreshed 5 minutes before expiration
// This happens automatically when you call validateToken()
final authService = di.sl<LaravelAuthService>();
await authService.validateToken(); // Auto-refreshes if needed
```

### 5. Logout
```dart
// Token is revoked on server and cleared locally
final authService = di.sl<LaravelAuthService>();
await authService.logout();
// All tokens are now cleared
```

## Handling 401 Responses

The API client automatically handles 401 Unauthorized responses:

```dart
// When a 401 response is received:
// 1. Token is automatically cleared from API client
// 2. ApiException with statusCode 401 is thrown
// 3. Your BLoC/UI should redirect to login

try {
  final response = await apiClient.get('/protected-endpoint');
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Token invalid, redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

## Best Practices

### 1. Use Cached Validation for Quick Checks
```dart
// For quick checks without server call
final isValid = await tokenManager.isTokenValidCached();
```

### 2. Validate with Server Periodically
```dart
// Validate with server every few minutes
// This is already done automatically in AuthBloc
```

### 3. Handle Token Refresh Proactively
```dart
// Check and refresh before making important API calls
if (await tokenManager.needsRefresh()) {
  await authService.autoRefreshToken();
}
```

### 4. Clear Tokens on Logout
```dart
// Always use authService.logout() instead of manually clearing
await authService.logout();
```

## Configuration

### Token Refresh Threshold
Tokens are refreshed 5 minutes before expiration:
```dart
static const Duration _refreshThreshold = Duration(minutes: 5);
```

### Validation Cache Duration
Server validation results are cached for 1 minute:
```dart
static const Duration _validationCacheDuration = Duration(minutes: 1);
```

## Troubleshooting

### Token Not Being Injected in API Calls
```dart
// Check if token is set in API client
final apiClient = di.sl<ApiClient>();
final token = apiClient.getAuthToken();
print('Current token: $token');

// If null, restore from token manager
final tokenManager = di.sl<TokenManager>();
final storedToken = await tokenManager.getToken();
if (storedToken != null) {
  apiClient.setAuthToken(storedToken);
}
```

### Token Expired but Not Refreshing
```dart
// Check token info
final tokenInfo = await tokenManager.getTokenInfo();
print('Token info: $tokenInfo');

// Manually trigger refresh
final authService = di.sl<LaravelAuthService>();
await authService.refreshToken();
```

### 401 Errors After Login
```dart
// Verify token was saved correctly
final token = await tokenManager.getToken();
print('Stored token: $token');

// Verify token is set in API client
final apiClient = di.sl<ApiClient>();
print('API client token: ${apiClient.getAuthToken()}');
```

## Security Considerations

1. **Never log full tokens** - Only log first 20 characters for debugging
2. **Always use secure storage** - Tokens are encrypted at rest
3. **Clear tokens on logout** - Use `authService.logout()` to clear all tokens
4. **Validate tokens regularly** - Use `validateToken()` to check with server
5. **Handle 401 responses** - Always redirect to login on unauthorized errors

## Testing

### Unit Tests
```dart
// Test token validation
test('should validate token correctly', () async {
  final tokenManager = TokenManager();
  await tokenManager.saveToken(token: 'test_token');
  expect(await tokenManager.isTokenValid(), true);
});
```

### Integration Tests
```dart
// Test complete token lifecycle
test('complete token lifecycle', () async {
  // Save token
  await tokenManager.saveToken(token: 'test_token');
  
  // Validate token
  expect(await tokenManager.isTokenValid(), true);
  
  // Clear token
  await tokenManager.clearTokens();
  
  // Verify cleared
  expect(await tokenManager.hasToken(), false);
});
```

## API Reference

### TokenManager Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `saveToken()` | Save token to secure storage | `Future<void>` |
| `getToken()` | Get stored token | `Future<String?>` |
| `hasToken()` | Check if token exists | `Future<bool>` |
| `isTokenValid()` | Check if token is valid locally | `Future<bool>` |
| `isTokenExpired()` | Check if token is expired | `Future<bool>` |
| `needsRefresh()` | Check if token needs refresh | `Future<bool>` |
| `getAuthorizationHeader()` | Get Bearer token header | `Future<String?>` |
| `clearTokens()` | Clear all tokens | `Future<void>` |
| `getTokenInfo()` | Get token debug info | `Future<Map<String, dynamic>>` |

### LaravelAuthService Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `login()` | Login and save token | `Future<User>` |
| `register()` | Register and save token | `Future<User>` |
| `logout()` | Logout and clear tokens | `Future<void>` |
| `validateToken()` | Validate token with server | `Future<bool>` |
| `refreshToken()` | Refresh expired token | `Future<User>` |
| `autoRefreshToken()` | Auto-refresh if needed | `Future<bool>` |
| `isAuthenticated()` | Check if authenticated | `Future<bool>` |

## Support

For issues or questions about token management:
1. Check the logs for detailed error messages
2. Use `getTokenInfo()` to debug token state
3. Verify API configuration in `api_config.dart`
4. Check Laravel backend logs for server-side issues
