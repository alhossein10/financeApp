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
    double? exchangeRate, // Optional if convertedAmount is provided
    double? convertedAmount, // Optional if exchangeRate is provided (Backend v3.1+)
    required DateTime exchangeDate,
    String? notes,
  }) async {
    return await repository.createExchange(
      transferId: transferId,
      targetCurrency: targetCurrency,
      amountUsd: amountUsd,
      exchangeRate: exchangeRate,
      convertedAmount: convertedAmount,
      exchangeDate: exchangeDate,
      notes: notes,
    );
  }
}
