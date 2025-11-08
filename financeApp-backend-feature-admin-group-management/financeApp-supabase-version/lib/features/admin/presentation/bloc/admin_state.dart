import 'package:equatable/equatable.dart';
import '../../../../features/expenses/domain/entities/expense.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoaded extends AdminState {
  final int totalUsers;
  final int totalExpenses;
  final int pendingSync;
  final double totalAmount;
  final List<Expense> recentExpenses;
  final Map<String, int> userActivityMap;

  const AdminLoaded({
    required this.totalUsers,
    required this.totalExpenses,
    required this.pendingSync,
    required this.totalAmount,
    required this.recentExpenses,
    required this.userActivityMap,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        totalExpenses,
        pendingSync,
        totalAmount,
        recentExpenses,
        userActivityMap,
      ];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
