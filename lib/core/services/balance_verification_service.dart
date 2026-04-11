import '../../features/fund_box/data/datasources/fund_box_api_datasource.dart';
import '../exceptions/insufficient_balance_exception.dart';

/// Service for verifying user balances before financial operations
/// Provides client-side balance checks to prevent operations that would result in negative balances
/// 
/// This service integrates with the FundBox API to retrieve current balances
/// and verify that sufficient funds are available before operations like:
/// - Creating expenses
/// - Creating transfers
/// - Creating currency exchanges
/// 
/// Requirements: 21.1, 21.2, 21.3, 21.4, 21.5
class BalanceVerificationService {
  final FundBoxApiDataSource _fundBoxApiDataSource;

  BalanceVerificationService({
    required FundBoxApiDataSource fundBoxApiDataSource,
  }) : _fundBoxApiDataSource = fundBoxApiDataSource;

  /// Verify that sufficient balance exists for an operation
  /// 
  /// [currency] - The currency to check (USD, SYP, or TRY)
  /// [amount] - The amount required for the operation
  /// [userId] - Optional user ID for admin/superadmin checking other users' balances
  /// [context] - Optional context about the operation (e.g., "expense creation", "transfer")
  /// 
  /// Returns true if sufficient balance exists
  /// Throws [InsufficientBalanceException] if balance is insufficient
  /// Throws [ApiException] if API call fails
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await balanceVerificationService.verifyBalance(
  ///     currency: 'USD',
  ///     amount: 100.0,
  ///     context: 'expense creation',
  ///   );
  ///   // Proceed with operation
  /// } on InsufficientBalanceException catch (e) {
  ///   // Show error to user
  ///   print(e.message);
  /// }
  /// ```
  Future<bool> verifyBalance({
    required String currency,
    required double amount,
    int? userId,
    String? context,
  }) async {
    // Validate currency
    final validCurrencies = ['USD', 'SYP', 'TRY'];
    if (!validCurrencies.contains(currency.toUpperCase())) {
      throw ArgumentError('Invalid currency: $currency. Must be one of: ${validCurrencies.join(", ")}');
    }

    // Validate amount
    if (amount < 0) {
      throw ArgumentError('Amount must be non-negative: $amount');
    }

    // Get current balances
    final balances = await getCurrentBalances(userId: userId);
    
    // Get the balance for the specified currency
    final currentBalance = balances[currency.toUpperCase()] ?? 0.0;

    // Check if sufficient balance exists
    if (currentBalance < amount) {
      throw InsufficientBalanceException(
        currency: currency.toUpperCase(),
        required: amount,
        available: currentBalance,
        context: context,
      );
    }

    return true;
  }

  /// Get current balances for all currencies
  /// 
  /// [userId] - Optional user ID for admin/superadmin checking other users' balances
  /// 
  /// Returns a map with currency codes as keys (USD, SYP, TRY) and balances as values
  /// 
  /// Example:
  /// ```dart
  /// final balances = await balanceVerificationService.getCurrentBalances();
  /// print('USD: ${balances['USD']}');
  /// print('SYP: ${balances['SYP']}');
  /// print('TRY: ${balances['TRY']}');
  /// ```
  Future<Map<String, double>> getCurrentBalances({int? userId}) async {
    try {
      // Fetch fund box data from API
      final fundBoxDto = userId != null
          ? await _fundBoxApiDataSource.getFundBoxByUserId(userId)
          : await _fundBoxApiDataSource.getFundBox();

      // Return balances as a map
      return {
        'USD': fundBoxDto.balanceUsd ?? 0.0,
        'SYP': fundBoxDto.balanceSyp ?? 0.0,
        'TRY': fundBoxDto.balanceTry ?? 0.0,
      };
    } catch (e) {
      // Re-throw API exceptions as-is
      rethrow;
    }
  }

  /// Verify balance for a specific currency using calculated balance
  /// This uses real-time calculation from transactions instead of stored balance
  /// 
  /// [currency] - The currency to check (USD, SYP, or TRY)
  /// [amount] - The amount required for the operation
  /// [context] - Optional context about the operation
  /// 
  /// Returns true if sufficient balance exists
  /// Throws [InsufficientBalanceException] if balance is insufficient
  Future<bool> verifyCalculatedBalance({
    required String currency,
    required double amount,
    String? context,
  }) async {
    // Validate currency
    final validCurrencies = ['USD', 'SYP', 'TRY'];
    if (!validCurrencies.contains(currency.toUpperCase())) {
      throw ArgumentError('Invalid currency: $currency. Must be one of: ${validCurrencies.join(", ")}');
    }

    // Validate amount
    if (amount < 0) {
      throw ArgumentError('Amount must be non-negative: $amount');
    }

    // Get calculated balances
    final balances = await getCalculatedBalances();
    
    // Get the balance for the specified currency
    final currentBalance = balances[currency.toUpperCase()] ?? 0.0;

    // Check if sufficient balance exists
    if (currentBalance < amount) {
      throw InsufficientBalanceException(
        currency: currency.toUpperCase(),
        required: amount,
        available: currentBalance,
        context: context,
      );
    }

    return true;
  }

  /// Get calculated balances for all currencies
  /// Uses real-time calculation from transactions instead of stored balance
  /// 
  /// Returns a map with currency codes as keys (USD, SYP, TRY) and balances as values
  Future<Map<String, double>> getCalculatedBalances() async {
    try {
      // Fetch calculated balance from API
      final fundBoxDto = await _fundBoxApiDataSource.getCalculatedBalance();

      // Return balances as a map
      return {
        'USD': fundBoxDto.balanceUsd ?? 0.0,
        'SYP': fundBoxDto.balanceSyp ?? 0.0,
        'TRY': fundBoxDto.balanceTry ?? 0.0,
      };
    } catch (e) {
      // Re-throw API exceptions as-is
      rethrow;
    }
  }

  /// Verify multiple currency amounts at once
  /// Useful for operations that affect multiple currencies
  /// 
  /// [amounts] - Map of currency codes to amounts to verify
  /// [userId] - Optional user ID for admin/superadmin checking other users' balances
  /// [context] - Optional context about the operation
  /// 
  /// Returns true if all balances are sufficient
  /// Throws [InsufficientBalanceException] for the first insufficient balance found
  /// 
  /// Example:
  /// ```dart
  /// await balanceVerificationService.verifyMultipleBalances(
  ///   amounts: {
  ///     'USD': 50.0,
  ///     'SYP': 100000.0,
  ///   },
  ///   context: 'multi-currency operation',
  /// );
  /// ```
  Future<bool> verifyMultipleBalances({
    required Map<String, double> amounts,
    int? userId,
    String? context,
  }) async {
    // Get current balances once
    final balances = await getCurrentBalances(userId: userId);

    // Check each currency
    for (final entry in amounts.entries) {
      final currency = entry.key.toUpperCase();
      final requiredAmount = entry.value;
      final currentBalance = balances[currency] ?? 0.0;

      if (currentBalance < requiredAmount) {
        throw InsufficientBalanceException(
          currency: currency,
          required: requiredAmount,
          available: currentBalance,
          context: context,
        );
      }
    }

    return true;
  }
}
