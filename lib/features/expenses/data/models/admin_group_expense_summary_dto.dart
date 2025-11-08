/// Data Transfer Object for Admin Group Expense Summary
/// Used for SuperAdmin to view aggregated expense data by admin group
class AdminGroupExpenseSummaryDto {
  final String adminGroupId;
  final String adminGroupName;
  final double totalAmount;
  final int expenseCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const AdminGroupExpenseSummaryDto({
    required this.adminGroupId,
    required this.adminGroupName,
    required this.totalAmount,
    required this.expenseCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  /// Create DTO from JSON response from Laravel API
  factory AdminGroupExpenseSummaryDto.fromJson(Map<String, dynamic> json) {
    return AdminGroupExpenseSummaryDto(
      adminGroupId: json['admin_group_id']?.toString() ?? '',
      adminGroupName: json['admin_group_name'] as String? ?? 'Unknown Group',
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      expenseCount: json['expense_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      approvedCount: json['approved_count'] as int? ?? 0,
      rejectedCount: json['rejected_count'] as int? ?? 0,
    );
  }

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'admin_group_id': adminGroupId,
      'admin_group_name': adminGroupName,
      'total_amount': totalAmount,
      'expense_count': expenseCount,
      'pending_count': pendingCount,
      'approved_count': approvedCount,
      'rejected_count': rejectedCount,
    };
  }

  /// Helper method to parse double values from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  AdminGroupExpenseSummaryDto copyWith({
    String? adminGroupId,
    String? adminGroupName,
    double? totalAmount,
    int? expenseCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
  }) {
    return AdminGroupExpenseSummaryDto(
      adminGroupId: adminGroupId ?? this.adminGroupId,
      adminGroupName: adminGroupName ?? this.adminGroupName,
      totalAmount: totalAmount ?? this.totalAmount,
      expenseCount: expenseCount ?? this.expenseCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}
