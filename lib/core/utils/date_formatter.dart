/// Utility class for formatting dates for API communication
/// Ensures consistent date formatting across the application
/// 
/// This class provides methods to convert between DateTime objects and
/// API-compatible string formats (YYYY-MM-DD for dates, ISO 8601 for timestamps).
/// All methods handle timezone conversions properly to ensure data consistency.
class DateFormatter {
  DateFormatter._(); // Private constructor to prevent instantiation

  /// Format date for API requests (YYYY-MM-DD)
  /// 
  /// Converts a DateTime object to YYYY-MM-DD format required by the Laravel API.
  /// The time component is ignored, only the date is formatted.
  /// 
  /// Example: DateTime(2024, 10, 23, 14, 30) -> "2024-10-23"
  /// 
  /// Throws [ArgumentError] if date is null
  static String toApiDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Format timestamp for API requests (ISO 8601)
  /// 
  /// Converts a DateTime object to ISO 8601 format with UTC timezone.
  /// This format includes date, time, and timezone information.
  /// 
  /// Example: DateTime(2024, 10, 23, 10, 30) -> "2024-10-23T10:30:00.000Z"
  /// 
  /// Note: The input DateTime is converted to UTC before formatting
  static String toApiTimestamp(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Parse API date response (YYYY-MM-DD)
  /// 
  /// Converts a date string in YYYY-MM-DD format to a DateTime object.
  /// The resulting DateTime will have time set to 00:00:00 in local timezone.
  /// 
  /// Example: "2024-10-23" -> DateTime(2024, 10, 23, 0, 0, 0)
  /// 
  /// Throws [FormatException] if the string is not in valid format
  static DateTime fromApiDate(String dateStr) {
    if (dateStr.isEmpty) {
      throw FormatException('Date string cannot be empty');
    }
    
    // Validate format first
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(dateStr)) {
      throw FormatException('Invalid date format: $dateStr. Expected YYYY-MM-DD');
    }
    
    try {
      // Parse the date string
      final parts = dateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      // Validate month and day ranges
      if (month < 1 || month > 12) {
        throw FormatException('Invalid month: $month. Must be between 1 and 12');
      }
      
      if (day < 1 || day > 31) {
        throw FormatException('Invalid day: $day. Must be between 1 and 31');
      }
      
      // Create DateTime and verify it matches input (catches invalid dates like Feb 30)
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        throw FormatException('Invalid date: $dateStr');
      }
      
      return parsed;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Invalid date format: $dateStr. Expected YYYY-MM-DD');
    }
  }

  /// Parse API timestamp response (ISO 8601)
  /// 
  /// Converts an ISO 8601 timestamp string to a DateTime object in local timezone.
  /// Handles various ISO 8601 formats including with/without milliseconds.
  /// 
  /// Example: "2024-10-23T10:30:00.000Z" -> DateTime(2024, 10, 23, 10, 30) (local time)
  /// 
  /// Throws [FormatException] if the string is not in valid ISO 8601 format
  static DateTime fromApiTimestamp(String timestampStr) {
    if (timestampStr.isEmpty) {
      throw FormatException('Timestamp string cannot be empty');
    }
    
    try {
      return DateTime.parse(timestampStr).toLocal();
    } catch (e) {
      throw FormatException('Invalid timestamp format: $timestampStr. Expected ISO 8601');
    }
  }

  /// Check if a string is in valid YYYY-MM-DD format
  /// 
  /// Returns true if the string matches YYYY-MM-DD format and represents a valid date.
  /// Returns false otherwise.
  /// 
  /// Example: 
  /// - "2024-10-23" -> true
  /// - "2024-13-01" -> false (invalid month)
  /// - "23-10-2024" -> false (wrong format)
  static bool isValidApiDate(String dateStr) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(dateStr)) return false;
    
    try {
      final parts = dateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      // Validate month and day ranges
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      
      // Create DateTime and verify it matches input
      final parsed = DateTime(year, month, day);
      return parsed.year == year && parsed.month == month && parsed.day == day;
    } catch (e) {
      return false;
    }
  }

  /// Check if a string is in valid ISO 8601 timestamp format
  /// 
  /// Returns true if the string is a valid ISO 8601 timestamp.
  /// Returns false otherwise.
  /// 
  /// Example:
  /// - "2024-10-23T10:30:00.000Z" -> true
  /// - "2024-10-23T10:30:00Z" -> true
  /// - "2024-10-23" -> true (date-only ISO 8601)
  /// - "invalid" -> false
  static bool isValidApiTimestamp(String timestampStr) {
    try {
      DateTime.parse(timestampStr);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convert a nullable date string to DateTime
  /// 
  /// Returns null if the input is null or empty.
  /// Otherwise parses the date string using fromApiDate.
  /// 
  /// Useful for optional date fields in DTOs.
  static DateTime? fromApiDateNullable(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return fromApiDate(dateStr);
  }

  /// Convert a nullable timestamp string to DateTime
  /// 
  /// Returns null if the input is null or empty.
  /// Otherwise parses the timestamp string using fromApiTimestamp.
  /// 
  /// Useful for optional timestamp fields in DTOs.
  static DateTime? fromApiTimestampNullable(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return null;
    return fromApiTimestamp(timestampStr);
  }

  /// Convert a nullable DateTime to API date string
  /// 
  /// Returns null if the input is null.
  /// Otherwise formats the date using toApiDate.
  /// 
  /// Useful for optional date fields in API requests.
  static String? toApiDateNullable(DateTime? date) {
    if (date == null) return null;
    return toApiDate(date);
  }

  /// Convert a nullable DateTime to API timestamp string
  /// 
  /// Returns null if the input is null.
  /// Otherwise formats the timestamp using toApiTimestamp.
  /// 
  /// Useful for optional timestamp fields in API requests.
  static String? toApiTimestampNullable(DateTime? dateTime) {
    if (dateTime == null) return null;
    return toApiTimestamp(dateTime);
  }

  /// Get current date in API format (YYYY-MM-DD)
  /// 
  /// Returns today's date in YYYY-MM-DD format.
  /// Useful for default date values.
  static String todayApiDate() {
    return toApiDate(DateTime.now());
  }

  /// Get current timestamp in API format (ISO 8601)
  /// 
  /// Returns current date and time in ISO 8601 format.
  /// Useful for default timestamp values.
  static String nowApiTimestamp() {
    return toApiTimestamp(DateTime.now());
  }

  /// Format date range for API query parameters
  /// 
  /// Returns a map with 'date_from' and 'date_to' keys formatted as YYYY-MM-DD.
  /// Useful for filtering API requests by date range.
  /// 
  /// Example:
  /// ```dart
  /// final range = DateFormatter.formatDateRange(
  ///   DateTime(2024, 10, 1),
  ///   DateTime(2024, 10, 31),
  /// );
  /// // Returns: {'date_from': '2024-10-01', 'date_to': '2024-10-31'}
  /// ```
  static Map<String, String> formatDateRange(DateTime from, DateTime to) {
    return {
      'date_from': toApiDate(from),
      'date_to': toApiDate(to),
    };
  }
}
