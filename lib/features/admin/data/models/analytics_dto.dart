/// Data Transfer Object for analytics data
/// Maps between API JSON and domain entities
/// Matches Laravel API spec: /admin/dashboard/analytics
class AnalyticsDto {
  final DatePeriod period;
  final ExpenseAnalytics expenses;
  final IncomeAnalytics income;
  final double netBalance;
  final TrendsData trends;

  const AnalyticsDto({
    required this.period,
    required this.expenses,
    required this.income,
    required this.netBalance,
    required this.trends,
  });

  /// Create AnalyticsDto from JSON response
  factory AnalyticsDto.fromJson(Map<String, dynamic> json) {
    return AnalyticsDto(
      period: DatePeriod.fromJson(json['period'] as Map<String, dynamic>),
      expenses: ExpenseAnalytics.fromJson(json['expenses'] as Map<String, dynamic>),
      income: IncomeAnalytics.fromJson(json['income'] as Map<String, dynamic>),
      netBalance: (json['net_balance'] as num?)?.toDouble() ?? 0.0,
      trends: TrendsData.fromJson(json['trends'] as Map<String, dynamic>),
    );
  }

  /// Convert AnalyticsDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'period': period.toJson(),
      'expenses': expenses.toJson(),
      'income': income.toJson(),
      'net_balance': netBalance,
      'trends': trends.toJson(),
    };
  }

  @override
  String toString() {
    return 'AnalyticsDto(period: $period, expenses: $expenses, income: $income, netBalance: $netBalance)';
  }
}

/// Date period for analytics
class DatePeriod {
  final String from;
  final String to;

  const DatePeriod({
    required this.from,
    required this.to,
  });

  factory DatePeriod.fromJson(Map<String, dynamic> json) {
    return DatePeriod(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }

  @override
  String toString() {
    return 'DatePeriod(from: $from, to: $to)';
  }
}

/// Expense analytics data
class ExpenseAnalytics {
  final double total;
  final int count;
  final double average;

  const ExpenseAnalytics({
    required this.total,
    required this.count,
    required this.average,
  });

  factory ExpenseAnalytics.fromJson(Map<String, dynamic> json) {
    return ExpenseAnalytics(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'count': count,
      'average': average,
    };
  }

  @override
  String toString() {
    return 'ExpenseAnalytics(total: $total, count: $count, average: $average)';
  }
}

/// Income analytics data
class IncomeAnalytics {
  final double total;
  final int count;
  final double average;

  const IncomeAnalytics({
    required this.total,
    required this.count,
    required this.average,
  });

  factory IncomeAnalytics.fromJson(Map<String, dynamic> json) {
    return IncomeAnalytics(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'count': count,
      'average': average,
    };
  }

  @override
  String toString() {
    return 'IncomeAnalytics(total: $total, count: $count, average: $average)';
  }
}

/// Trends data with monthly breakdown
class TrendsData {
  final List<MonthlyTrend> monthly;

  const TrendsData({
    required this.monthly,
  });

  factory TrendsData.fromJson(Map<String, dynamic> json) {
    return TrendsData(
      monthly: (json['monthly'] as List<dynamic>?)
              ?.map((item) => MonthlyTrend.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly': monthly.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'TrendsData(monthly: ${monthly.length} items)';
  }
}

/// Monthly trend data
class MonthlyTrend {
  final String month;
  final double expenses;
  final double income;

  const MonthlyTrend({
    required this.month,
    required this.expenses,
    required this.income,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] as String,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'expenses': expenses,
      'income': income,
    };
  }

  @override
  String toString() {
    return 'MonthlyTrend(month: $month, expenses: $expenses, income: $income)';
  }
}
