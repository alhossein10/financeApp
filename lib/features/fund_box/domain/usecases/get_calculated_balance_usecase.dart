import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fund_box.dart';
import '../repositories/fund_box_repository.dart';

/// Use case for retrieving calculated balance from transactions
/// Returns real-time balance calculated from all transactions
/// Available to all authenticated users (SuperAdmin, Admin, and Regular Users)
class GetCalculatedBalanceUseCase {
  final FundBoxRepository repository;

  GetCalculatedBalanceUseCase(this.repository);

  /// Execute the use case to get calculated balance
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// Returns Either a Failure or the FundBox entity with calculated balance
  Future<Either<Failure, FundBox>> call({String? currency}) async {
    return await repository.getCalculatedBalance(currency: currency);
  }
}

