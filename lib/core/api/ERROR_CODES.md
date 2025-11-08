# API Error Codes Reference

## Overview

This document provides a comprehensive reference for all error codes used in the Laravel backend integration. Each error code includes its meaning, common causes, and recommended actions.

---

## HTTP Status Codes

### 2xx Success

#### 200 OK
- **Meaning**: Request successful
- **Usage**: GET, PUT, DELETE requests
- **Action**: Process response data normally

#### 201 Created
- **Meaning**: Resource created successfully
- **Usage**: POST requests
- **Action**: Process created resource data

#### 204 No Content
- **Meaning**: Request successful, no content to return
- **Usage**: DELETE requests
- **Action**: Update UI to reflect deletion

---

### 4xx Client Errors

#### 400 Bad Request
- **Meaning**: Invalid request parameters or malformed request
- **Common Causes**:
  - Missing required fields
  - Invalid data format
  - Malformed JSON
- **Action**: 
  - Validate request data before sending
  - Check API documentation for correct format
  - Display validation errors to user

**Example Response:**
```json
{
  "message": "Invalid request data",
  "errors": {
    "price_usd": ["The price usd field is required."]
  }
}
```

#### 401 Unauthorized
- **Meaning**: Authentication required or token invalid
- **Common Causes**:
  - Missing authentication token
  - Expired token
  - Invalid token
  - Token revoked
- **Action**:
  - Clear stored tokens
  - Redirect to login page
  - Prompt user to log in again

**Example Response:**
```json
{
  "message": "Unauthenticated."
}
```

**User Message**: "Your session has expired. Please log in again."

#### 403 Forbidden
- **Meaning**: User lacks permission to access resource
- **Common Causes**:
  - Regular user accessing admin endpoint
  - User accessing another user's data
  - Insufficient role permissions
- **Action**:
  - Display "Access denied" message
  - Hide unauthorized features in UI
  - Check user role before making request

**Example Response:**
```json
{
  "message": "This action is unauthorized."
}
```

**User Message**: "You do not have permission to perform this action."

#### 404 Not Found
- **Meaning**: Requested resource doesn't exist
- **Common Causes**:
  - Invalid resource ID
  - Resource deleted
  - Incorrect endpoint URL
- **Action**:
  - Display "Not found" message
  - Redirect to list view
  - Refresh data from server

**Example Response:**
```json
{
  "message": "Resource not found"
}
```

**User Message**: "The requested item was not found."

#### 408 Request Timeout
- **Meaning**: Request took too long to complete
- **Common Causes**:
  - Slow network connection
  - Large file upload
  - Server processing delay
- **Action**:
  - Retry request
  - Increase timeout duration
  - Check network connection

**User Message**: "Request timed out. Please try again."

#### 422 Unprocessable Entity (Validation Error)
- **Meaning**: Request data failed validation
- **Common Causes**:
  - Invalid email format
  - Password too short
  - Required field missing
  - Invalid date format
  - Duplicate entry
- **Action**:
  - Display field-specific errors
  - Highlight invalid fields
  - Provide correction guidance

