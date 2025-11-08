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
