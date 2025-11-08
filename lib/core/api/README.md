# API Module

## Overview

The API module provides a robust HTTP client infrastructure for communicating with the Laravel backend. It handles authentication, error handling, retry logic, and request/response logging.

## Components

### ApiClient

The `ApiClient` is the central HTTP client for all API communication.

**Features:**
- Base URL configuration
- Request/response interceptors
- Authentication token injection
- Automatic retry with exponential backoff
- Request timeout management
- File upload support

**Usage Example:**

```dart
// Initialize API client
final apiClient = DioApiClient(
  baseUrl: 'https://api.example.com',
);

// Set authentication token
apiClient.setAuthToken('your-token-here');

// Make GET request
final response = await apiClient.get(
  '/expenses',
  queryParams: {'page': 1, 'per_page': 15},
);

// Make POST request
final createResponse = await apiClient.post(
  '/expenses',
  body: {
    'description': 'Office supplies',
    'price_usd': 50.00,
    'expense_date': '2024-01-15',
  },
);

// Upload file
final uploadResponse = await apiClient.uploadFile(
  '/expenses/1/invoice',
  File('/path/to/invoice.jpg'),
  fields: {'description': 'Invoice for expense'},
  onProgress: (sent, total) {
    print('Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%');
  },
);
```

### ApiException

Structured exception handling for all API errors.

**Exception Types:**

| Exception | Status Code | Description |
|-----------|-------------|-------------|
| `BadRequestException` | 400 | Invalid request parameters |
| `UnauthorizedException` | 401 | Authentication required |
| `ForbiddenException` | 403 | Insufficient permissions |
| `NotFoundException` | 404 | Resource not found |
| `ValidationException` | 422 | Validation errors |
| `RateLimitException` | 429 | Too many requests |
| `ServerException` | 500-504 | Server errors |
| `ConnectionTimeoutException` | - | Connection timeout |
| `NoInternetException` | - | No network connection |

**Usage Example:**

```dart
try {
  final response = await apiClient.get('/expenses');
} on ValidationException catch (e) {
  // Handle validation errors
  final errors = e.getValidationErrors();
  for (final error in errors) {
    print(error);
  }
} on UnauthorizedException catch (e) {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
} on RateLimitException catch (e) {
  // Wait before retrying
  final retryAfter = e.getRetryAfterDuration();
  await Future.delayed(retryAfter ?? Duration(seconds: 60));
} on ApiException catch (e) {
  // Handle generic API error
  showErrorDialog(e.getUserFriendlyMessage());
}
```

### ApiConfig

Configuration constants for API communication.

**Configuration Options:**

```dart
class ApiConfig {
  // Base URL (configured per environment)
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const double retryDelayMultiplier = 2.0;
  static const Duration maxRetryDelay = Duration(seconds: 30);
  
  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';
  static const String acceptJson = 'application/json';
  static const String authorizationPrefix = 'Bearer';
}
```

### ApiLogger

Logging utility for debugging API requests and responses.

**Features:**
- Request logging (method, URL, headers, body)
- Response logging (status, data)
- Error logging with stack traces
- Retry attempt logging
- Sensitive data filtering (never logs tokens or passwords)

**Note:** Logging is only enabled in debug mode to avoid performance impact in production.

## Error Codes

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Check request parameters |
| 401 | Unauthorized | Token expired or invalid - redirect to login |
| 403 | Forbidden | User lacks permissions |
| 404 | Not Found | Resource doesn't exist |
| 422 | Validation Error | Fix validation errors and retry |
| 429 | Rate Limited | Wait and retry after specified duration |
| 500 | Server Error | Retry request or contact support |
| 502 | Bad Gateway | Server temporarily unavailable |
| 503 | Service Unavailable | Server maintenance or overload |
| 504 | Gateway Timeout | Server took too long to respond |

### Network Error Codes

| Error | Description | Action |
|-------|-------------|--------|
| Connection Timeout | Server didn't respond in time | Check network and retry |
| Send Timeout | Request took too long to send | Check network and retry |
| Receive Timeout | Response took too long | Check network and retry |
| No Internet | Device is offline | Show offline indicator and queue request |
| Bad Certificate | SSL/TLS error | Check server certificate |

## Retry Logic

The API client implements automatic retry with exponential backoff for transient errors.

**Retry Conditions:**
- Network timeouts (connection, send, receive)
- Server errors (500-504)
- Connection errors

**Retry Strategy:**
1. First retry: Wait 1 second
2. Second retry: Wait 2 seconds
3. Third retry: Wait 4 seconds
4. Max retries: 3 attempts

**Non-Retryable Errors:**
- Client errors (400-499) except 408 (timeout)
- Authentication errors (401)
- Validation errors (422)

## Authentication

The API client automatically injects authentication tokens into all requests.

**Token Injection:**
```
Authorization: Bearer {token}
```

**Token Management:**
1. Set token after login: `apiClient.setAuthToken(token)`
2. Token is automatically included in all requests
3. Clear token on logout: `apiClient.clearAuthToken()`

## File Uploads

The API client supports multipart file uploads with progress tracking.

**Upload Process:**
1. File is converted to `MultipartFile`
2. Additional form fields can be included
3. Progress callback provides upload status
4. Automatic retry on failure

**Best Practices:**
- Compress images before upload to reduce bandwidth
- Validate file size and type before upload
- Show progress indicator to user
- Handle upload cancellation

## Testing

### Unit Tests

```dart
// Mock API client for testing
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  
  setUp(() {
    mockApiClient = MockApiClient();
  });
  
  test('should make GET request with query parameters', () async {
    // Arrange
    when(() => mockApiClient.get(
      any(),
      queryParams: any(named: 'queryParams'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      data: {'data': []},
      statusCode: 200,
    ));
    
    // Act
    final response = await mockApiClient.get(
      '/expenses',
      queryParams: {'page': 1},
    );
    
    // Assert
    expect(response.statusCode, 200);
    verify(() => mockApiClient.get(
      '/expenses',
      queryParams: {'page': 1},
    )).called(1);
  });
}
```

## Best Practices

1. **Always handle exceptions**: Wrap API calls in try-catch blocks
2. **Use specific exception types**: Catch specific exceptions before generic ones
3. **Show user-friendly messages**: Use `getUserFriendlyMessage()` for error display
4. **Implement offline support**: Queue requests when network is unavailable
5. **Log errors**: Use ApiLogger for debugging (debug mode only)
6. **Validate inputs**: Check data before making API calls
7. **Use pagination**: Always paginate large lists
8. **Compress files**: Reduce file size before upload
9. **Handle rate limits**: Respect Retry-After headers
10. **Secure tokens**: Never log or expose authentication tokens

## Dependencies

- `dio`: ^5.0.0 - HTTP client
- `flutter_secure_storage`: ^9.0.0 - Secure token storage

## Related Modules

- [Authentication Service](../services/README.md#laravel-auth-service)
- [Token Manager](../services/README.md#token-manager)
- [Cache Service](../services/README.md#cache-service)
- [Queue Manager](../services/README.md#queue-manager)
