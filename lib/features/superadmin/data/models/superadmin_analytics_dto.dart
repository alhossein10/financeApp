/// Data Transfer Object for SuperAdmin Analytics
/// Contains aggregated statistics for all admin groups
class SuperAdminAnalyticsDto {
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<AdminGroupAnalyticsData> adminGroups;
  final DateTime generatedAt;

  const SuperAdminAnalyticsDto({
    required this.period,
    this.startDate,
    this.endDate,
    required this.adminGroups,
    required this.generatedAt,
  });

  /// Create from JSON response
  factory SuperAdminAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return SuperAdminAnalyticsDto(
      period: json['period'] as String? ?? 'all',
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      adminGroups: (json['admin_groups'] as List<dynamic>?)
              ?.map((e) => AdminGroupAnalyticsData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'admin_groups': adminGroups.map((e) => e.toJson()).toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SuperAdminAnalyticsDto(period: $period, adminGroups: ${adminGroups.length}, generatedAt: $generatedAt)';
  }
}

/// Analytics data for a single admin group
class AdminGroupAnalyticsData {
  final int adminGroupId;
  final String adminGroupName;
  final String adminGroupCode;
  final int adminUserId;
  final String adminUserName;
  final String adminUserEmail;
  final int transfersCount;
  final double transfersTotalUsd;
  final double transfersTotalSyp;
  final double transfersTotalTry;
  final int expensesCount;
  final double expensesTotalUsd;
  final double expensesTotalSyp;
  final double expensesTotalTry;
  final double totalBalanceUsd;
  final double totalBalanceSyp;
  final double totalBalanceTry;

  const AdminGroupAnalyticsData({
    required this.adminGroupId,
    required this.adminGroupName,
    required this.adminGroupCode,
    required this.adminUserId,
    required this.adminUserName,
    required this.adminUserEmail,
    required this.transfersCount,
    required this.transfersTotalUsd,
    required this.transfersTotalSyp,
    required this.transfersTotalTry,
    required this.expensesCount,
    required this.expensesTotalUsd,
    required this.expensesTotalSyp,
    required this.expensesTotalTry,
    required this.totalBalanceUsd,
    required this.totalBalanceSyp,
    required this.totalBalanceTry,
  });

  /// Create from JSON response
  factory AdminGroupAnalyticsData.fromJson(Map<String, dynamic> json) {
    final adminGroup = json['admin_group'] as Map<String, dynamic>? ?? {};
    final adminUser = adminGroup['admin_user'] as Map<String, dynamic>? ?? {};
    final transfers = json['transfers'] as Map<String, dynamic>? ?? {};
    final expenses = json['expenses'] as Map<String, dynamic>? ?? {};
    
    return AdminGroupAnalyticsData(
      adminGroupId: adminGroup['id'] as int? ?? 0,
      adminGroupName: adminGroup['name'] as String? ?? '',
      adminGroupCode: adminGroup['code'] as String? ?? '',
      adminUserId: adminUser['id'] as int? ?? 0,
      adminUserName: adminUser['name'] as String? ?? '',
      adminUserEmail: adminUser['email'] as String? ?? '',
      transfersCount: transfers['count'] as int? ?? 0,
      transfersTotalUsd: (transfers['total_usd'] as num?)?.toDouble() ?? 0.0,
      transfersTotalSyp: (transfers['total_syp'] as num?)?.toDouble() ?? 0.0,
      transfersTotalTry: (transfers['total_try'] as num?)?.toDouble() ?? 0.0,
      expensesCount: expenses['count'] as int? ?? 0,
      expensesTotalUsd: (expenses['total_usd'] as num?)?.toDouble() ?? 0.0,
      expensesTotalSyp: (expenses['total_syp'] as num?)?.toDouble() ?? 0.0,
      expensesTotalTry: (expenses['total_try'] as num?)?.toDouble() ?? 0.0,
      // Calculate total balance (transfers - expenses)
      totalBalanceUsd: ((transfers['total_usd'] as num?)?.toDouble() ?? 0.0) - 
                       ((expenses['total_usd'] as num?)?.toDouble() ?? 0.0),
      totalBalanceSyp: ((transfers['total_syp'] as num?)?.toDouble() ?? 0.0) - 
                       ((expenses['total_syp'] as num?)?.toDouble() ?? 0.0),
      totalBalanceTry: ((transfers['total_try'] as num?)?.toDouble() ?? 0.0) - 
                       ((expenses['total_try'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'admin_group': {
        'id': adminGroupId,
        'name': adminGroupName,
        'code': adminGroupCode,
        'admin_user': {
          'id': adminUserId,
          'name': adminUserName,
          'email': adminUserEmail,
        },
      },
      'transfers': {
        'count': transfersCount,
        'total_usd': transfersTotalUsd,
        'total_syp': transfersTotalSyp,
        'total_try': transfersTotalTry,
      },
      'expenses': {
        'count': expensesCount,
        'total_usd': expensesTotalUsd,
        'total_syp': expensesTotalSyp,
        'total_try': expensesTotalTry,
      },
    };
  }

  @override
  String toString() {
    return 'AdminGroupAnalyticsData(id: $adminGroupId, name: $adminGroupName, admin: $adminUserName)';
  }
}

// Keep old DTOs for backward compatibility
typedef AdminGroupAnalyticsDto = AdminGroupAnalyticsData;

/// Transfer statistics for an admin group
class TransferStatisticsDto {
  final int totalCount;
  final double totalAmountUsd;
  final double totalAmountSyp;
  final double totalAmountTry;

  const TransferStatisticsDto({
    required this.totalCount,
    required this.totalAmountUsd,
    required this.totalAmountSyp,
    required this.totalAmountTry,
  });

  /// Create from JSON response
  factory TransferStatisticsDto.fromJson(Map<String, dynamic> json) {
    return TransferStatisticsDto(
      totalCount: json['total_count'] as int? ?? 0,
      totalAmountUsd: (json['total_amount_usd'] as num?)?.toDouble() ?? 0.0,
      totalAmountSyp: (json['total_amount_syp'] as num?)?.toDouble() ?? 0.0,
      totalAmountTry: (json['total_amount_try'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'total_amount_usd': totalAmountUsd,
      'total_amount_syp': totalAmountSyp,
      'total_amount_try': totalAmountTry,
    };
  }

  @override
  String toString() {
    return 'TransferStatisticsDto(count: $totalCount, USD: $totalAmountUsd, SYP: $totalAmountSyp, TRY: $totalAmountTry)';
  }
}

/// Expense statistics for an admin group
class ExpenseStatisticsDto {
  final int totalCount;
  final double totalAmountUsd;
  final double totalAmountSyp;
  final double totalAmountTry;

  const ExpenseStatisticsDto({
    required this.totalCount,
    required this.totalAmountUsd,
    required this.totalAmountSyp,
    required this.totalAmountTry,
  });

  /// Create from JSON response
  factory ExpenseStatisticsDto.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsDto(
      totalCount: json['total_count'] as int? ?? 0,
      totalAmountUsd: (json['total_amount_usd'] as num?)?.toDouble() ?? 0.0,
      totalAmountSyp: (json['total_amount_syp'] as num?)?.toDouble() ?? 0.0,
      totalAmountTry: (json['total_amount_try'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'total_amount_usd': totalAmountUsd,
      'total_amount_syp': totalAmountSyp,
      'total_amount_try': totalAmountTry,
    };
  }

  @override
  String toString() {
    return 'ExpenseStatisticsDto(count: $totalCount, USD: $totalAmountUsd, SYP: $totalAmountSyp, TRY: $totalAmountTry)';
  }
}
