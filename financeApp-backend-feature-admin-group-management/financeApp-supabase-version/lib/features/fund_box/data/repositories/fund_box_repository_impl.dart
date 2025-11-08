import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fund_box.dart';
import '../../domain/repositories/fund_box_repository.dart';
import '../datasources/fund_box_local_datasource.dart';

/// Implementation of FundBoxRepository
/// Handles data operations and error conversion
class FundBoxRepositoryImpl implements FundBoxRepository {
  final FundBoxLocalDataSource localDataSource;

  FundBoxRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, FundBox>> getFundBoxByUser(int userId) async {
    try {
      final fundBox = await localDataSource.getFundBoxByUser(userId);
      return Right(fundBox);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FundBox>> updateFundBalance({
    required int userId,
    required double newBalance,
  }) async {
    try {
      final fundBox = await localDataSource.updateFundBalance(
        userId: userId,
        newBalance: newBalance,
      );
      return Right(fundBox);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FundBox>> initializeFundBox(int userId) async {
    try {
      final fundBox = await localDataSource.initializeFundBox(userId);
      return Right(fundBox);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
