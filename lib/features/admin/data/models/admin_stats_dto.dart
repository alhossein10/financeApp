/// Data Transfer Object for admin dashboard statistics
/// Maps between API JSON and domain entities
/// Matches Laravel API spec: /admin/dashboard/stats
class AdminStatsDto {
  final int totalUsers;
  final int totalExpenses;
  final int totalIncome;
  final int totalTransfers;
  final double totalAmountExpenses;
  final double totalAmountIncome;
  final double fundBoxBalance;

  const AdminStatsDto({
    required this.totalUsers,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalTransfers,
    required this.totalAmountExpenses,
    required this.totalAmountIncome,
    required this.fundBoxBalance,
  });

  /// Create AdminStatsDto from JSON response
  factory AdminStatsDto.fromJson(Map<String, dynamic> json) {
    return AdminStatsDto(
      totalUsers: json['total_users'] as int? ?? 0,
      totalExpenses: json['total_expenses'] as int? ?? 0,
      totalIncome: json['total_income'] as int? ?? 0,
      totalTransfers: json['total_transfers'] as int? ?? 0,
      totalAmountExpenses: (json['total_amount_expenses'] as num?)?.toDouble() ?? 0.0,
      totalAmountIncome: (json['total_amount_income'] as num?)?.toDouble() ?? 0.0,
      fundBoxBalance: (json['fund_box_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert AdminStatsDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_expenses': totalExpenses,
      'total_income': totalIncome,
      'total_transfers': totalTransfers,
      'total_amount_expenses': totalAmountExpenses,
      'total_amount_income': totalAmountIncome,
      'fund_box_balance': fundBoxBalance,
    };
  }

  @override
  String toString() {
    return 'AdminStatsDto(totalUsers: $totalUsers, totalExpenses: $totalExpenses, '
        'totalIncome: $totalIncome, totalTransfers: $totalTransfers, '
        'fundBoxBalance: $fundBoxBalance)';
  }
}