**Example Response:**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email field is required.",
      "The email must be a valid email address."
    ],
    "password": [
      "The password must be at least 8 characters."
    ],
    "expense_date": [
      "The expense date is not a valid date."
    ]
  }
}
```

**Handling in Code:**
```dart
try {
  await apiClient.post('/expenses', body: data);
} on ValidationException catch (e) {
  final errors = e.getValidationErrors();
  for (final error in errors) {
    // Display each error to user
    showError(error);
  }
}
```

#### 429 Too Many Requests (Rate Limited)
- **Meaning**: Too many requests in a short time
- **Common Causes**:
  - Rapid button clicking
  - Automated requests
  - Exceeded rate limit
- **Action**:
  - Wait for specified duration
  - Display countdown timer
  - Implement client-side throttling

**Example Response:**
```json
{
  "message": "Too many requests. Please try again later."
}
```

**Response Headers:**
```
Retry-After: 60
```

**Handling in Code:**
```dart
try {
  await apiClient.post('/expenses', body: data);
} on RateLimitException catch (e) {
  final retryAfter = e.getRetryAfterDuration();
  showMessage('Too many requests. Please wait ${retryAfter?.inSeconds} seconds.');
  await Future.delayed(retryAfter ?? Duration(seconds: 60));
  // Retry request
}
```

---

### 5xx Server Errors

#### 500 Internal Server Error
- **Meaning**: Unexpected server error
- **Common Causes**:
  - Server bug
  - Database error
  - Unhandled exception
- **Action**:
  - Retry request (automatic)
  - Display generic error message
  - Log error for debugging
  - Contact support if persistent

**User Message**: "Server error. Please try again later."

#### 502 Bad Gateway
- **Meaning**: Server received invalid response from upstream
- **Common Causes**:
  - Proxy server error
  - Backend server down
  - Network issue
- **Action**:
  - Retry request (automatic)
  - Wait and try again
  - Check server status

**User Message**: "Service temporarily unavailable. Please try again."

#### 503 Service Unavailable
- **Meaning**: Server temporarily unavailable
- **Common Causes**:
  - Server maintenance
  - Server overload
  - Deployment in progress
- **Action**:
  - Retry request (automatic)
  - Display maintenance message
  - Check server status page

**User Message**: "Service is temporarily unavailable. Please try again in a few minutes."

#### 504 Gateway Timeout
- **Meaning**: Server didn't respond in time
- **Common Causes**:
  - Long-running operation
  - Database query timeout
  - Network latency
- **Action**:
  - Retry request (automatic)
  - Increase timeout
  - Check network connection

**User Message**: "Request timed out. Please try again."

---

## Network Error Codes

### Connection Timeout
- **Meaning**: Failed to establish connection within timeout period
- **Common Causes**:
  - No internet connection
  - Server unreachable
  - Firewall blocking
  - DNS resolution failure
- **Action**:
  - Check network connection
  - Verify server URL
  - Queue operation for later
  - Display offline indicator

**User Message**: "Connection timeout. Please check your internet connection."

### Send Timeout
- **Meaning**: Failed to send request within timeout period
- **Common Causes**:
  - Slow upload speed
  - Large file upload
  - Network congestion
- **Action**:
  - Retry with smaller payload
  - Compress files before upload
  - Check network speed

**User Message**: "Upload timed out. Please try again."

### Receive Timeout
- **Meaning**: Failed to receive response within timeout period
- **Common Causes**:
  - Slow download speed
  - Large response data
  - Server processing delay
- **Action**:
  - Retry request
  - Implement pagination
  - Check network speed

**User Message**: "Response timed out. Please try again."

### No Internet Connection
- **Meaning**: Device is offline
- **Common Causes**:
  - WiFi disconnected
  - Mobile data disabled
  - Airplane mode enabled
  - Network unavailable
- **Action**:
  - Queue operation for later
  - Display offline indicator
  - Show cached data
  - Prompt user to check connection

**User Message**: "No internet connection. Your changes will be synced when you're back online."

### Bad Certificate
- **Meaning**: SSL/TLS certificate validation failed
- **Common Causes**:
  - Expired certificate
  - Self-signed certificate
  - Certificate mismatch
  - Man-in-the-middle attack
- **Action**:
  - Refuse connection
  - Display security warning
  - Contact server administrator
  - Never bypass certificate validation in production

**User Message**: "Security certificate error. Connection refused for your safety."

---

## Application Error Codes

### Cache Corruption
- **Meaning**: Cached data is corrupted or invalid
- **Action**:
  - Clear corrupted cache
  - Fetch fresh data from API
  - Log error for debugging

### Queue Processing Failure
- **Meaning**: Failed to process offline queue item
- **Action**:
  - Retry with exponential backoff
  - Keep item in queue
  - Display sync status to user

### File Upload Failure
- **Meaning**: Failed to upload file
- **Action**:
  - Retry up to 3 times
  - Compress file if too large
  - Display error to user

---

## Error Handling Best Practices

### 1. Specific Exception Handling

```dart
try {
  final response = await apiClient.post('/expenses', body: data);
} on ValidationException catch (e) {
  // Handle validation errors
  showValidationErrors(e.getValidationErrors());
} on UnauthorizedException catch (e) {
  // Handle auth errors
  redirectToLogin();
} on RateLimitException catch (e) {
  // Handle rate limiting
  await Future.delayed(e.getRetryAfterDuration() ?? Duration(seconds: 60));
} on NoInternetException catch (e) {
  // Handle offline
  queueOperation(data);
  showOfflineMessage();
} on ApiException catch (e) {
  // Handle generic API errors
  showError(e.getUserFriendlyMessage());
} catch (e) {
  // Handle unexpected errors
  showError('An unexpected error occurred');
  logError(e);
}
```

### 2. User-Friendly Messages

Always use `getUserFriendlyMessage()` for displaying errors to users:

```dart
try {
  await apiClient.get('/expenses');
} on ApiException catch (e) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: Text(e.getUserFriendlyMessage()),
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

