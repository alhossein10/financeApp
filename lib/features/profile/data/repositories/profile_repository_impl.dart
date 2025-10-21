import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/user_statistics.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

/// Implementation of profile repository
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;

  ProfileRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserStatistics>> getUserStatistics(int userId) async {
    try {
      final statistics = await localDataSource.getUserStatistics(userId);
      return Right(statistics);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get user statistics: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    required int userId,
    String? username,
    String? email,
  }) async {
    try {
      final updatedUser = await localDataSource.updateUserProfile(
        userId: userId,
        username: username,
        email: email,
      );
      return Right(updatedUser);
    } on DatabaseException catch (e) {
      if (e.message.contains('already exists')) {
        return Left(ValidationFailure(e.message));
      }
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Failed to update user profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfilePicture({
    required int userId,
    required String imagePath,
  }) async {
    try {
      final updatedUser = await localDataSource.updateProfilePicture(
        userId: userId,
        imagePath: imagePath,
      );
      return Right(updatedUser);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Failed to update profile picture: ${e.toString()}'));
    }
  }
}