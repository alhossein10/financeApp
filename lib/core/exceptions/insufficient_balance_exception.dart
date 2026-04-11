/// Exception thrown when a user attempts an operation with insufficient balance
/// Used by BalanceVerificationService to prevent operations that would result in negative balances
class InsufficientBalanceException implements Exception {
  /// The currency that has insufficient balance (USD, SYP, or TRY)
  final String currency;
  
  /// The amount required for the operation
  final double required;
  
  /// The amount currently available
  final double available;
  
  /// Optional additional context about the operation
  final String? context;

  const InsufficientBalanceException({
    required this.currency,
    required this.required,
    required this.available,
    this.context,
  });

  /// Human-readable error message
  String get message {
    final contextStr = context != null ? ' ($context)' : '';
    return 'Insufficient $currency balance$contextStr. Required: ${required.toStringAsFixed(2)}, Available: ${available.toStringAsFixed(2)}';
  }

  @override
  String toString() => 'InsufficientBalanceException: $message';
}
