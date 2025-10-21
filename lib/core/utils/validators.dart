/// Utility class for validation functions
class Validators {
  Validators._(); // Private constructor to prevent instantiation

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    // Email regex pattern
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Checks if email format is valid (returns boolean)
  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }

  /// Validates password strength
  /// Returns null if valid, error message if invalid
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Checks if password meets strength requirements (returns boolean)
  static bool isValidPassword(String password) {
    return validatePassword(password) == null;
  }

  /// Checks if password is strong (alias for isValidPassword)
  static bool isStrongPassword(String password) {
    return isValidPassword(password);
  }

  /// Validates password confirmation
  /// Returns null if valid, error message if invalid
  static String? validatePasswordConfirmation(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates username
  /// Returns null if valid, error message if invalid
  /// Requirements:
  /// - Minimum 3 characters
  /// - Maximum 30 characters
  /// - Only alphanumeric characters, underscores, and hyphens
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.length > 30) {
      return 'Username must not exceed 30 characters';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    return null;
  }

  /// Checks if username is valid (returns boolean)
  static bool isValidUsername(String username) {
    return validateUsername(username) == null;
  }

  /// Validates amount (for financial transactions)
  /// Returns null if valid, error message if invalid
  static String? validateAmount(double? amount, {double minAmount = 0.01}) {
    if (amount == null) {
      return 'Amount is required';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount < minAmount) {
      return 'Amount must be at least $minAmount';
    }

    return null;
  }

  /// Validates that a string is not empty
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length
  /// Returns null if valid, error message if invalid
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    return null;
  }

  /// Validates maximum length
  /// Returns null if valid, error message if invalid
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validates that a value is within a range
  /// Returns null if valid, error message if invalid
  static String? validateRange(double? value, double min, double max, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value < min || value > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validates phone number format (basic validation)
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'Phone number is required';
    }

    // Remove common formatting characters
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits and optional + at the start
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(cleanedNumber)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }
}
