import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking authentication status
class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  /// Execute authentication status check
  /// Returns true if user is authenticated, false otherwise
  Future<Either<Failure, bool>> call() async {
    return await repository.isAuthenticated();
  }
}
