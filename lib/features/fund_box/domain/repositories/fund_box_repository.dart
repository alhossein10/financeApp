import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fund_box.dart';

/// Repository interface for fund box operations
/// Defines the contract for data access operations
abstract class FundBoxRepository {
  /// Get the fund box for a specific user
  /// Returns the user's fund box or a failure
  Future<Either<Failure, FundBox>> getFundBoxByUser(int userId);

  /// Update the fund box balance for a specific user
  /// Returns the updated fund box or a failure
  Future<Either<Failure, FundBox>> updateFundBalance({
    required int userId,
    required double newBalance,
  });

  /// Initialize a fund box for a new user
  /// Returns the created fund box or a failure
  Future<Either<Failure, FundBox>> initializeFundBox(int userId);
}
