import 'package:dio/dio.dart';
import '../services/token_manager.dart';
import '../config/api_config.dart';
import 'api_exception.dart';

/// Bearer Token Interceptor for automatic token injection and refresh
/// 
/// This interceptor:
/// - Automatically adds "Bearer {token}" to Authorization header for protected endpoints
/// - Detects public endpoints that don't require authentication
/// - Handles 401 errors with automatic token refresh
/// - Queues requests during token refresh to prevent race conditions
/// - Redirects to login on refresh failure
class BearerTokenInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final Dio _dio;
  
  // Callback for handling logout/redirect to login
  final Future<void> Function()? onTokenRefreshFailed;
  
  // Request queue for handling concurrent requests during token refresh
  final List<_QueuedRequest> _requestQueue = [];
  bool _isRefreshing = false;

  BearerTokenInterceptor({
    required TokenManager tokenManager,
    required Dio dio,
    this.onTokenRefreshFailed,
  })  : _tokenManager = tokenManager,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Check if endpoint is public (doesn't require authentication)
      if (_isPublicEndpoint(options.path)) {
        print('[BearerTokenInterceptor] 🌐 Public endpoint detected: ${options.path}');
        print('[BearerTokenInterceptor] ✅ Skipping token injection');
        return handler.next(options);
      }

      // Get current token from TokenManager
      final token = await _tokenManager.getToken();

      if (token == null || token.isEmpty) {
        print('[BearerTokenInterceptor] ⚠️ No token available for protected endpoint: ${options.path}');
        // Let the request proceed - server will return 401 if auth is required
        return handler.next(options);
      }

      // Add Bearer token to Authorization header
      final authHeader = 'Bearer $token';
      options.headers['Authorization'] = authHeader;

      final tokenPreview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
      print('[BearerTokenInterceptor] 🔑 Bearer token added: $tokenPreview');
      print('[BearerTokenInterceptor] 📤 Request: ${options.method} ${options.path}');

      handler.next(options);
    } catch (e, stackTrace) {
      print('[BearerTokenInterceptor] 🔴 Error in onRequest: $e');
      print('[BearerTokenInterceptor] Stack trace: $stackTrace');
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    print('[BearerTokenInterceptor] 🔴 401 Unauthorized detected');
    print('[BearerTokenInterceptor] 🔄 Attempting token refresh...');

    // Check if this is a public endpoint (shouldn't happen, but safety check)
    if (_isPublicEndpoint(err.requestOptions.path)) {
      print('[BearerTokenInterceptor] ⚠️ 401 on public endpoint: ${err.requestOptions.path}');
      return handler.next(err);
    }

    // Check if this is the refresh endpoint itself (prevent infinite loop)
    if (_isRefreshEndpoint(err.requestOptions.path)) {
      print('[BearerTokenInterceptor] 🔴 Token refresh failed - clearing tokens');
      await _handleRefreshFailure();
      return handler.next(err);
    }

    // If already refreshing, queue this request
    if (_isRefreshing) {
      print('[BearerTokenInterceptor] ⏳ Token refresh in progress, queueing request...');
      final queuedRequest = _QueuedRequest(
        requestOptions: err.requestOptions,
        handler: handler,
      );
      _requestQueue.add(queuedRequest);
      return;
    }

    // Start token refresh
    _isRefreshing = true;

    try {
      // Attempt to refresh token
      final refreshed = await _refreshToken();

      if (refreshed) {
        print('[BearerTokenInterceptor] ✅ Token refreshed successfully');

        // Retry the original request with new token
        final response = await _retryRequest(err.requestOptions);
        handler.resolve(response);

        // Process queued requests
        await _processQueue();
      } else {
        print('[BearerTokenInterceptor] 🔴 Token refresh failed');
        await _handleRefreshFailure();
        
        // Reject all queued requests
        _rejectQueue(err);
        
        handler.next(err);
      }
    } catch (e, stackTrace) {
      print('[BearerTokenInterceptor] 🔴 Error during token refresh: $e');
      print('[BearerTokenInterceptor] Stack trace: $stackTrace');
      
      await _handleRefreshFailure();
      _rejectQueue(err);
      
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Check if the endpoint is public (doesn't require authentication)
  bool _isPublicEndpoint(String path) {
    // Normalize path by removing leading/trailing slashes and query params
    final normalizedPath = path.split('?').first.trim().toLowerCase();

    // List of public endpoints that don't require Bearer token
    final publicEndpoints = [
      '/organizations',
      '/auth/register',
      '/auth/login',
      '/auth/logout',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];

    // Check if path matches any public endpoint
    for (final endpoint in publicEndpoints) {
      if (normalizedPath == endpoint || 
          normalizedPath.endsWith(endpoint) ||
          normalizedPath.contains(endpoint)) {
        return true;
      }
    }

    // Special case: /organizations/{id}/departments
    if (normalizedPath.contains('/organizations/') && 
        normalizedPath.contains('/departments')) {
      return true;
    }

    return false;
  }

  /// Check if the endpoint is the token refresh endpoint
  bool _isRefreshEndpoint(String path) {
    final normalizedPath = path.split('?').first.trim().toLowerCase();
    return normalizedPath.endsWith('/auth/refresh');
  }

  /// Attempt to refresh the authentication token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> _refreshToken() async {
    try {
      print('[BearerTokenInterceptor] 🔄 Calling refresh endpoint...');

      // Get current token for refresh request
      final currentToken = await _tokenManager.getToken();
      if (currentToken == null) {
        print('[BearerTokenInterceptor] 🔴 No token available for refresh');
        return false;
      }

      // Make refresh request with current Bearer token
      final response = await _dio.post(
        '${ApiConfig.apiBasePath}/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $currentToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract new token from response
        final data = response.data;
        
        if (data is Map<String, dynamic>) {
          final newToken = data['token'] as String?;
          final tokenType = data['token_type'] as String? ?? 'Bearer';
          
          if (newToken != null && newToken.isNotEmpty) {
            // Parse expiration if available
            DateTime? expiresAt;
            if (data['expires_at'] != null) {
              try {
                expiresAt = DateTime.parse(data['expires_at']);
              } catch (e) {
                print('[BearerTokenInterceptor] ⚠️ Could not parse expires_at: $e');
              }
            }

            // Save new token
            await _tokenManager.saveToken(
              token: newToken,
              tokenType: tokenType,
              expiresAt: expiresAt,
            );

            print('[BearerTokenInterceptor] ✅ New token saved');
            return true;
          }
        }

        print('[BearerTokenInterceptor] 🔴 Invalid refresh response format');
        return false;
      }

      print('[BearerTokenInterceptor] 🔴 Refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e, stackTrace) {
      print('[BearerTokenInterceptor] 🔴 Token refresh error: $e');
      print('[BearerTokenInterceptor] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Retry a request with the new token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    print('[BearerTokenInterceptor] 🔄 Retrying request: ${requestOptions.method} ${requestOptions.path}');

    // Get new token
    final newToken = await _tokenManager.getToken();
    if (newToken != null) {
      // Update Authorization header with new token
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
    }

    // Retry the request
    return await _dio.fetch(requestOptions);
  }

  /// Process all queued requests after successful token refresh
  Future<void> _processQueue() async {
    if (_requestQueue.isEmpty) {
      return;
    }

    print('[BearerTokenInterceptor] 📋 Processing ${_requestQueue.length} queued requests...');

    final queue = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in queue) {
      try {
        final response = await _retryRequest(queuedRequest.requestOptions);
        queuedRequest.handler.resolve(response);
        print('[BearerTokenInterceptor] ✅ Queued request completed: ${queuedRequest.requestOptions.path}');
      } catch (e) {
        print('[BearerTokenInterceptor] 🔴 Queued request failed: ${queuedRequest.requestOptions.path}');
        queuedRequest.handler.reject(
          DioException(
            requestOptions: queuedRequest.requestOptions,
            error: e,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }

    print('[BearerTokenInterceptor] ✅ All queued requests processed');
  }

  /// Reject all queued requests with the original error
  void _rejectQueue(DioException originalError) {
    if (_requestQueue.isEmpty) {
      return;
    }

    print('[BearerTokenInterceptor] 🔴 Rejecting ${_requestQueue.length} queued requests...');

    final queue = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queuedRequest in queue) {
      queuedRequest.handler.reject(
        DioException(
          requestOptions: queuedRequest.requestOptions,
          error: originalError.error,
          response: originalError.response,
          type: originalError.type,
        ),
      );
    }
  }

  /// Handle token refresh failure
  /// Clears tokens and triggers logout callback
  Future<void> _handleRefreshFailure() async {
    print('[BearerTokenInterceptor] 🔴 Handling refresh failure...');

    // Clear stored tokens
    await _tokenManager.clearTokens();

    // Trigger logout callback if provided
    if (onTokenRefreshFailed != null) {
      try {
        await onTokenRefreshFailed!();
        print('[BearerTokenInterceptor] ✅ Logout callback executed');
      } catch (e) {
        print('[BearerTokenInterceptor] 🔴 Error in logout callback: $e');
      }
    }
  }
}

/// Internal class to hold queued requests during token refresh
class _QueuedRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _QueuedRequest({
    required this.requestOptions,
    required this.handler,
  });
}
