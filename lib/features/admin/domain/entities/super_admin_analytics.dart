import 'package:equatable/equatable.dart';

/// SuperAdmin Analytics domain entity
/// Contains aggregated analytics for all admin groups under the SuperAdmin
class SuperAdminAnalytics extends Equatable {
  final String period; // '15days', 'month', or 'all'
  final DateTime? startDate;
  final DateTime endDate;
  final List<AdminGroupAnalytics> adminGroups;

  const SuperAdminAnalytics({
    required this.period,
    this.startDate,
    required this.endDate,
    required this.adminGroups,
  });

  @override
  List<Object?> get props => [period, startDate, endDate, adminGroups];
}

/// Analytics for a single admin group
class AdminGroupAnalytics extends Equatable {
  final AdminGroupInfo adminGroup;
  final TransferStats transfers;
  final ExpenseStats expenses;

  const AdminGroupAnalytics({
    required this.adminGroup,
    required this.transfers,
    required this.expenses,
  });

  @override
  List<Object?> get props => [adminGroup, transfers, expenses];
}

/// Admin group information
class AdminGroupInfo extends Equatable {
  final int id;
  final String name;
  final String code;
  final AdminUser adminUser;

  const AdminGroupInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.adminUser,
  });

  @override
  List<Object?> get props => [id, name, code, adminUser];
}

/// Admin user information
class AdminUser extends Equatable {
  final int id;
  final String name;
  final String email;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}

/// Transfer statistics
class TransferStats extends Equatable {
  final int count;
  final double totalUsd;

  const TransferStats({
    required this.count,
    required this.totalUsd,
  });

  @override
  List<Object?> get props => [count, totalUsd];
}

/// Expense statistics
class ExpenseStats extends Equatable {
  final int count;
  final double totalUsd;
  final double totalSyp;
  final double totalTry;

  const ExpenseStats({
    required this.count,
    required this.totalUsd,
    required this.totalSyp,
    required this.totalTry,
  });

  @override
  List<Object?> get props => [count, totalUsd, totalSyp, totalTry];
}

