import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fund_box.dart';
import '../repositories/fund_box_repository.dart';

/// Parameters for updating fund balance
class UpdateFundBalanceParams {
  final int userId;
  final double newBalance;

  const UpdateFundBalanceParams({
    required this.userId,
    required this.newBalance,
  });
}

/// Use case for updating a user's fund box balance
/// Encapsulates the business logic for balance updates
class UpdateFundBalanceUseCase {
  final FundBoxRepository repository;

  UpdateFundBalanceUseCase(this.repository);

  /// Execute the use case to update fund balance
  /// Returns Either a Failure or the updated FundBox entity
  Future<Either<Failure, FundBox>> call(UpdateFundBalanceParams params) async {
    // Validate user ID
    if (params.userId <= 0) {
      return Left(ValidationFailure('Invalid user ID'));
    }

    // Validate balance (allow negative for overdraft scenarios if needed)
    // For now, we'll allow any balance value
    // Add business rules here if needed (e.g., minimum balance)

    return await repository.updateFundBalance(
      userId: params.userId,
      newBalance: params.newBalance,
    );
  }
}
