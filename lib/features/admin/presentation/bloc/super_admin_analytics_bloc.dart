import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_super_admin_analytics_usecase.dart';
import 'super_admin_analytics_event.dart';
import 'super_admin_analytics_state.dart';

class SuperAdminAnalyticsBloc extends Bloc<SuperAdminAnalyticsEvent, SuperAdminAnalyticsState> {
  final GetSuperAdminAnalyticsUseCase getAnalyticsUseCase;

  SuperAdminAnalyticsBloc({
    required this.getAnalyticsUseCase,
  }) : super(const SuperAdminAnalyticsInitial()) {
    on<LoadSuperAdminAnalyticsEvent>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadSuperAdminAnalyticsEvent event,
    Emitter<SuperAdminAnalyticsState> emit,
  ) async {
    emit(const SuperAdminAnalyticsLoading());

    final result = await getAnalyticsUseCase(event.period);

    result.fold(
      (failure) {
        emit(SuperAdminAnalyticsError(
          failure.message,
          isForbidden: failure is AuthorizationFailure,
        ));
      },
      (analytics) {
        emit(SuperAdminAnalyticsLoaded(analytics));
      },
    );
  }
}