### 3. Automatic Retry

The API client automatically retries transient errors:

- Network timeouts
- Server errors (500-504)
- Connection errors

**Retry Strategy:**
- Max retries: 3
- Exponential backoff: 1s, 2s, 4s
- Non-retryable: 4xx errors (except 408)

### 4. Offline Queue

Queue operations when offline:

```dart
try {
  await apiClient.post('/expenses', body: data);
} on NoInternetException catch (e) {
  // Queue for later
  await queueManager.enqueue(QueueItem(
    operation: QueueOperation.create,
    resourceType: 'expense',
    data: data,
  ));
  
  showMessage('Saved offline. Will sync when online.');
}
```

### 5. Logging

Log errors for debugging (debug mode only):

```dart
try {
  await apiClient.get('/expenses');
} on ApiException catch (e) {
  ApiLogger.logError(e, stackTrace: e.stackTrace);
  showError(e.getUserFriendlyMessage());
}
```

---

## Testing Error Scenarios

### Unit Tests

```dart
test('should handle 401 unauthorized error', () async {
  // Arrange
  when(() => mockApiClient.get(any()))
      .thenThrow(UnauthorizedException());

  // Act & Assert
  expect(
    () => expenseRepository.getExpenses(),
    throwsA(isA<UnauthorizedException>()),
  );
});

test('should handle validation errors', () async {
  // Arrange
  when(() => mockApiClient.post(any(), body: any(named: 'body')))
      .thenThrow(ValidationException(
        errors: {
          'email': ['The email field is required.'],
        },
      ));

  // Act & Assert
  expect(
    () => authService.register(name: 'John', email: '', password: 'pass'),
    throwsA(isA<ValidationException>()),
  );
});
```

---

## Quick Reference

| Code | Error | Action |
|------|-------|--------|
| 400 | Bad Request | Validate input |
| 401 | Unauthorized | Redirect to login |
| 403 | Forbidden | Hide feature |
| 404 | Not Found | Show not found message |
| 422 | Validation Error | Show field errors |
| 429 | Rate Limited | Wait and retry |
| 500 | Server Error | Retry automatically |
| 502 | Bad Gateway | Retry automatically |
| 503 | Service Unavailable | Retry automatically |
| 504 | Gateway Timeout | Retry automatically |
| - | Connection Timeout | Check network |
| - | No Internet | Queue operation |
| - | Bad Certificate | Refuse connection |

---

## Support

For additional help with error handling:

1. Check API documentation
2. Review error logs
3. Test with mock data
4. Contact backend team
5. Submit bug report with error details
