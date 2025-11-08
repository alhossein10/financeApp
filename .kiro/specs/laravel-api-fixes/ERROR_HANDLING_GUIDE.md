# Error Handling Guide

## Overview

This guide documents the comprehensive error handling system implemented for the Laravel API integration. All API errors are handled consistently with user-friendly messages and appropriate recovery actions.

## Error Types

### ApiException

The base exception class for all API-related errors:

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  final dynamic response;
  
  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
    this.response,
  });
}
```

### Error Properties

```dart
// Check error type
bool get isUnauthorized => statusCode == 401;
bool get isForbidden => statusCode == 403;
bool get isNotFound => statusCode == 404;
bool get isValidationError => statusCode == 422;
bool get isRateLimited => statusCode == 429;
bool get isServerError => statusCode >= 500;

// Get user-friendly message
String get userFriendlyMessage;
```

## HTTP Status Codes

### 400 Bad Request

**Cause**: Invalid request format or parameters

**User Message**: "Invalid request. Please check your input."

**Handling**:
```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    showError('Invalid request. Please check your input.');
  }
}
```

### 401 Unauthorized

**Cause**: Missing, invalid, or expired authentication token

**User Message**: "Session expired. Please login again."

**Handling**:
```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Clear stored token
    await tokenManager.clearToken();
    
    // Redirect to login
    Navigator.pushReplacementNamed(context, '/login');
    
    showError('Session expired. Please login again.');
  }
}
```

**Automatic Handling**: The `ApiClient` automatically handles 401 errors by:
1. Clearing the stored token
2. Emitting an authentication failure event
3. Triggering logout flow

### 403 Forbidden

**Cause**: User lacks required permissions (e.g., non-admin accessing admin endpoints)

**User Message**: "Access denied. You don't have permission for this action."

**Handling**:
```dart
try {
  await fundBoxApiDataSource.getFundBox();
} on ApiException catch (e) {
  if (e.isForbidden) {
    showError('Access denied. Admin privileges required.');
  }
}
```

**Admin-Only Features**:
- Fund Box management
- Admin Dashboard
- Audit Logs
- User management

### 404 Not Found

**Cause**: Requested resource doesn't exist

**User Message**: "Resource not found."

**Handling**:
```dart
try {
  await expenseApiDataSource.getExpense(id);
} on ApiException catch (e) {
  if (e.isNotFound) {
    showError('Expense not found. It may have been deleted.');
  }
}
```

### 422 Unprocessable Entity

**Cause**: Validation errors in request data

**User Message**: Field-specific validation errors

**Response Format**:
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."],
    "amount": ["The amount must be greater than 0."]
  }
}
```

**Handling**:
```dart
try {
  await expenseApiDataSource.createExpense(expense);
} on ApiException catch (e) {
  if (e.isValidationError) {
    // Display field-specific errors
    final errorMessage = e.userFriendlyMessage;
    showError(errorMessage);
    
    // Or handle individual fields
    if (e.errors != null) {
      e.errors!.forEach((field, messages) {
        if (messages is List) {
          for (var message in messages) {
            showFieldError(field, message);
          }
        }
      });
    }
  }
}
```

**Formatted Error Message**:
```
The email field is required.
The amount must be greater than 0.
```

### 429 Too Many Requests

**Cause**: Rate limit exceeded

**User Message**: "Too many requests. Please try again later."

**Handling**:
```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.isRateLimited) {
    showError('Too many requests. Please try again in a few minutes.');
  }
}
```

**Rate Limits**:
- Authentication endpoints: 5 requests per minute
- General API: 60 requests per minute
- Admin endpoints: 100 requests per minute

### 500 Internal Server Error

**Cause**: Server-side error

**User Message**: "Server error. Please try again later."

**Handling**:
```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.isServerError) {
    // Log error details for debugging
    logger.error('Server error', error: e, stackTrace: stackTrace);
    
    showError('Server error. Please try again later.');
  }
}
```

### 502 Bad Gateway / 503 Service Unavailable

**Cause**: Server is down or unreachable

**User Message**: "Server is temporarily unavailable. Please try again later."

**Handling**:
```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.statusCode == 502 || e.statusCode == 503) {
    showError('Server is temporarily unavailable. Please try again later.');
  }
}
```

## BLoC Error Handling

### Standard Pattern

```dart
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  Future<void> _handleApiCall<T>(
    Emitter<ExpenseState> emit,
    Future<T> Function() apiCall,
    void Function(T) onSuccess,
  ) async {
    emit(ExpenseLoading());
    
    try {
      final result = await apiCall();
      onSuccess(result);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        emit(ExpenseError(
          'Session expired',
          requiresLogin: true,
        ));
      } else if (e.isForbidden) {
        emit(ExpenseError('Access denied'));
      } else if (e.isValidationError) {
        emit(ExpenseError(
          e.userFriendlyMessage,
          validationErrors: e.errors,
        ));
      } else {
        emit(ExpenseError(e.userFriendlyMessage));
      }
    } on NetworkException catch (e) {
      emit(ExpenseError('No internet connection. Please check your network.'));
    } catch (e) {
      emit(ExpenseError('An unexpected error occurred'));
      logger.error('Unexpected error', error: e);
    }
  }
}
```

### Error State

```dart
class ExpenseError extends ExpenseState {
  final String message;
  final bool requiresLogin;
  final Map<String, dynamic>? validationErrors;
  
  const ExpenseError(
    this.message, {
    this.requiresLogin = false,
    this.validationErrors,
  });
}
```

## UI Error Display

### Error Snackbar

```dart
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}
```

### Validation Error Display

