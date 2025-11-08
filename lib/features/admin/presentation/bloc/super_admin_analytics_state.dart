import 'package:equatable/equatable.dart';
import '../../domain/entities/super_admin_analytics.dart';

abstract class SuperAdminAnalyticsState extends Equatable {
  const SuperAdminAnalyticsState();

  @override
  List<Object?> get props => [];
}

class SuperAdminAnalyticsInitial extends SuperAdminAnalyticsState {
  const SuperAdminAnalyticsInitial();
}

class SuperAdminAnalyticsLoading extends SuperAdminAnalyticsState {
  const SuperAdminAnalyticsLoading();
}

class SuperAdminAnalyticsLoaded extends SuperAdminAnalyticsState {
  final SuperAdminAnalytics analytics;

  const SuperAdminAnalyticsLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

class SuperAdminAnalyticsError extends SuperAdminAnalyticsState {
  final String message;
  final bool isForbidden;

  const SuperAdminAnalyticsError(this.message, {this.isForbidden = false});

  @override
  List<Object?> get props => [message, isForbidden];
}

