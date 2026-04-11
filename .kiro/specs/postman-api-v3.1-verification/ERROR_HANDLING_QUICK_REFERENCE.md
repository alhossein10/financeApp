# Error Handling Quick Reference

## Quick Error Type Reference

| Status Code | Exception Type | User Message | Action |
|------------|----------------|--------------|--------|
| 400 | `BadRequestException` | "Invalid request. Please check your input." | Show validation errors |
| 401 | `UnauthorizedException` | "Session expired. Please login again." | Redirect to login |
| 403 | `ForbiddenException` | "Access denied. You don't have permission." | Show access denied |
| 404 | `NotFoundException` | "Resource not found." | Show not found |
| 422 | `ValidationException` | Field-specific errors | Show field errors |
| 429 | `RateLimitException` | "Too many requests. Try in X seconds." | Wait and retry |
| 500 | `ServerException` | "Internal server error. Try again later." | Show retry option |
| 502 | `ServerException` | "Server temporarily unavailable." | Show retry option |
| 503 | `ServerException` | "Service unavailable. Try again later." | Show retry option |
| 504 | `ServerException` | "Server took too long to respond." | Show retry option |
| Timeout | `ConnectionTimeoutException` | "Connection timeout. Check internet." | Check connection |
| No Internet | `NoInternetException` | "No internet connection." | Check network |

## Common Usage Patterns

### Pattern 1: Basic Error Handling
```dart
try {
  final result = await apiClient.get('/endpoint');
  return result;
} on ApiException catch (e) {
  showSnackBar(e.userFriendlyMessage);
  rethrow;
}
```

### Pattern 2: Validation Error Display
```dart
try {
  await apiClient.post('/create', body: data);
} on ValidationException catch (e) {
  // Show formatted errors with field names
  showErrorDialog(e.getFormattedValidationErrors());
}
```

### Pattern 3: Auth Error Handling
```dart
try {
  await apiClient.get('/protected');
} on UnauthorizedException catch (e) {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
  showSnackBar(e.userFriendlyMessage);
}
```

### Pattern 4: Rate Limit Handling
```dart
try {
  await apiClient.get('/analytics');
} on RateLimitException catch (e) {
  final duration = e.getRetryAfterDuration();
  if (duration != null) {
    await Future.delayed(duration);
    return retry(); // Retry after waiting
  }
}
```

### Pattern 5: Server Error with Retry
```dart
try {
  return await apiClient.get('/data');
} on ServerException catch (e) {
  final shouldRetry = await showRetryDialog(e.userFriendlyMessage);
  if (shouldRetry) {
    return retry();
  }
}
```

### Pattern 6: Network Error Handling
```dart
try {
  await apiClient.get('/profile');
} on NoInternetException catch (e) {
  showOfflineBanner(e.userFriendlyMessage);
} on ConnectionTimeoutException catch (e) {
  showTimeoutDialog(e.userFriendlyMessage);
}
```

## Exception Properties

### All Exceptions Have:
- `statusCode`: HTTP status code (null for network errors)
- `message`: Error message from server
- `errors`: Validation errors map (for 400, 422)
- `userFriendlyMessage`: User-friendly error message

### Validation Exception Specific:
- `getValidationErrors()`: List of error strings
- `getFormattedValidationErrors()`: Formatted string with field names

### Rate Limit Exception Specific:
- `retryAfter`: Seconds to wait (from Retry-After header)
- `getRetryAfterDuration()`: Duration object for retry timing

### Boolean Checks:
- `isAuthError` / `isUnauthorized`: 401 error
- `isForbiddenError` / `isForbidden`: 403 error
- `isNotFoundError` / `isNotFound`: 404 error
- `isValidationError`: 422 error
- `isRateLimited`: 429 error
- `isServerError`: 5xx error
- `isNetworkError`: No status code (timeout, no internet)
- `isBadRequest`: 400 error

## Error Message Examples

### Validation Error (422)
```
• email: The email field is required.
• email: The email must be valid.
• password: The password must be at least 8 characters.
```

