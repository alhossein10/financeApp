import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_fund_box_usecase.dart';
import '../../domain/usecases/update_fund_balance_usecase.dart';
import 'fund_box_event.dart';
import 'fund_box_state.dart';

/// BLoC for managing fund box state and operations
/// Handles loading and updating fund box data
class FundBoxBloc extends Bloc<FundBoxEvent, FundBoxState> {
  final GetFundBoxUseCase getFundBoxUseCase;
  final UpdateFundBalanceUseCase updateFundBalanceUseCase;

  FundBoxBloc({
    required this.getFundBoxUseCase,
    required this.updateFundBalanceUseCase,
  }) : super(const FundBoxInitial()) {
    on<LoadFundBox>(_onLoadFundBox);
    on<UpdateFundBalance>(_onUpdateFundBalance);
    on<RefreshFundBox>(_onRefreshFundBox);
  }

  /// Handle loading fund box for a user
  Future<void> _onLoadFundBox(
    LoadFundBox event,
    Emitter<FundBoxState> emit,
  ) async {
    emit(const FundBoxLoading());

    final result = await getFundBoxUseCase(event.userId);

    result.fold(
      (failure) => emit(FundBoxError(failure.message)),
      (fundBox) => emit(FundBoxLoaded(fundBox)),
    );
  }

  /// Handle updating fund box balance
  Future<void> _onUpdateFundBalance(
    UpdateFundBalance event,
    Emitter<FundBoxState> emit,
  ) async {
    // Show updating state with current data if available
    if (state is FundBoxLoaded) {
      emit(FundBoxUpdating((state as FundBoxLoaded).fundBox));
    } else {
      emit(const FundBoxLoading());
    }

    final result = await updateFundBalanceUseCase(
      UpdateFundBalanceParams(
        userId: event.userId,
        newBalance: event.newBalance,
      ),
    );

    result.fold(
      (failure) => emit(FundBoxError(failure.message)),
      (fundBox) => emit(FundBoxLoaded(fundBox)),
    );
  }

  /// Handle refreshing fund box data
  Future<void> _onRefreshFundBox(
    RefreshFundBox event,
    Emitter<FundBoxState> emit,
  ) async {
    // Don't show loading state for refresh, keep current data visible
    final result = await getFundBoxUseCase(event.userId);

    result.fold(
      (failure) => emit(FundBoxError(failure.message)),
      (fundBox) => emit(FundBoxLoaded(fundBox)),
    );
  }
}
