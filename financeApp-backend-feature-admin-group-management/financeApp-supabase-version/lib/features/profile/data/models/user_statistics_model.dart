import '../../domain/entities/user_statistics.dart';

/// User statistics model for data layer
class UserStatisticsModel extends UserStatistics {
  const UserStatisticsModel({
    required super.totalExpenses,
    required super.totalTransfers,
    required super.totalTransactions,
    required super.accountAgeDays,
    super.lastActivity,
  });

  /// Create UserStatisticsModel from calculation results
  factory UserStatisticsModel.fromCalculation({
    required double totalExpenses,
    required double totalTransfers,
    required int totalTransactions,
    required DateTime userCreatedAt,
    DateTime? lastActivity,
  }) {
    final now = DateTime.now();
    final accountAgeDays = now.difference(userCreatedAt).inDays;

    return UserStatisticsModel(
      totalExpenses: totalExpenses,
      totalTransfers: totalTransfers,
      totalTransactions: totalTransactions,
      accountAgeDays: accountAgeDays,
      lastActivity: lastActivity,
    );
  }
}