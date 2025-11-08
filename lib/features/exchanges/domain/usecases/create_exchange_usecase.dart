import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';
import '../repositories/exchange_repository.dart';

class CreateExchangeUseCase {
  final ExchangeRepository repository;

  CreateExchangeUseCase(this.repository);

  Future<Either<Failure, Exchange>> call({
    int? transferId, // Optional - for balance-based exchanges
    required String targetCurrency, // 'SYP' or 'TRY'
    required double amountUsd,
    required double exchangeRate,
    required DateTime exchangeDate,
    String? notes,
  }) async {
    return await repository.createExchange(
      transferId: transferId,
      targetCurrency: targetCurrency,
      amountUsd: amountUsd,
      exchangeRate: exchangeRate,
      exchangeDate: exchangeDate,
      notes: notes,
    );
  }
}
