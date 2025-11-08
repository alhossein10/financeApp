import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fund_box.dart';
import '../repositories/fund_box_repository.dart';

/// Use case for retrieving a user's fund box
/// Encapsulates the business logic for getting fund box data
class GetFundBoxUseCase {
  final FundBoxRepository repository;

  GetFundBoxUseCase(this.repository);

  /// Execute the use case to get fund box for a user
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// Returns Either a Failure or the FundBox entity
  Future<Either<Failure, FundBox>> call(int userId, {String? currency}) async {
    // Validate user ID
    if (userId <= 0) {
      return Left(ValidationFailure('Invalid user ID'));
    }

    return await repository.getFundBoxByUser(userId, currency: currency);
  }
}