```dart
Widget buildTextField({
  required String label,
  required TextEditingController controller,
  Map<String, dynamic>? validationErrors,
}) {
  final fieldErrors = validationErrors?[label.toLowerCase()] as List?;
  final errorText = fieldErrors?.isNotEmpty == true 
    ? fieldErrors!.first 
    : null;
  
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      errorMaxLines: 2,
    ),
  );
}
```

### Error Dialog

```dart
void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Network Error Handling

### NetworkException

```dart
class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
}
```

### Handling Network Errors

```dart
try {
  await apiCall();
} on NetworkException catch (e) {
  showError('No internet connection. Please check your network.');
  
  // Queue operation for later sync
  await queueManager.addToQueue(operation);
} on SocketException catch (e) {
  showError('Unable to connect to server. Please check your connection.');
} on TimeoutException catch (e) {
  showError('Request timed out. Please try again.');
}
```

## Offline Queue

When network errors occur, operations are automatically queued:

```dart
// Automatically queued when offline
try {
  await expenseApiDataSource.createExpense(expense);
} on NetworkException catch (e) {
  // Operation is automatically added to queue
  showInfo('Saved locally. Will sync when online.');
}

// Queue is processed automatically when connection is restored
```

## Error Logging

### Development Logging

```dart
if (kDebugMode) {
  print('API Error: ${e.statusCode} - ${e.message}');
  print('Response: ${e.response}');
  print('Stack trace: $stackTrace');
}
```

### Production Logging

```dart
// Log to analytics service
await analyticsService.logError(
  error: e,
  stackTrace: stackTrace,
  context: {
    'endpoint': endpoint,
    'method': method,
    'userId': userId,
  },
);
```

## Best Practices

### 1. Always Handle Specific Errors First

```dart
try {
  await apiCall();
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Handle 401
  } else if (e.isForbidden) {
    // Handle 403
  } else if (e.isValidationError) {
    // Handle 422
  } else {
    // Handle other API errors
  }
} on NetworkException catch (e) {
  // Handle network errors
} catch (e) {
  // Handle unexpected errors
}
```

### 2. Provide Context-Specific Messages

```dart
// Bad
showError('Error occurred');

// Good
showError('Failed to create expense. Please check your input and try again.');
```

### 3. Log Errors for Debugging

```dart
try {
  await apiCall();
} catch (e, stackTrace) {
  logger.error('Failed to create expense', error: e, stackTrace: stackTrace);
  showError('Failed to create expense');
}
```

### 4. Handle Unauthorized Globally

```dart
// In ApiClient
if (response.statusCode == 401) {
  await tokenManager.clearToken();
  eventBus.fire(UnauthorizedEvent());
  throw ApiException(statusCode: 401, message: 'Unauthorized');
}

// In main app
eventBus.on<UnauthorizedEvent>().listen((event) {
  Navigator.pushReplacementNamed(context, '/login');
});
```

### 5. Validate Before API Calls

```dart
// Validate locally first
if (!PaymentMethod.isValid(paymentMethod)) {
  throw ValidationException('Invalid payment method');
}

// Then make API call
await expenseApiDataSource.createExpense(expense);
```

## Testing Error Handling

### Unit Tests

```dart
test('should handle 422 validation error', () async {
  // Arrange
  when(mockApiClient.post(any, body: any))
    .thenThrow(ApiException(
      statusCode: 422,
      message: 'Validation failed',
      errors: {'amount': ['Amount is required']},
    ));
  
  // Act
  final result = await dataSource.createExpense(expense);
  
  // Assert
  expect(result, isA<Left<Failure, Expense>>());
});
```

### Widget Tests

```dart
testWidgets('should display validation error', (tester) async {
  // Arrange
  final bloc = MockExpenseBloc();
  when(bloc.state).thenReturn(ExpenseError(
    'Validation failed',
    validationErrors: {'amount': ['Amount is required']},
  ));
  
  // Act
  await tester.pumpWidget(ExpensePage(bloc: bloc));
  
  // Assert
  expect(find.text('Amount is required'), findsOneWidget);
});
```

## Common Error Scenarios

### Scenario 1: Session Expired During Operation

```dart
// User is creating an expense when token expires
try {
  await expenseApiDataSource.createExpense(expense);
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Save expense locally
    await expenseLocalDataSource.createExpense(expense);
    
    // Queue for sync
    await queueManager.addToQueue(operation);
    
    // Redirect to login
    Navigator.pushReplacementNamed(context, '/login');
    
    showInfo('Session expired. Expense saved locally and will sync after login.');
  }
}
```

### Scenario 2: Non-Admin Accessing Admin Feature

```dart
try {
  await fundBoxApiDataSource.getFundBox();
} on ApiException catch (e) {
  if (e.isForbidden) {
    // Hide admin features
    setState(() {
      showAdminFeatures = false;
    });
    
    showError('Access denied. Admin privileges required.');
  }
}
```

### Scenario 3: Network Error During Sync

```dart
try {
  await batchSyncService.syncAll();
} on NetworkException catch (e) {
  // Keep data in queue
  showInfo('Sync will resume when connection is restored.');
} on ApiException catch (e) {
  if (e.isServerError) {
    // Retry later
    await Future.delayed(Duration(minutes: 5));
    await batchSyncService.syncAll();
  }
}
```

## Summary

- Always use `ApiException` for API errors
- Provide user-friendly error messages
- Handle 401 errors globally with automatic logout
- Handle 403 errors with appropriate access denied messages
- Display validation errors (422) with field-specific messages
- Queue operations when network errors occur
- Log errors for debugging in development
- Test error handling thoroughly
