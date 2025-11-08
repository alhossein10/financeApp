import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/exchange.dart';
import '../repositories/exchange_repository.dart';

class GetAllExchangesUseCase {
  final ExchangeRepository repository;

  GetAllExchangesUseCase(this.repository);

  /// [currency] optional filter: 'all', 'SYP', or 'TRY'
  Future<Either<Failure, List<Exchange>>> call({String? currency}) async {
    return await repository.getAllExchanges(currency: currency);
  }
}
