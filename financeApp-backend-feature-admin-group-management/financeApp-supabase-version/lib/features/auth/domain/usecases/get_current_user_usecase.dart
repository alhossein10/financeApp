import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the currently authenticated user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Execute get current user
  /// Returns the authenticated user or failure if not authenticated
  Future<Either<Failure, User>> call() async {
    return await repository.getCurrentUser();
  }
}
