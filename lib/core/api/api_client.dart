import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/api_logger.dart';
import '../services/token_manager.dart';
import '../services/certificate_pinning_service.dart';
import 'api_exception.dart';
import 'bearer_token_interceptor.dart';

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
  final TokenManager? _tokenManager;
  final Future<void> Function()? _onTokenRefreshFailed;
  BearerTokenInterceptor? _bearerTokenInterceptor;

  DioApiClient({
    Dio? dio,
    String? baseUrl,
    TokenManager? tokenManager,
    Future<void> Function()? onTokenRefreshFailed,
    bool enableCertificatePinning = true,
    List<String>? allowedCertificateFingerprints,
  })  : _tokenManager = tokenManager,
        _onTokenRefreshFailed = onTokenRefreshFailed {
    _dio = dio ?? Dio();
    _configureDio(baseUrl);
    
    // Configure certificate pinning if enabled
    if (enableCertificatePinning) {
      _configureCertificatePinning(allowedCertificateFingerprints);
    }
  }

  /// Configure Dio with base options and interceptors
  void _configureDio(String? baseUrl) {
    final url = baseUrl ?? ApiConfig.apiUrl;
    
    // Validate HTTPS (except for localhost in debug mode)
    if (!_validateSecureUrl(url)) {
      throw ApiException(
        message: 'Insecure URL detected. All API calls must use HTTPS.',
        statusCode: 0,
      );
    }
    
    _dio.options = BaseOptions(
      baseUrl: url,
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

    // Add interceptors in correct order:
    // 1. Logging (request/response logging)
    // 2. Bearer Token (authentication)
    // 3. Error Handling (retry logic)
    _dio.interceptors.clear();
    
    // 1. Logging interceptor (first to log all requests)
    _dio.interceptors.add(_createRequestInterceptor());
    _dio.interceptors.add(_createResponseInterceptor());
    
    // 2. Bearer Token interceptor (adds authentication)
    if (_tokenManager != null) {
      _bearerTokenInterceptor = BearerTokenInterceptor(
        tokenManager: _tokenManager!,
        dio: _dio,
        onTokenRefreshFailed: _onTokenRefreshFailed,
      );
      _dio.interceptors.add(_bearerTokenInterceptor!);
      print('[ApiClient] ✅ BearerTokenInterceptor added');
    } else {
      print('[ApiClient] ⚠️ TokenManager not provided, Bearer token authentication disabled');
    }
    
    // 3. Error handling interceptor (last to handle all errors)
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

  /// Create request interceptor for logging
  /// Note: Token injection is now handled by BearerTokenInterceptor
  Interceptor _createRequestInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('[ApiClient] Request: ${options.method} ${options.uri}');
        
        // Log Authorization header presence (for debugging)
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
  /// Note: 401 errors are now handled by BearerTokenInterceptor
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Log error
        ApiLogger.logError(error, stackTrace: error.stackTrace);

        // Note: 401 Unauthorized is handled by BearerTokenInterceptor
        // which attempts token refresh before this interceptor runs

        // Check if we should retry (for network errors and 5xx errors)
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
  
  /// Validate that URL uses HTTPS
  bool _validateSecureUrl(String url) {
    // Allow localhost and local IPs in debug mode or development environment
    if (kDebugMode || ApiConfig.environment == 'development') {
      if (url.contains('localhost') || 
          url.contains('127.0.0.1') || 
          url.contains('10.0.2.2') ||  // Android emulator
          url.startsWith('http://192.168.') ||  // Local network
          url.startsWith('http://172.') ||  // Docker/local network
          url.startsWith('http://10.')) {  // Local network
        print('[ApiClient] ⚠️ Allowing insecure local URL in debug/development mode: $url');
        return true;
      }
    }
    
    // Require HTTPS for all other URLs
    if (!url.startsWith('https://')) {
      print('[ApiClient] 🔴 Insecure URL detected: $url');
      return false;
    }
    
    return true;
  }
  
  /// Configure certificate pinning
  void _configureCertificatePinning(List<String>? allowedFingerprints) {
    try {
      // In debug mode, allow self-signed certificates
      final allowSelfSigned = kDebugMode;
      
      CertificatePinningService.configureCertificatePinning(
        _dio,
        allowedSHA256Fingerprints: allowedFingerprints,
        allowSelfSigned: allowSelfSigned,
      );
      
      print('[ApiClient] 🔒 Certificate pinning configured');
    } catch (e) {
      print('[ApiClient] 🔴 Error configuring certificate pinning: $e');
    }
  }
}
