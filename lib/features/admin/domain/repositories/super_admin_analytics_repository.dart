import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/super_admin_analytics.dart';

/// Repository interface for SuperAdmin Analytics
abstract class SuperAdminAnalyticsRepository {
  /// Get analytics for SuperAdmin
  /// [period] must be '15days', 'month', or 'all'
  Future<Either<Failure, SuperAdminAnalytics>> getAnalytics(String period);
}

