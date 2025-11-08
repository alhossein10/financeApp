import '../../domain/entities/super_admin_analytics.dart';

/// Data Transfer Object for SuperAdmin Analytics
class SuperAdminAnalyticsDto {
  final String period;
  final String? startDate;
  final String endDate;
  final List<AdminGroupAnalyticsDto> adminGroups;

  const SuperAdminAnalyticsDto({
    required this.period,
    this.startDate,
    required this.endDate,
    required this.adminGroups,
  });

  factory SuperAdminAnalyticsDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final adminGroupsList = data['admin_groups'] as List<dynamic>? ?? [];
    
    return SuperAdminAnalyticsDto(
      period: data['period'] as String? ?? 'all',
      startDate: data['start_date'] as String?,
      endDate: data['end_date'] as String,
      adminGroups: adminGroupsList
          .map((item) => AdminGroupAnalyticsDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  SuperAdminAnalytics toEntity() {
    return SuperAdminAnalytics(
      period: period,
      startDate: startDate != null ? DateTime.parse(startDate!) : null,
      endDate: DateTime.parse(endDate),
      adminGroups: adminGroups.map((dto) => dto.toEntity()).toList(),
    );
  }
}

class AdminGroupAnalyticsDto {
  final AdminGroupInfoDto adminGroup;
  final TransferStatsDto transfers;
  final ExpenseStatsDto expenses;

  const AdminGroupAnalyticsDto({
    required this.adminGroup,
    required this.transfers,
    required this.expenses,
  });

  factory AdminGroupAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return AdminGroupAnalyticsDto(
      adminGroup: AdminGroupInfoDto.fromJson(json['admin_group'] as Map<String, dynamic>),
      transfers: TransferStatsDto.fromJson(json['transfers'] as Map<String, dynamic>),
      expenses: ExpenseStatsDto.fromJson(json['expenses'] as Map<String, dynamic>),
    );
  }

  AdminGroupAnalytics toEntity() {
    return AdminGroupAnalytics(
      adminGroup: adminGroup.toEntity(),
      transfers: transfers.toEntity(),
      expenses: expenses.toEntity(),
    );
  }
}

class AdminGroupInfoDto {
  final int id;
  final String name;
  final String code;
  final AdminUserDto adminUser;

  const AdminGroupInfoDto({
    required this.id,
    required this.name,
    required this.code,
    required this.adminUser,
  });

  factory AdminGroupInfoDto.fromJson(Map<String, dynamic> json) {
    return AdminGroupInfoDto(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      adminUser: AdminUserDto.fromJson(json['admin_user'] as Map<String, dynamic>),
    );
  }

  AdminGroupInfo toEntity() {
    return AdminGroupInfo(
      id: id,
      name: name,
      code: code,
      adminUser: adminUser.toEntity(),
    );
  }
}

class AdminUserDto {
  final int id;
  final String name;
  final String email;

  const AdminUserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  AdminUser toEntity() {
    return AdminUser(
      id: id,
      name: name,
      email: email,
    );
  }
}

class TransferStatsDto {
  final int count;
  final double totalUsd;

  const TransferStatsDto({
    required this.count,
    required this.totalUsd,
  });

  factory TransferStatsDto.fromJson(Map<String, dynamic> json) {
    return TransferStatsDto(
      count: json['count'] as int? ?? 0,
      totalUsd: _parseDouble(json['total_usd']) ?? 0.0,
    );
  }

  TransferStats toEntity() {
    return TransferStats(
      count: count,
      totalUsd: totalUsd,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ExpenseStatsDto {
  final int count;
  final double totalUsd;
  final double totalSyp;
  final double totalTry;

  const ExpenseStatsDto({
    required this.count,
    required this.totalUsd,
    required this.totalSyp,
    required this.totalTry,
  });

  factory ExpenseStatsDto.fromJson(Map<String, dynamic> json) {
    return ExpenseStatsDto(
      count: json['count'] as int? ?? 0,
      totalUsd: _parseDouble(json['total_usd']) ?? 0.0,
      totalSyp: _parseDouble(json['total_syp']) ?? 0.0,
      totalTry: _parseDouble(json['total_try']) ?? 0.0,
    );
  }

  ExpenseStats toEntity() {
    return ExpenseStats(
      count: count,
      totalUsd: totalUsd,
      totalSyp: totalSyp,
      totalTry: totalTry,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

