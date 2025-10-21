import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/incoming.dart';
import '../../domain/repositories/incoming_repository.dart';
import '../datasources/incoming_local_datasource.dart';
import '../models/incoming_model.dart';

class IncomingRepositoryImpl implements IncomingRepository {
  final IncomingLocalDataSource localDataSource;

  IncomingRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Incoming>> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    try {
      final incoming = await localDataSource.createIncoming(
        userId: userId,
        description: description,
        amountUsd: amountUsd,
        transactionDate: transactionDate,
      );
      return Right(incoming);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Incoming>>> getIncomingByUser(int userId) async {
    try {
      final incomingList = await localDataSource.getIncomingByUser(userId);
      return Right(incomingList);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateIncoming(Incoming incoming) async {
    try {
      // Convert entity to model
      final incomingModel = IncomingModel.fromEntity(incoming);
      await localDataSource.updateIncoming(incomingModel);
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncoming(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      await localDataSource.deleteIncoming(id, userId, refund: refund);
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
