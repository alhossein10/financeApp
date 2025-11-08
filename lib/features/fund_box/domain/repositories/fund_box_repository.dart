import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fund_box.dart';

/// Repository interface for fund box operations
/// Defines the contract for data access operations
/// Supports multi-currency balances (USD, SYP, TRY)
abstract class FundBoxRepository {
  /// Get the fund box for a specific user
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// Returns the user's fund box or a failure
  Future<Either<Failure, FundBox>> getFundBoxByUser(int userId, {String? currency});

  /// Get calculated balance from transactions (real-time calculation)
  /// Returns balance calculated from all transactions, not from stored database value
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// Returns the calculated fund box balance or a failure
  Future<Either<Failure, FundBox>> getCalculatedBalance({String? currency});

  /// Update the fund box balance for a specific user
  /// Supports multi-currency updates
  /// Returns the updated fund box or a failure
  Future<Either<Failure, FundBox>> updateFundBalance({
    required int userId,
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
    // Legacy parameter for backward compatibility
    double? newBalance,
  });

  /// Initialize a fund box for a new user
  /// Returns the created fund box or a failure
  Future<Either<Failure, FundBox>> initializeFundBox(int userId);
}
