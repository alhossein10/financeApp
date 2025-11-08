import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';

/// Exchange Repository interface
abstract class ExchangeRepository {
  /// Create a new exchange (balance-based, optional transferId)
  Future<Either<Failure, Exchange>> createExchange({
    int? transferId, // Optional - for balance-based exchanges
    required String targetCurrency, // 'SYP' or 'TRY'
    required double amountUsd,
    required double exchangeRate,
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
