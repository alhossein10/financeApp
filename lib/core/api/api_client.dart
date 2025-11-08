import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/api_logger.dart';
import 'api_exception.dart';

/// Abstract API Client interface
abstract class ApiClient {
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  });

  Future<Response> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Options? options,
  });

  Future<Response> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Options? options,
  });

  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  });

  Future<Response> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String fileFieldName = 'file',
    ProgressCallback? onProgress,
    Options? options,
  });

  void setAuthToken(String? token);
  String? getAuthToken();
  void clearAuthToken();
}

/// Implementation of API Client using Dio
class DioApiClient implements ApiClient {
  late final Dio _dio;
  String? _authToken;

  DioApiClient({
    Dio? dio,
    String? baseUrl,
  }) {
    _dio = dio ?? Dio();
    _configureDio(baseUrl);
  }

  /// Configure Dio with base options and interceptors
  void _configureDio(String? baseUrl) {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.apiUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': ApiConfig.contentTypeJson,
        'Accept': ApiConfig.acceptJson,
      },
      validateStatus: (status) {
        // Accept all status codes to handle them manually
        return status != null && status < 500;
      },
    );

    // Add interceptors
    _dio.interceptors.clear();
    _dio.interceptors.add(_createRequestInterceptor());
    _dio.interceptors.add(_createResponseInterceptor());
    _dio.interceptors.add(_createErrorInterceptor());
  }

  /// Check if the given path is an authentication endpoint
  /// Authentication endpoints don't require a token, so we skip warnings for them
  bool _isAuthEndpoint(String path) {
    final authEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/auth/reset-password',
    ];
    
    // Normalize path by removing leading/trailing slashes and query params
    final normalizedPath = path.split('?').first.trim();
    
    return authEndpoints.any((endpoint) => normalizedPath == endpoint || normalizedPath.endsWith(endpoint));
  }

  /// Create request interceptor for token injection and logging
  Interceptor _createRequestInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Inject authentication token with Bearer prefix
        if (_authToken != null && _authToken!.isNotEmpty) {
          // Ensure Bearer prefix is included
          final authHeader = _authToken!.startsWith('Bearer ')
              ? _authToken!
              : '${ApiConfig.authorizationPrefix} $_authToken';
          
          options.headers['Authorization'] = authHeader;
          
          // Log token injection (only first 20 chars for security)
          final tokenPreview = _authToken!.length > 20 
              ? '${_authToken!.substring(0, 20)}...' 
              : _authToken!;
          print('[ApiClient] ✅ Token injected: $tokenPreview');
        } else {
          // Only log warning for non-authentication endpoints
          // Auth endpoints (login, register, etc.) are expected to work without tokens
          if (!_isAuthEndpoint(options.path)) {
            print('[ApiClient] ⚠️ No token available for request');
          }
        }

        print('[ApiClient] Request: ${options.method} ${options.uri}');
        
        // Always log Authorization header presence (for debugging)
        if (options.headers.containsKey('Authorization')) {
          final authHeader = options.headers['Authorization'] as String?;
          if (authHeader != null && authHeader.isNotEmpty) {
            final headerPreview = authHeader.length > 30 
                ? '${authHeader.substring(0, 30)}...' 
                : authHeader;
            print('[ApiClient] ✅ Authorization header present: $headerPreview');
          } else {
            print('[ApiClient] ⚠️ Authorization header is empty');
          }
        } else {
          print('[ApiClient] ⚠️ Authorization header missing');
        }
        
        if (ApiConfig.enableDebugLogging) {
          print('[ApiClient] Headers: ${options.headers}');
        }

        // Log request
        ApiLogger.logRequest(options);

        handler.next(options);
      },
    );
  }

  /// Create response interceptor for logging
  Interceptor _createResponseInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        // Log response
        ApiLogger.logResponse(response);

        handler.next(response);
      },
    );
  }

  /// Create error interceptor for retry logic and error handling
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Log error
        ApiLogger.logError(error, stackTrace: error.stackTrace);

        // Handle 401 Unauthorized - token expired or invalid
        if (error.response?.statusCode == 401) {
          print('🔴 [ApiClient] 401 Unauthorized - Token invalid or expired');
          
          // Clear the invalid token
          clearAuthToken();
          
          // Don't retry 401 errors - let the app handle re-authentication
          handler.next(error);
          return;
        }

        // Check if we should retry
        if (_shouldRetry(error)) {
          try {
            final response = await _retryRequest(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // If retry fails, continue with error handling
          }
        }

        handler.next(error);
      },
    );
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException error) {
    // Don't retry on client errors (4xx) except 408 (timeout)
    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;
      if (statusCode >= 400 && statusCode < 500 && statusCode != 408) {
        return false;
      }
    }

    // Retry on network errors, timeouts, and server errors
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null && 
         error.response!.statusCode! >= 500);
  }

  /// Retry request with exponential backoff
  Future<Response> _retryRequest(
    RequestOptions requestOptions, {
    int attemptNumber = 1,
  }) async {
    if (attemptNumber > ApiConfig.maxRetries) {
      throw DioException(
        requestOptions: requestOptions,
        error: 'Max retry attempts exceeded',
        type: DioExceptionType.unknown,
      );
    }

    // Calculate delay with exponential backoff
    final delay = _calculateRetryDelay(attemptNumber);

    // Log retry attempt
    ApiLogger.logRetry(requestOptions, attemptNumber, delay);

    // Wait before retrying
    await Future.delayed(delay);

    try {
      // Retry the request
      return await _dio.fetch(requestOptions);
    } on DioException catch (e) {
      // If retry fails and we haven't exceeded max retries, try again
      if (_shouldRetry(e) && attemptNumber < ApiConfig.maxRetries) {
        return await _retryRequest(
          requestOptions,
          attemptNumber: attemptNumber + 1,
        );
      }
      rethrow;
    }
  }

  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int attemptNumber) {
    final delayMs = ApiConfig.initialRetryDelay.inMilliseconds *
        (ApiConfig.retryDelayMultiplier * (attemptNumber - 1));

    final delay = Duration(milliseconds: delayMs.toInt());

    // Cap at max retry delay
    return delay > ApiConfig.maxRetryDelay 
        ? ApiConfig.maxRetryDelay 
        : delay;
  }

  @override
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Response> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        queryParameters: queryParams,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Response> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
        queryParameters: queryParams,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Response> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String fileFieldName = 'file',
    ProgressCallback? onProgress,
    Options? options,
  }) async {
    try {
      // Create form data
      final formData = FormData();

      // Add file
      formData.files.add(
        MapEntry(
          fileFieldName,
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );

      // Add additional fields
      if (fields != null) {
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });
      }

      // Merge options with multipart content type
      final uploadOptions = (options ?? Options()).copyWith(
        contentType: ApiConfig.contentTypeMultipart,
      );

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: uploadOptions,
        onSendProgress: onProgress,
      );

      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      print('[ApiClient] 🔑 Token set: ${token.substring(0, 20)}...');
    } else {
      print('[ApiClient] 🔑 Token cleared');
    }
    ApiLogger.logAuth('Token set');
  }

  @override
  String? getAuthToken() {
    return _authToken;
  }

  @override
  void clearAuthToken() {
    _authToken = null;
    ApiLogger.logAuth('Token cleared');
  }

  /// Download file with progress tracking
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
    Options? options,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        options: options,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}
