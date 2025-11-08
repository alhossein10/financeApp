import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/role_service.dart';
import '../../domain/usecases/get_fund_box_usecase.dart';
import '../../domain/usecases/get_calculated_balance_usecase.dart';
import '../../domain/usecases/update_fund_balance_usecase.dart';
import 'fund_box_event.dart';
import 'fund_box_state.dart';

/// BLoC for managing fund box state and operations
/// Handles loading and updating fund box data via Laravel API
/// Includes special handling for 403 Forbidden errors (non-admin access)
/// Supports both stored balance (fund-box) and calculated balance (calculated-balance) endpoints
class FundBoxBloc extends Bloc<FundBoxEvent, FundBoxState> {
  final GetFundBoxUseCase getFundBoxUseCase;
  final GetCalculatedBalanceUseCase getCalculatedBalanceUseCase;
  final UpdateFundBalanceUseCase updateFundBalanceUseCase;
  final RoleService roleService;

  FundBoxBloc({
    required this.getFundBoxUseCase,
    required this.getCalculatedBalanceUseCase,
    required this.updateFundBalanceUseCase,
    required this.roleService,
  }) : super(const FundBoxInitial()) {
    on<LoadFundBox>(_onLoadFundBox);
    on<LoadCalculatedBalance>(_onLoadCalculatedBalance);
    on<UpdateFundBalance>(_onUpdateFundBalance);
    on<RefreshFundBox>(_onRefreshFundBox);
  }

  /// Handle loading fund box for a user
  /// For regular users, this uses the fund-box endpoint which now returns calculated balance
  /// For admins/superadmins, this uses the fund-box endpoint which returns stored balance
  Future<void> _onLoadFundBox(
    LoadFundBox event,
    Emitter<FundBoxState> emit,
  ) async {
    // Don't emit loading if already in error state to prevent infinite loops
    if (state is! FundBoxError) {
      emit(const FundBoxLoading());
    }

    try {
      // Check if user can access fund box (both admin and regular users can)
      final canAccess = await roleService.canAccessFundBox();
      if (!canAccess) {
        throw InsufficientPermissionsException(
          'You must be logged in to access fund box',
        );
      }
      
      // Check if user is a regular user (not admin/superadmin)
      // For regular users, the fund-box endpoint now returns calculated balance automatically
      // For admins/superadmins, it returns stored balance
      final isRegularUser = await roleService.isUser();
      
      if (isRegularUser) {
        // For regular users, use calculated balance endpoint for real-time accuracy
        // Note: The fund-box endpoint also returns calculated balance for users,
        // but using calculated-balance endpoint is more explicit and always real-time
        print('🟢 [FUND_BOX] Regular user detected - using calculated balance');
        final result = await getCalculatedBalanceUseCase(currency: event.currency);
        
        result.fold(
          (failure) {
            print('🔴 [FUND_BOX] Calculated balance load failed: ${failure.message}');
            // Fallback to standard fund-box endpoint if calculated balance fails
            _loadStandardFundBox(event, emit);
          },
          (fundBox) {
            print('🟢 [FUND_BOX] Calculated balance loaded: USD=${fundBox.balanceUsd}, SYP=${fundBox.balanceSyp}, TRY=${fundBox.balanceTry}');
            emit(FundBoxLoaded(fundBox));
          },
        );
      } else {
        // For admins/superadmins, use standard fund-box endpoint (stored balance)
        print('🟢 [FUND_BOX] Admin/SuperAdmin detected - using standard fund-box endpoint');
        try {
          await _loadStandardFundBox(event, emit);
        } catch (e, stackTrace) {
          print('🔴 [FUND_BOX] Error in _loadStandardFundBox: $e');
          print('🔴 [FUND_BOX] Stack trace: $stackTrace');
          emit(FundBoxError(
            'Failed to load fund box: ${e.toString()}',
          ));
        }
      }
    } on InsufficientPermissionsException catch (e) {
      print('🔴 [FUND_BOX] Permission denied: ${e.message}');
      emit(FundBoxError(
        e.message,
        isForbidden: true,
      ));
    } catch (e, stackTrace) {
      print('🔴 [FUND_BOX] Unexpected error in _onLoadFundBox: $e');
      print('🔴 [FUND_BOX] Stack trace: $stackTrace');
      emit(FundBoxError(
        'Failed to load fund box: ${e.toString()}',
      ));
    }
  }

