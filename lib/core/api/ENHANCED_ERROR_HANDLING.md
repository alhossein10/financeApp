# Enhanced Error Handling System

## Overview

The enhanced error handling system provides comprehensive, user-friendly error handling across all BLoCs with special support for:

- **401 Unauthorized**: Automatic logout requirement
- **403 Forbidden**: Access denied messages for admin-only features
- **422 Validation Error**: Field-specific error messages
- **429 Rate Limit**: Retry-after duration handling
- All other HTTP status codes with appropriate messages

## Components

### 1. ApiException (Enhanced)

Located in `lib/core/api/api_exception.dart`

#### New Properties

```dart
// Status code checks
bool get isUnauthorized => statusCode == 401;
bool get isForbidden => statusCode == 403;
bool get isNotFound => statusCode == 404;
bool get isValidationError => statusCode == 422;
bool get isRateLimited => statusCode == 429;
bool get isBadRequest => statusCode == 400;
bool get isServerError => statusCode != null && statusCode! >= 500;
bool get isNetworkError => statusCode == null;
```

#### User-Friendly Messages

```dart
// Get comprehensive user-friendly error message
String get userFriendlyMessage;

// Get formatted validation errors with field names
String getFormattedValidationErrors();
```

#### Status Code Handling

| Status Code | User-Friendly Message |
|-------------|----------------------|
| 400 | Invalid request. Please check your input. |
| 401 | Session expired. Please login again. |
| 403 | Access denied. You don't have permission for this action. |
| 404 | Resource not found. |
| 422 | Validation failed. (Shows field-specific errors) |
| 429 | Too many requests. Please try again in X seconds. |
| 500 | Internal server error. Please try again later. |
| 502 | Bad gateway. The server is temporarily unavailable. |
| 503 | Service unavailable. Please try again later. |
| 504 | Gateway timeout. The server took too long to respond. |

### 2. ErrorHandler Utility

Located in `lib/core/utils/error_handler.dart`

#### Usage in BLoCs

```dart
import '../../../../core/utils/error_handler.dart';

// In your BLoC event handler
result.fold(
  (failure) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    emit(YourErrorState(
      errorResult.displayMessage,
      requiresLogout: errorResult.requiresLogout,
      isForbidden: errorResult.isForbidden,
      isValidationError: errorResult.isValidationError,
      isRateLimited: errorResult.isRateLimited,
      retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
    ));
  },
  (success) => emit(YourSuccessState(success)),
);
```

#### EnhancedErrorResult Properties

```dart
class EnhancedErrorResult {
  final String message;              // Basic error message
  final bool requiresLogout;         // True for 401 errors
  final bool isForbidden;            // True for 403 errors
  final bool isValidationError;      // True for 422 errors
  final bool isRateLimited;          // True for 429 errors
  final String? formattedValidationErrors;  // Formatted field errors
  final Duration? retryAfterDuration;       // Retry duration for 429
  final Failure originalFailure;     // Original failure object
  
  // Get display message (uses formatted validation errors if available)
  String get displayMessage;
  
  // Get retry message for rate limit errors
  String? get retryMessage;
}
```

### 3. Enhanced BLoC States

All error states now include additional metadata:

```dart
class YourErrorState extends YourState {
  final String message;
  final bool requiresLogout;         // Trigger logout for 401
  final bool isForbidden;            // Show access denied for 403
  final bool isValidationError;      // Show validation errors for 422
  final bool isRateLimited;          // Show rate limit message for 429
  final int? retryAfterSeconds;      // Seconds to wait for 429
  
  const YourErrorState(
    this.message, {
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });
}
```

## Updated BLoCs

The following BLoCs have been updated with enhanced error handling:

1. **TransferBloc** - `lib/features/transfers/presentation/bloc/transfer_bloc.dart`
2. **IncomingBloc** - `lib/features/incoming/presentation/bloc/incoming_bloc.dart`
3. **ExpenseBloc** - `lib/features/expenses/presentation/bloc/expense_bloc.dart`
4. **FundBoxBloc** - `lib/features/fund_box/presentation/bloc/fund_box_bloc.dart`
5. **AdminBloc** - `lib/features/admin/presentation/bloc/admin_bloc.dart`

## UI Integration

### Handling Error States in UI

```dart
BlocListener<YourBloc, YourState>(
  listener: (context, state) {
    if (state is YourErrorState) {
      // Handle 401 - Automatic logout
      if (state.requiresLogout) {
        // Clear session and navigate to login
        context.read<AuthBloc>().add(LogoutRequested());
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      
      // Handle 403 - Access denied
      if (state.isForbidden) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        return;
      }
      
      // Handle 422 - Validation errors
      if (state.isValidationError) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Validation Error'),
            content: Text(state.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      
      // Handle 429 - Rate limit
      if (state.isRateLimited) {
        final retryMessage = state.retryAfterSeconds != null
            ? ' Please try again in ${state.retryAfterSeconds} seconds.'
            : ' Please try again later.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message + retryMessage),
            duration: Duration(seconds: state.retryAfterSeconds ?? 5),
          ),
        );
        return;
      }
      
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
)
```

### Example: Complete Error Handling Widget

