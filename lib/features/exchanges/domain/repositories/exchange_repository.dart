import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';

/// Exchange Repository interface
abstract class ExchangeRepository {
  /// Create a new exchange (balance-based, optional transferId)
  /// 
  /// Either exchangeRate OR convertedAmount must be provided (not both required).
  /// Backend v3.1+ supports converted_amount as alternative to exchange_rate.
  Future<Either<Failure, Exchange>> createExchange({
    int? transferId, // Optional - for balance-based exchanges
    required String targetCurrency, // 'SYP' or 'TRY'
    required double amountUsd,
    double? exchangeRate, // Optional if convertedAmount is provided
    double? convertedAmount, // Optional if exchangeRate is provided (Backend v3.1+)
    required DateTime exchangeDate,
    String? notes,
  });

  /// Get all exchanges for the authenticated user
  /// [currency] filter: 'all', 'SYP', or 'TRY' (optional)
  Future<Either<Failure, List<Exchange>>> getAllExchanges({String? currency});

  /// Get exchange by ID
  Future<Either<Failure, Exchange>> getExchangeById(int id);

  /// Get all exchanges for a specific transfer
  Future<Either<Failure, List<Exchange>>> getExchangesByTransfer(int transferId);

  /// Get transfer balance
  Future<Either<Failure, TransferBalance>> getTransferBalance(int transferId);
}
