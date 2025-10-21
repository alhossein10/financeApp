// Export SyncStatus enum from expense entity
export '../../features/expenses/domain/entities/expense.dart' show SyncStatus;

/// Strategy for handling sync retry logic with exponential backoff
class SyncRetryStrategy {
  /// Maximum number of retry attempts before giving up
  static const int maxRetries = 3;
  
  /// Base delay for the first retry attempt
  static const Duration baseDelay = Duration(seconds: 5);
  
  /// Calculate the delay before the next retry attempt
  /// Uses exponential backoff: 5s, 10s, 20s
  /// 
  /// Parameters:
  /// - [retryCount]: Current retry attempt number (0-based)
  /// 
  /// Returns:
  /// - Duration to wait before next retry
  static Duration getRetryDelay(int retryCount) {
    // Exponential backoff: baseDelay * 2^retryCount
    return baseDelay * (1 << retryCount);
  }
  
  /// Check if another retry attempt should be made
  /// 
  /// Parameters:
  /// - [retryCount]: Current retry attempt number (0-based)
  /// 
  /// Returns:
  /// - true if retry should be attempted
  /// - false if max retries reached
  static bool shouldRetry(int retryCount) {
    return retryCount < maxRetries;
  }
}
