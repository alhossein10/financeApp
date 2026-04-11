# Error Handling Tests - Quick Reference

## Overview

Comprehensive error handling tests for the Finance App, covering all HTTP status codes, network errors, token refresh failures, and validation scenarios.

## Test File Location

```
test/core/api/comprehensive_error_handling_test.dart
```

## Running the Tests

```bash
# Run all error handling tests
flutter test test/core/api/comprehensive_error_handling_test.dart

# Run with verbose output
flutter test test/core/api/comprehensive_error_handling_test.dart --reporter expanded

# Run specific test group
flutter test test/core/api/comprehensive_error_handling_test.dart --name "Token Refresh Failure"
```

## Test Categories

### 1. Token Refresh Failure (5 tests)

Tests token refresh failure scenarios and token cleanup:

```dart
// Test Groups:
- Token refresh failure with 401
- Expired refresh token
- Invalid token format
- Revoked token
- Network error during refresh
```

**Key Assertions:**
- `verify(mockTokenManager.clearTokens()).called(1)`
- 401 errors on `/auth/refresh` trigger cleanup
- Network errors are properly handled

### 2. Insufficient Balance Errors (6 tests)

Tests multi-currency balance validation:

```dart
// Currencies Tested:
- USD balance for expenses
- SYP balance for expenses
- TRY balance for expenses
- USD balance for transfers
- USD balance for exchanges
```

**Key Assertions:**
- `statusCode: 422`
- `errors?['price_usd']` contains balance message
- User-friendly error messages

### 3. Validation Errors (6 tests)

Tests field-specific validation:

```dart
// Fields Tested:
- Multiple validation errors
- Email validation
- Password validation (multiple rules)
- Group code validation
- Exchange rate validation
- Date validation
```

**Key Assertions:**
- `statusCode: 422`
- `errors` map contains field-specific errors
- Multiple errors per field supported

### 4. Network Timeout (4 tests)

Tests different timeout scenarios:

```dart
// Timeout Types:
- Connection timeout
- Send timeout (file uploads)
- Receive timeout (downloads)
- No internet connection
```

**Key Assertions:**
- `isNetworkError: true`
- Appropriate exception types
- User-friendly messages

### 5. HTTP Status Codes (7 tests)

Tests all major HTTP error codes:

```dart
// Status Codes:
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 422 Unprocessable Entity
- 429 Too Many Requests
- 500 Internal Server Error
```

**Key Assertions:**
- Correct exception type for each status
- Status code preserved
- Appropriate error messages

## Common Test Patterns

### Testing HTTP Errors

```dart
test('should handle 422 validation error', () async {
  final dioException = DioException(
    requestOptions: RequestOptions(path: '/endpoint'),
    response: Response(
      requestOptions: RequestOptions(path: '/endpoint'),
      statusCode: 422,
      data: {
        'message': 'Validation failed',
        'errors': {
          'field': ['Error message'],
        },
      },
    ),
    type: DioExceptionType.badResponse,
  );

  when(mockDio.post(any, data: anyNamed('data')))
      .thenThrow(dioException);

  expect(
    () => apiClient.post('/endpoint', body: {}),
    throwsA(isA<ValidationException>()
        .having((e) => e.statusCode, 'statusCode', 422)
        .having((e) => e.errors?['field'], 'field error', isNotNull)),
  );
});
```

### Testing Network Errors

```dart
test('should handle connection timeout', () async {
  final dioException = DioException(
    requestOptions: RequestOptions(path: '/endpoint'),
    type: DioExceptionType.connectionTimeout,
    message: 'Connection timeout',
  );

  when(mockDio.get(any)).thenThrow(dioException);

  expect(
    () => apiClient.get('/endpoint'),
    throwsA(isA<ConnectionTimeoutException>()
        .having((e) => e.isNetworkError, 'isNetworkError', true)),
  );
});
```

### Testing Token Refresh Failure

