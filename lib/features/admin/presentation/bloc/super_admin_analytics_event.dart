import 'package:equatable/equatable.dart';

abstract class SuperAdminAnalyticsEvent extends Equatable {
  const SuperAdminAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuperAdminAnalyticsEvent extends SuperAdminAnalyticsEvent {
  final String period; // '15days', 'month', or 'all'

  const LoadSuperAdminAnalyticsEvent(this.period);

  @override
  List<Object?> get props => [period];
}

