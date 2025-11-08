import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdminStatisticsRequested extends AdminEvent {
  const FetchAdminStatisticsRequested();
}

class FetchAllUserExpensesRequested extends AdminEvent {
  const FetchAllUserExpensesRequested();
}

/// Event to fetch dashboard statistics from API
class FetchDashboardStatsRequested extends AdminEvent {
  const FetchDashboardStatsRequested();
}

/// Event to fetch user activity from API
class FetchUserActivityRequested extends AdminEvent {
  const FetchUserActivityRequested();
}

/// Event to fetch expense summaries from API
class FetchExpenseSummariesRequested extends AdminEvent {
  const FetchExpenseSummariesRequested();
}

/// Event to fetch analytics with date range filtering
class FetchAnalyticsRequested extends AdminEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetchAnalyticsRequested({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
