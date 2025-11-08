import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/super_admin_analytics.dart';
import '../repositories/super_admin_analytics_repository.dart';

class GetSuperAdminAnalyticsUseCase {
  final SuperAdminAnalyticsRepository repository;

  GetSuperAdminAnalyticsUseCase(this.repository);

  /// [period] must be '15days', 'month', or 'all'
  Future<Either<Failure, SuperAdminAnalytics>> call(String period) async {
    // Validate period
    if (!['15days', 'month', 'all'].contains(period)) {
      return Left(ValidationFailure('Invalid period. Must be "15days", "month", or "all"'));
    }

    return await repository.getAnalytics(period);
  }
}

