import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';
import '../repositories/exchange_repository.dart';

class GetExchangesByTransferUseCase {
  final ExchangeRepository repository;

  GetExchangesByTransferUseCase(this.repository);

  Future<Either<Failure, List<Exchange>>> call(int transferId) async {
    return await repository.getExchangesByTransfer(transferId);
  }
}