### Rate Limit Error (429)
```
Too many requests. Please try again in 60 seconds.
```

### Server Error (500)
```
Internal server error. Please try again later.
```

### Network Error
```
No internet connection. Please check your network.
```

## Testing Error Handling

### Test Validation Errors
```dart
test('should handle validation errors', () async {
  // Arrange
  when(mockApiClient.post(any, body: anyNamed('body')))
      .thenThrow(ValidationException(
        errors: {'email': ['Invalid email']},
      ));

  // Act & Assert
  expect(
    () => repository.create(data),
    throwsA(isA<ValidationException>()),
  );
});
```

### Test Rate Limit
```dart
test('should handle rate limit with retry', () async {
  // Arrange
  when(mockApiClient.get(any))
      .thenThrow(RateLimitException(retryAfter: 60));

  // Act & Assert
  expect(
    () => repository.fetch(),
    throwsA(isA<RateLimitException>()
        .having((e) => e.retryAfter, 'retryAfter', 60)),
  );
});
```

## BLoC Error Handling Pattern

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  Future<void> _onFetchData(FetchDataEvent event, Emitter<MyState> emit) async {
    emit(MyState.loading());
    
    try {
      final data = await repository.fetchData();
      emit(MyState.success(data));
    } on ValidationException catch (e) {
      emit(MyState.validationError(e.getFormattedValidationErrors()));
    } on UnauthorizedException catch (e) {
      emit(MyState.authError(e.userFriendlyMessage));
    } on ServerException catch (e) {
      emit(MyState.serverError(e.userFriendlyMessage, canRetry: true));
    } on NoInternetException catch (e) {
      emit(MyState.networkError(e.userFriendlyMessage));
    } on ApiException catch (e) {
      emit(MyState.error(e.userFriendlyMessage));
    }
  }
}
```

## UI Error Display Pattern

```dart
Widget build(BuildContext context) {
  return BlocConsumer<MyBloc, MyState>(
    listener: (context, state) {
      if (state is MyErrorState) {
        if (state.isAuthError) {
          // Redirect to login
          Navigator.pushReplacementNamed(context, '/login');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage),
            action: state.canRetry
                ? SnackBarAction(
                    label: 'Retry',
                    onPressed: () => context.read<MyBloc>().add(RetryEvent()),
                  )
                : null,
          ),
        );
      }
    },
    builder: (context, state) {
      // Build UI
    },
  );
}
```

## Retry Logic Pattern

```dart
Future<T> retryOnError<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int retryCount = 0;
  
  while (true) {
    try {
      return await operation();
    } on ServerException catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) rethrow;
      
      final delay = initialDelay * retryCount;
      await Future.delayed(delay);
    } on RateLimitException catch (e) {
      final duration = e.getRetryAfterDuration();
      if (duration != null) {
        await Future.delayed(duration);
        return await operation();
      }
      rethrow;
    }
  }
}
```

## Error Logging Pattern

```dart
try {
  await apiClient.get('/endpoint');
} on ApiException catch (e, stackTrace) {
  // Log for debugging
  logger.error(
    'API Error: ${e.message}',
    error: e,
    stackTrace: stackTrace,
    extra: {
      'statusCode': e.statusCode,
      'endpoint': '/endpoint',
      'errors': e.errors,
    },
  );
  
  // Show user-friendly message
  showSnackBar(e.userFriendlyMessage);
}
```

## Summary

✅ **All HTTP status codes handled** (400, 401, 403, 404, 422, 429, 500-504)
✅ **Network errors handled** (timeout, no connection)
✅ **User-friendly messages** for all error types
✅ **Validation errors** formatted with field names
✅ **Rate limiting** with retry timing
✅ **Server errors** with retry option
✅ **Type-safe** exception handling
✅ **Well-tested** with comprehensive test suite

---

**For detailed implementation**: See `lib/core/api/api_exception.dart`
**For test examples**: See `test/core/api/error_handling_verification_test.dart`
**For complete documentation**: See `TASK_15_ERROR_HANDLING_VERIFICATION.md`