```dart
class ErrorHandlingWidget extends StatelessWidget {
  final Widget child;
  
  const ErrorHandlingWidget({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TransferBloc, TransferState>(
          listener: _handleTransferError,
        ),
        BlocListener<ExpenseBloc, ExpenseState>(
          listener: _handleExpenseError,
        ),
        // Add more listeners as needed
      ],
      child: child,
    );
  }
  
  void _handleTransferError(BuildContext context, TransferState state) {
    if (state is TransferError) {
      _handleError(context, state.message, state);
    }
  }
  
  void _handleExpenseError(BuildContext context, ExpenseState state) {
    if (state is ExpenseError) {
      _handleError(context, state.message, state);
    }
  }
  
  void _handleError(
    BuildContext context,
    String message,
    dynamic state,
  ) {
    // Check for requiresLogout
    if (state.requiresLogout == true) {
      _handleLogout(context, message);
      return;
    }
    
    // Check for forbidden
    if (state.isForbidden == true) {
      _showAccessDeniedDialog(context, message);
      return;
    }
    
    // Check for validation error
    if (state.isValidationError == true) {
      _showValidationErrorDialog(context, message);
      return;
    }
    
    // Check for rate limit
    if (state.isRateLimited == true) {
      _showRateLimitSnackBar(context, message, state.retryAfterSeconds);
      return;
    }
    
    // Show generic error
    _showErrorSnackBar(context, message);
  }
  
  void _handleLogout(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }
  
  void _showAccessDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showValidationErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Error'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showRateLimitSnackBar(
    BuildContext context,
    String message,
    int? retryAfterSeconds,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: retryAfterSeconds ?? 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

## Testing Error Scenarios

### Manual Testing Checklist

- [ ] **401 Unauthorized**: Test with expired token
  - Should show "Session expired" message
  - Should trigger automatic logout
  - Should redirect to login page

- [ ] **403 Forbidden**: Test admin-only features with regular user
  - Should show "Access denied" message
  - Should not crash the app
  - Should allow user to continue using other features

- [ ] **422 Validation Error**: Test with invalid input
  - Should show field-specific error messages
  - Should format errors in a readable way
  - Should allow user to correct and retry

- [ ] **429 Rate Limit**: Test by making many rapid requests
  - Should show "Too many requests" message
  - Should display retry-after duration if available
  - Should prevent further requests temporarily

- [ ] **Network Errors**: Test with no internet connection
  - Should show "No internet connection" message
  - Should queue operations for offline sync

- [ ] **Server Errors (500, 502, 503, 504)**: Test with backend issues
  - Should show appropriate server error messages
  - Should not expose technical details to users

## Benefits

1. **Consistent Error Handling**: All BLoCs use the same error handling pattern
2. **User-Friendly Messages**: Clear, actionable error messages for users
3. **Automatic Logout**: 401 errors automatically trigger logout
4. **Access Control**: 403 errors properly handled for admin features
5. **Validation Feedback**: 422 errors show field-specific validation messages
6. **Rate Limit Handling**: 429 errors show retry-after duration
7. **Type Safety**: Strongly typed error states with metadata
8. **Easy Testing**: Error scenarios can be easily tested

## Migration Guide

If you have existing error handling code, follow these steps:

1. **Update BLoC imports**:
   ```dart
   import '../../../../core/utils/error_handler.dart';
   ```

2. **Replace error handling**:
   ```dart
   // Old way
   result.fold(
     (failure) => emit(YourErrorState(failure.message)),
     (success) => emit(YourSuccessState(success)),
   );
   
   // New way
   result.fold(
     (failure) {
       final errorResult = ErrorHandler.createEnhancedError(failure);
       emit(YourErrorState(
         errorResult.displayMessage,
         requiresLogout: errorResult.requiresLogout,
         isForbidden: errorResult.isForbidden,
         isValidationError: errorResult.isValidationError,
         isRateLimited: errorResult.isRateLimited,
         retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
       ));
     },
     (success) => emit(YourSuccessState(success)),
   );
   ```

3. **Update error states**:
   ```dart
   class YourErrorState extends YourState {
     final String message;
     final bool requiresLogout;
     final bool isForbidden;
     final bool isValidationError;
     final bool isRateLimited;
     final int? retryAfterSeconds;
     
     const YourErrorState(
       this.message, {
       this.requiresLogout = false,
       this.isForbidden = false,
       this.isValidationError = false,
       this.isRateLimited = false,
       this.retryAfterSeconds,
     });
     
     @override
     List<Object?> get props => [
       message,
       requiresLogout,
       isForbidden,
       isValidationError,
       isRateLimited,
       retryAfterSeconds,
     ];
   }
   ```

4. **Update UI error handling**: Use the examples above to handle different error types in your UI.

## Best Practices

1. **Always use ErrorHandler**: Don't manually construct error messages
2. **Handle requiresLogout**: Always check and handle 401 errors
3. **Show appropriate UI**: Use dialogs for critical errors, snackbars for minor ones
4. **Log errors**: Log detailed errors for debugging while showing user-friendly messages
5. **Test all scenarios**: Test each error type to ensure proper handling
6. **Don't expose technical details**: Never show stack traces or technical errors to users
7. **Provide actionable feedback**: Tell users what went wrong and how to fix it

## Future Enhancements

- [ ] Add error analytics tracking
- [ ] Implement automatic retry for transient errors
- [ ] Add error recovery suggestions
- [ ] Implement circuit breaker pattern for repeated failures
- [ ] Add error reporting to backend
