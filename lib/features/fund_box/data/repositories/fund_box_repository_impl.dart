import 'package:dartz/dartz.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fund_box.dart';
import '../../domain/repositories/fund_box_repository.dart';
import '../datasources/fund_box_api_datasource.dart';

/// Implementation of FundBoxRepository
/// Handles data operations and error conversion
/// Now uses Laravel API instead of SQLite
class FundBoxRepositoryImpl implements FundBoxRepository {
  final FundBoxApiDataSource apiDataSource;

  FundBoxRepositoryImpl({required this.apiDataSource});

  @override
  Future<Either<Failure, FundBox>> getFundBoxByUser(int userId, {String? currency}) async {
    try {
      print('[FundBoxRepository] Getting fund box for userId: $userId, currency: $currency');
      
      // If userId is provided and different from current user, use getFundBoxByUserId
      // Otherwise, use the standard getFundBox endpoint
      // Note: We need to get current user ID from auth context to compare
      // For now, we'll use getFundBoxByUserId if userId is provided (Admin/SuperAdmin use case)
      final fundBoxDto = await apiDataSource.getFundBoxByUserId(userId, currency: currency);
      print('[FundBoxRepository] Received DTO: id=${fundBoxDto.id}, USD=${fundBoxDto.balanceUsd}, SYP=${fundBoxDto.balanceSyp}, TRY=${fundBoxDto.balanceTry}');
      print('[FundBoxRepository] DTO lastUpdated: ${fundBoxDto.lastUpdated}');
      print('[FundBoxRepository] DTO lastCalculatedAt: ${fundBoxDto.lastCalculatedAt}');
      
      try {
        print('[FundBoxRepository] Converting DTO to entity...');
        final entity = fundBoxDto.toEntity();
        print('[FundBoxRepository] ✅ Converted to entity successfully: id=${entity.id}, userId=${entity.userId}, USD=${entity.balanceUsd}, SYP=${entity.balanceSyp}, TRY=${entity.balanceTry}');
        print('[FundBoxRepository] Entity updatedAt: ${entity.updatedAt}');
        print('[FundBoxRepository] Entity lastCalculatedAt: ${entity.lastCalculatedAt}');
        return Right(entity);
      } catch (e, stackTrace) {
        print('[FundBoxRepository] ❌ Error converting DTO to entity: $e');
        print('[FundBoxRepository] Error type: ${e.runtimeType}');
        print('[FundBoxRepository] Stack trace: $stackTrace');
        return Left(ServerFailure('Failed to convert fund box data: ${e.toString()}'));
      }
    } on ApiException catch (e) {
      print('[FundBoxRepository] ❌ ApiException: ${e.statusCode} - ${e.message}');
      if (e.statusCode == 403) {
        return Left(AuthorizationFailure('Access denied. Admin/SuperAdmin privileges required.'));
      } else if (e.statusCode == 404) {
        // If endpoint doesn't support user_id parameter, fall back to standard endpoint
        // This handles cases where backend hasn't implemented user_id parameter yet
        print('[FundBoxRepository] User-specific endpoint not found, trying standard endpoint...');
        try {
          final fallbackDto = await apiDataSource.getFundBox(currency: currency);
          final entity = fallbackDto.toEntity();
          return Right(entity);
        } catch (fallbackError) {
          print('[FundBoxRepository] Fallback also failed: $fallbackError');
          return Left(ServerFailure('User fund box not found'));
        }
      }
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      print('[FundBoxRepository] ❌ Unexpected error: $e');
      print('[FundBoxRepository] Error type: ${e.runtimeType}');
      print('[FundBoxRepository] Stack trace: $stackTrace');
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FundBox>> getCalculatedBalance({String? currency}) async {
    try {
      // Get calculated balance from the new endpoint
      // This returns real-time balance calculated from transactions
      final fundBoxDto = await apiDataSource.getCalculatedBalance(currency: currency);
      return Right(fundBoxDto.toEntity());
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return Left(AuthorizationFailure('Unauthenticated'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FundBox>> updateFundBalance({
    required int userId,
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
    double? newBalance, // Legacy parameter for backward compatibility
  }) async {
    try {
      // NOTE: The API updates the fund box for the authenticated user's admin group.
      // The userId parameter is ignored as the API uses the authenticated user's token.
      // Support legacy newBalance parameter for backward compatibility
      final fundBoxDto = await apiDataSource.updateFundBox(
        balanceUsd: balanceUsd ?? newBalance,
        balanceSyp: balanceSyp,
        balanceTry: balanceTry,
      );
      return Right(fundBoxDto.toEntity());
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return Left(AuthorizationFailure('Access denied. Admin privileges required.'));
      } else if (e.statusCode == 422) {
        return Left(ValidationFailure('Invalid balance value'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, FundBox>> initializeFundBox(int userId) async {
    // For API-based implementation, initialization is handled by the backend
    // Just fetch the fund box
    return getFundBoxByUser(userId);
  }
}
