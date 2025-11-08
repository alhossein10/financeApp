/// API Configuration for Laravel Backend Integration
/// 
/// This class manages API configuration for different environments
/// (development, staging, production) and provides constants for
/// timeouts, retry settings, and API versioning.
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// API Base URLs for different environments
  static const String _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String _stagingBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://staging-api.example.com',
  );

  static const String _productionBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  /// Current environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Get base URL based on current environment
  static String get baseUrl {
    switch (environment) {
      case 'production':
        return _productionBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      case 'development':
      default:
        return _devBaseUrl;
    }
  }

  /// API Version
  static const String apiVersion = 'v1';

  /// Full API base path (includes version)
  static String get apiBasePath => '/api/$apiVersion';

  /// Full API URL
  static String get apiUrl => '$baseUrl$apiBasePath';

  // Timeout Configuration
  /// Connection timeout duration
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry Configuration
  /// Maximum number of retry attempts for failed requests
  static const int maxRetries = 3;

  /// Initial delay before first retry
  static const Duration initialRetryDelay = Duration(seconds: 2);

  /// Maximum delay between retries
  static const Duration maxRetryDelay = Duration(seconds: 30);

  /// Exponential backoff multiplier
  static const double retryDelayMultiplier = 2.0;

  // Request Configuration
  /// Maximum file upload size (10MB)
  static const int maxFileUploadSize = 10 * 1024 * 1024;

  /// Default pagination page size
  static const int defaultPageSize = 15;

  /// Maximum batch sync size
  static const int maxBatchSize = 50;

  // Cache Configuration
  /// Default cache TTL (Time To Live)
  static const Duration defaultCacheTtl = Duration(hours: 1);

  /// Cache size limit (50MB)
  static const int maxCacheSize = 50 * 1024 * 1024;

  // Debug Configuration
  /// Enable debug logging
  static const bool enableDebugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: false,
  );

  /// Enable request/response logging
  static bool get enableRequestLogging => 
      enableDebugLogging && environment == 'development';

  // API Endpoints
  /// Authentication endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';

  /// Profile endpoints
  static const String profile = '/profile';
  static const String profilePassword = '/profile/password';

  /// Expense endpoints
  static const String expenses = '/expenses';
  static String expenseById(int id) => '/expenses/$id';
  static String expenseInvoice(int id) => '/expenses/$id/invoice';

  /// Transfer endpoints
  static const String transfers = '/transfers';
  static String transferById(int id) => '/transfers/$id';
  static String transferExchange(int id) => '/transfers/$id/exchange';

  /// Incoming endpoints
  static const String incoming = '/incoming';
  static String incomingById(int id) => '/incoming/$id';

  /// Fund box endpoints
  static const String fundBox = '/fund-box';

  /// Admin endpoints
  static const String adminDashboardStats = '/admin/dashboard/stats';
  static const String adminDashboardUsers = '/admin/dashboard/users';
  static const String adminDashboardExpenses = '/admin/dashboard/expenses';
  static const String adminDashboardAnalytics = '/admin/dashboard/analytics';
  static const String auditLogs = '/audit-logs';
  static String auditLogById(int id) => '/audit-logs/$id';

  /// Export endpoints
  static const String exportExpensesPdf = '/export/expenses/pdf';
  static const String exportExpensesExcel = '/export/expenses/excel';
  static const String exportSystemWide = '/export/system-wide';
  static String exportStatus(String id) => '/export/$id/status';
  static String exportDownload(String id) => '/export/$id/download';

  /// Sync endpoints
  static const String syncBatch = '/sync/batch';
  static const String syncResolve = '/sync/resolve';

  // HTTP Headers
  /// Content-Type header for JSON
  static const String contentTypeJson = 'application/json';

  /// Content-Type header for multipart form data
  static const String contentTypeMultipart = 'multipart/form-data';

  /// Accept header
  static const String acceptJson = 'application/json';

  /// Authorization header prefix
  static const String authorizationPrefix = 'Bearer';

  // Validation
  /// Validate if API configuration is valid
  static bool isValid() {
    try {
      // Check if base URL is not empty
      if (baseUrl.isEmpty) return false;

      // Check if base URL is a valid URL
      final uri = Uri.parse(baseUrl);
      if (!uri.hasScheme || !uri.hasAuthority) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'baseUrl': baseUrl,
      'apiUrl': apiUrl,
      'apiVersion': apiVersion,
      'connectTimeout': connectTimeout.inSeconds,
      'maxRetries': maxRetries,
      'enableDebugLogging': enableDebugLogging,
      'enableRequestLogging': enableRequestLogging,
    };
  }
}