  /// Load standard fund box (stored balance for admins, calculated for users)
  Future<void> _loadStandardFundBox(
    LoadFundBox event,
    Emitter<FundBoxState> emit,
  ) async {
    try {
      print('🟢 [FUND_BOX] Loading standard fund box for userId: ${event.userId}, currency: ${event.currency}');
      final result = await getFundBoxUseCase(event.userId, currency: event.currency);

      result.fold(
        (failure) {
          print('🔴 [FUND_BOX] Load failed: ${failure.message}');
          print('🔴 [FUND_BOX] Failure type: ${failure.runtimeType}');
          _handleError(failure, emit);
        },
        (fundBox) {
          print('🟢 [FUND_BOX] Loaded successfully: USD=${fundBox.balanceUsd}, SYP=${fundBox.balanceSyp}, TRY=${fundBox.balanceTry}');
          print('🟢 [FUND_BOX] Emitting FundBoxLoaded state');
          emit(FundBoxLoaded(fundBox));
          print('🟢 [FUND_BOX] FundBoxLoaded state emitted');
        },
      );
    } catch (e, stackTrace) {
      print('🔴 [FUND_BOX] Exception in _loadStandardFundBox: $e');
      print('🔴 [FUND_BOX] Stack trace: $stackTrace');
      emit(FundBoxError(
        'Failed to load fund box: ${e.toString()}',
      ));
    }
  }

  /// Handle loading calculated balance (real-time from transactions)
  /// Available to all authenticated users
  Future<void> _onLoadCalculatedBalance(
    LoadCalculatedBalance event,
    Emitter<FundBoxState> emit,
  ) async {
    // Don't emit loading if already in error state to prevent infinite loops
    if (state is! FundBoxError) {
      emit(const FundBoxLoading());
    }

    try {
      // Check if user can access fund box (both admin and regular users can)
      final canAccess = await roleService.canAccessFundBox();
      if (!canAccess) {
        throw InsufficientPermissionsException(
          'You must be logged in to access calculated balance',
        );
      }
      
      print('🟢 [FUND_BOX] Loading calculated balance from transactions...');
      final result = await getCalculatedBalanceUseCase(currency: event.currency);

      result.fold(
        (failure) {
          print('🔴 [FUND_BOX] Calculated balance load failed: ${failure.message}');
          _handleError(failure, emit);
        },
        (fundBox) {
          print('🟢 [FUND_BOX] Calculated balance loaded: USD=${fundBox.balanceUsd}, SYP=${fundBox.balanceSyp}, TRY=${fundBox.balanceTry}');
          emit(FundBoxLoaded(fundBox));
        },
      );
    } on InsufficientPermissionsException catch (e) {
      print('🔴 [FUND_BOX] Permission denied: ${e.message}');
      emit(FundBoxError(
        e.message,
        isForbidden: true,
      ));
    } catch (e, stackTrace) {
      print('🔴 [FUND_BOX] Unexpected error in _onLoadCalculatedBalance: $e');
      print('🔴 [FUND_BOX] Stack trace: $stackTrace');
      emit(FundBoxError(
        'Failed to load calculated balance: ${e.toString()}',
      ));
    }
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

    try {
      // Validate admin permission before API call (only admins can update fund box)
      await roleService.requireAdminPermission();
      
      final result = await updateFundBalanceUseCase(
        UpdateFundBalanceParams(
          userId: event.userId,
          balanceUsd: event.balanceUsd,
          balanceSyp: event.balanceSyp,
          balanceTry: event.balanceTry,
          newBalance: event.newBalance, // Legacy support
        ),
      );

      result.fold(
        (failure) => _handleError(failure, emit),
        (fundBox) => emit(FundBoxLoaded(fundBox)),
      );
    } on InsufficientPermissionsException catch (e) {
      emit(FundBoxError(
        e.message,
        isForbidden: true,
      ));
    }
  }

  /// Handle refreshing fund box data
  /// For regular users, refreshes calculated balance for real-time accuracy
  Future<void> _onRefreshFundBox(
    RefreshFundBox event,
    Emitter<FundBoxState> emit,
  ) async {
    // Don't show loading state for refresh, keep current data visible
    try {
      // Check if user is a regular user
      final isRegularUser = await roleService.isUser();
      
      if (isRegularUser) {
        // For regular users, refresh calculated balance for real-time accuracy
        final result = await getCalculatedBalanceUseCase(currency: event.currency);
        result.fold(
          (failure) => _handleError(failure, emit),
          (fundBox) => emit(FundBoxLoaded(fundBox)),
        );
      } else {
        // For admins/superadmins, refresh standard fund box (stored balance)
        final result = await getFundBoxUseCase(event.userId, currency: event.currency);
        result.fold(
          (failure) => _handleError(failure, emit),
          (fundBox) => emit(FundBoxLoaded(fundBox)),
        );
      }
    } catch (e) {
      // Fallback to standard fund box on error
      final result = await getFundBoxUseCase(event.userId, currency: event.currency);
      result.fold(
        (failure) => _handleError(failure, emit),
        (fundBox) => emit(FundBoxLoaded(fundBox)),
      );
    }
  }

  /// Enhanced error handling with support for 401, 403, 422, 429
  void _handleError(Failure failure, Emitter<FundBoxState> emit) {
    final errorResult = ErrorHandler.createEnhancedError(failure);
    
    emit(FundBoxError(
      errorResult.displayMessage,
      requiresLogout: errorResult.requiresLogout,
      isForbidden: errorResult.isForbidden,
      isValidationError: errorResult.isValidationError,
      isRateLimited: errorResult.isRateLimited,
      retryAfterSeconds: errorResult.retryAfterDuration?.inSeconds,
    ));
  }
}
