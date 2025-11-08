import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/incoming.dart';

abstract class IncomingRepository {
  Future<Either<Failure, Incoming>> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  });

  Future<Either<Failure, List<Incoming>>> getIncomingByUser(int userId);

  Future<Either<Failure, void>> updateIncoming(Incoming incoming);

  Future<Either<Failure, void>> deleteIncoming(int id, int userId, {bool refund = false});
}
