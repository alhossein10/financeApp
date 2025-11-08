import '../../../../core/utils/date_formatter.dart';
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

  /// Create UserStatisticsModel from API JSON response
  factory UserStatisticsModel.fromApiJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      totalTransfers: (json['total_transfers'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      accountAgeDays: json['account_age_days'] as int? ?? 0,
      lastActivity: DateFormatter.fromApiTimestampNullable(json['last_activity'] as String?),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'total_expenses': totalExpenses,
      'total_transfers': totalTransfers,
      'total_transactions': totalTransactions,
      'account_age_days': accountAgeDays,
      'last_activity': DateFormatter.toApiTimestampNullable(lastActivity),
    };
  }
}