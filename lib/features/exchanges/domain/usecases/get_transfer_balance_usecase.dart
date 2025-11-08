import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';
import '../repositories/exchange_repository.dart';

class GetTransferBalanceUseCase {
  final ExchangeRepository repository;

  GetTransferBalanceUseCase(this.repository);

  Future<Either<Failure, TransferBalance>> call(int transferId) async {
    return await repository.getTransferBalance(transferId);
  }
}
