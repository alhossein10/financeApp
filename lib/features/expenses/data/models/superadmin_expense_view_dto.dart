import 'admin_group_expense_summary_dto.dart';

/// Data Transfer Object for SuperAdmin Expense View
/// Contains aggregated expense data across all admin groups
class SuperAdminExpenseViewDto {
  final List<AdminGroupExpenseSummaryDto> groupSummaries;
  final double grandTotal;
  final int totalExpenseCount;

  const SuperAdminExpenseViewDto({
    required this.groupSummaries,
    required this.grandTotal,
    required this.totalExpenseCount,
  });

  /// Create DTO from JSON response from Laravel API
  factory SuperAdminExpenseViewDto.fromJson(Map<String, dynamic> json) {
    final summariesList = json['group_summaries'] as List<dynamic>? ?? [];
    final summaries = summariesList
        .map((item) => AdminGroupExpenseSummaryDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return SuperAdminExpenseViewDto(
      groupSummaries: summaries,
      grandTotal: _parseDouble(json['grand_total']) ?? 0.0,
      totalExpenseCount: json['total_expense_count'] as int? ?? 0,
    );
  }

  /// Convert DTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'group_summaries': groupSummaries.map((s) => s.toJson()).toList(),
      'grand_total': grandTotal,
      'total_expense_count': totalExpenseCount,
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

  SuperAdminExpenseViewDto copyWith({
    List<AdminGroupExpenseSummaryDto>? groupSummaries,
    double? grandTotal,
    int? totalExpenseCount,
  }) {
    return SuperAdminExpenseViewDto(
      groupSummaries: groupSummaries ?? this.groupSummaries,
      grandTotal: grandTotal ?? this.grandTotal,
      totalExpenseCount: totalExpenseCount ?? this.totalExpenseCount,
    );
  }
}