```dart
test('should clear tokens on refresh failure', () async {
  final dioException = DioException(
    requestOptions: RequestOptions(path: '/auth/refresh'),
    response: Response(
      requestOptions: RequestOptions(path: '/auth/refresh'),
      statusCode: 401,
      data: {'message': 'Invalid refresh token'},
    ),
    type: DioExceptionType.badResponse,
  );

  await bearerTokenInterceptor.onError(dioException, mockErrorHandler);

  verify(mockTokenManager.clearTokens()).called(1);
});
```

## Exception Types Reference

| Status Code | Exception Type | Properties |
|------------|----------------|------------|
| 400 | `BadRequestException` | `isBadRequest: true` |
| 401 | `UnauthorizedException` | `isAuthError: true`, `isUnauthorized: true` |
| 403 | `ForbiddenException` | `isForbiddenError: true`, `isForbidden: true` |
| 404 | `NotFoundException` | `isNotFoundError: true`, `isNotFound: true` |
| 422 | `ValidationException` | `isValidationError: true`, `errors: Map` |
| 429 | `RateLimitException` | `isRateLimited: true`, `retryAfter: int?` |
| 500+ | `ServerException` | `isServerError: true` |
| Timeout | `ConnectionTimeoutException` | `isNetworkError: true` |
| No Internet | `NoInternetException` | `isNetworkError: true` |

## Verification Checklist

### Token Refresh Failure
- [x] 401 on refresh endpoint clears tokens
- [x] Expired token handled
- [x] Invalid token format handled
- [x] Revoked token handled
- [x] Network error during refresh handled

### Insufficient Balance
- [x] USD balance validation
- [x] SYP balance validation
- [x] TRY balance validation
- [x] Transfer balance validation
- [x] Exchange balance validation
- [x] User-friendly messages

### Validation Errors
- [x] Multiple validation errors
- [x] Email validation
- [x] Password validation
- [x] Group code validation
- [x] Exchange rate validation
- [x] Date validation

### Network Timeouts
- [x] Connection timeout
- [x] Send timeout
- [x] Receive timeout
- [x] No internet connection

### HTTP Status Codes
- [x] 400 Bad Request
- [x] 401 Unauthorized
- [x] 403 Forbidden
- [x] 404 Not Found
- [x] 422 Unprocessable Entity
- [x] 429 Too Many Requests
- [x] 500 Internal Server Error

## Test Results

```
✅ 28/28 tests passing
✅ All requirements verified (29.7, 29.8)
✅ 100% coverage of specified scenarios
```

## Troubleshooting

### Mock Generation Issues

If you see "MockXXX isn't a type" errors:

```bash
# Generate mocks
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Errors

The test file reuses mocks from existing test files:

```dart
import 'error_handling_verification_test.mocks.dart';
import 'bearer_token_interceptor_test.mocks.dart' show MockErrorInterceptorHandler;
```

### Test Failures

If tests fail, check:
1. Exception types match expected types
2. Status codes are correct
3. Error messages contain expected text
4. Mock setup is correct

## Related Files

- `test/core/api/error_handling_verification_test.dart` - Detailed error verification
- `test/core/api/bearer_token_interceptor_test.dart` - Token interceptor tests
- `lib/core/api/api_exception.dart` - Exception definitions
- `lib/core/api/api_client.dart` - API client implementation

## Next Steps

With error handling tests complete:
1. ✅ All HTTP status codes tested
2. ✅ Network errors tested
3. ✅ Token refresh failure tested
4. ✅ Validation errors tested
5. ✅ Balance errors tested

Ready to proceed to Phase 18: Documentation.

---

**Quick Commands:**

```bash
# Run all error handling tests
flutter test test/core/api/comprehensive_error_handling_test.dart

# Run with coverage
flutter test --coverage test/core/api/comprehensive_error_handling_test.dart

# Run specific test
flutter test test/core/api/comprehensive_error_handling_test.dart --name "insufficient balance"
```
