import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/super_admin_analytics.dart';
import '../../domain/repositories/super_admin_analytics_repository.dart';
import '../datasources/super_admin_analytics_api_datasource.dart';

class SuperAdminAnalyticsRepositoryImpl implements SuperAdminAnalyticsRepository {
  final SuperAdminAnalyticsApiDataSource apiDataSource;

  SuperAdminAnalyticsRepositoryImpl({required this.apiDataSource});

  @override
  Future<Either<Failure, SuperAdminAnalytics>> getAnalytics(String period) async {
    try {
      final dto = await apiDataSource.getAnalytics(period);
      return Right(dto.toEntity());
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return Left(AuthorizationFailure('Access denied. SuperAdmin privileges required.'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

