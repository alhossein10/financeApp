/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ==================== Authentication Constants ====================
  
  /// Minimum password length
  static const int minPasswordLength = 8;
  
  /// Maximum password length
  static const int maxPasswordLength = 128;
  
  /// Minimum username length
  static const int minUsernameLength = 3;
  
  /// Maximum username length
  static const int maxUsernameLength = 30;
  
  /// Session duration in days
  static const int sessionDurationDays = 7;
  
  /// Inactivity timeout in minutes
  static const int inactivityTimeoutMinutes = 30;
  
  /// Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;
  
  /// Account lockout duration in minutes
  static const int lockoutDurationMinutes = 15;
  
  /// Password reset token expiration in hours
  static const int passwordResetTokenExpirationHours = 24;
  
  /// BCrypt salt rounds for password hashing
  static const int bcryptSaltRounds = 12;

  // ==================== Database Constants ====================
  
  /// Database name
  static const String databaseName = 'finance_app.db';
  
  /// Current database version
  static const int databaseVersion = 5;
  
  /// Default user ID for migration (existing data)
  static const int defaultUserId = 1;

  // ==================== Storage Keys ====================
  
  /// Secure storage key for auth token
  static const String authTokenKey = 'auth_token';
  
  /// Secure storage key for user ID
  static const String userIdKey = 'user_id';
  
  /// Secure storage key for remember me preference
  static const String rememberMeKey = 'remember_me';
  
  /// Shared preferences key for onboarding completion
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  /// Shared preferences key for last activity timestamp
  static const String lastActivityKey = 'last_activity';
  
  /// Shared preferences key for language preference
  static const String languageKey = 'language';
  
  /// Shared preferences key for theme preference
  static const String themeKey = 'theme';

  // ==================== Validation Constants ====================
  
  /// Minimum transaction amount
  static const double minTransactionAmount = 0.01;
  
  /// Maximum transaction amount
  static const double maxTransactionAmount = 999999999.99;
  
  /// Email regex pattern
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
  /// Username regex pattern (alphanumeric, underscore, hyphen)
  static const String usernamePattern = r'^[a-zA-Z0-9_-]+$';

  // ==================== Error Messages ====================
  
  /// Generic error message
  static const String genericErrorMessage = 'An error occurred. Please try again.';
  
  /// Network error message
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  
  /// Database error message
  static const String databaseErrorMessage = 'Database error. Please try again.';
  
  /// Authentication error message
  static const String authenticationErrorMessage = 'Authentication failed. Please try again.';
  
  /// Session expired message
  static const String sessionExpiredMessage = 'Your session has expired. Please log in again.';
  
  /// Unauthorized access message
  static const String unauthorizedAccessMessage = 'You are not authorized to perform this action.';
  
  /// Insufficient funds message
  static const String insufficientFundsMessage = 'Insufficient funds for this transaction.';

  // ==================== Date/Time Formats ====================
  
  /// Standard date format (yyyy-MM-dd)
  static const String standardDateFormat = 'yyyy-MM-dd';
  
  /// Display date format (dd/MM/yyyy)
  static const String displayDateFormat = 'dd/MM/yyyy';
  
  /// Date time format (yyyy-MM-dd HH:mm:ss)
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  /// Display date time format (dd/MM/yyyy HH:mm)
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // ==================== UI Constants ====================
  
  /// Default padding
  static const double defaultPadding = 16.0;
  
  /// Small padding
  static const double smallPadding = 8.0;
  
  /// Large padding
  static const double largePadding = 24.0;
  
  /// Border radius
  static const double borderRadius = 8.0;
  
  /// Button height
  static const double buttonHeight = 48.0;
  
  /// Text field height
  static const double textFieldHeight = 56.0;
  
  /// App bar height
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation bar height
  static const double bottomNavBarHeight = 60.0;

  // ==================== Animation Durations ====================
  
  /// Short animation duration in milliseconds
  static const int shortAnimationDuration = 200;
  
  /// Medium animation duration in milliseconds
  static const int mediumAnimationDuration = 300;
  
  /// Long animation duration in milliseconds
  static const int longAnimationDuration = 500;

  // ==================== Pagination Constants ====================
  
  /// Default page size for paginated lists
  static const int defaultPageSize = 20;
  
  /// Maximum page size
  static const int maxPageSize = 100;

  // ==================== File/Image Constants ====================
  
  /// Maximum profile picture size in bytes (5 MB)
  static const int maxProfilePictureSizeBytes = 5 * 1024 * 1024;
  
  /// Maximum invoice image size in bytes (10 MB)
  static const int maxInvoiceImageSizeBytes = 10 * 1024 * 1024;
  
  /// Supported image formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // ==================== Export Constants ====================
  
  /// PDF export file name prefix
  static const String pdfExportPrefix = 'finance_export_';
  
  /// Excel export file name prefix
  static const String excelExportPrefix = 'finance_export_';
  
  /// Date format for export file names
  static const String exportDateFormat = 'yyyyMMdd_HHmmss';

  // ==================== Currency Constants ====================
  
  /// Default currency symbol (USD)
  static const String defaultCurrencySymbol = '\$';
  
  /// Secondary currency symbol (SYP)
  static const String secondaryCurrencySymbol = 'ل.س';
  
  /// Currency decimal places
  static const int currencyDecimalPlaces = 2;

  // ==================== Logging Constants ====================
  
  /// Enable debug logging
  static const bool enableDebugLogging = true;
  
  /// Enable error logging
  static const bool enableErrorLogging = true;
  
  /// Log file name
  static const String logFileName = 'app_log.txt';
  
  /// Maximum log file size in bytes (10 MB)
  static const int maxLogFileSizeBytes = 10 * 1024 * 1024;
}
