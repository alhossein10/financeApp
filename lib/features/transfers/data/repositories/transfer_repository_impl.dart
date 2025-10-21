import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_local_datasource.dart';
import '../models/transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferLocalDataSource localDataSource;

  TransferRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Transfer>> createTransfer({
    required int userId,
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    try {
      final transfer = await localDataSource.createTransfer(
        userId: userId,
        recipientName: recipientName,
        amountUsd: amountUsd,
        convertedAmountUsd: convertedAmountUsd,
        amountSypAtExchange: amountSypAtExchange,
        manualUsdToSypRate: manualUsdToSypRate,
        transactionDate: transactionDate,
      );
      return Right(transfer);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Transfer>>> getTransfersByUser(int userId) async {
    try {
      final transfers = await localDataSource.getTransfersByUser(userId);
      return Right(transfers);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransfer(Transfer transfer) async {
    try {
      final transferModel = TransferModel.fromEntity(transfer);
      await localDataSource.updateTransfer(transferModel);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransfer(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      await localDataSource.deleteTransfer(id, userId, refund: refund);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
