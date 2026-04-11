import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/filter_persistence_service.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/reset_password_with_token_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_organizations_usecase.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final ResetPasswordWithTokenUseCase resetPasswordWithTokenUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final GetOrganizationsUseCase getOrganizationsUseCase;
  final GetDepartmentsUseCase getDepartmentsUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.checkAuthStatusUseCase,
    required this.resetPasswordUseCase,
    required this.resetPasswordWithTokenUseCase,
    required this.changePasswordUseCase,
    required this.getOrganizationsUseCase,
    required this.getDepartmentsUseCase,
  }) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckAuthRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordResetWithTokenRequested>(_onPasswordResetWithTokenRequested);
    on<AuthPasswordChangeRequested>(_onPasswordChangeRequested);
    on<LoadOrganizationsEvent>(_onLoadOrganizations);
    on<LoadDepartmentsEvent>(_onLoadDepartments);
    on<OrganizationSelectedEvent>(_onOrganizationSelected);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Login requested for: ${event.email}');
    emit(const AuthLoading());

    final result = await loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
        rememberMe: event.rememberMe,
      ),
    );

    result.fold(
      (failure) {
        print('🔴 [BLOC] Login failed: ${failure.message}');
        emit(AuthError(message: _formatErrorMessage(failure.message)));
      },
      (user) {
        print('🟢 [BLOC] Login successful for user: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Registration requested for: ${event.email} with role: ${event.role}');
    print('🔵 [BLOC] Organization: ${event.organizationName}, Department: ${event.departmentName}, Group Code: ${event.groupCode}');
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await registerUseCase(
      RegisterParams(
        username: event.username,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        organizationName: event.organizationName,
        departmentName: event.departmentName,
        adminGroupName: event.adminGroupName,
        groupCode: event.groupCode,
        superAdminGroupCode: event.superAdminGroupCode,
        role: event.role,
      ),
    );

    result.fold(
      (failure) {
        print('🔴 [BLOC] Registration failed: ${failure.message}');
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: _formatErrorMessage(failure.message),
        ));
      },
      (registrationResult) {
        print('🟢 [BLOC] Registration successful for user: ${registrationResult.user.email} with role: ${registrationResult.user.role}');
        if (registrationResult.groupCode != null) {
          print('🔑 [BLOC] Admin group code: ${registrationResult.groupCode}');
        }
        if (registrationResult.superAdminGroupCode != null) {
          print('🔑 [BLOC] SuperAdmin group code: ${registrationResult.superAdminGroupCode}');
        }
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: registrationResult.user,
          groupCode: registrationResult.groupCode,
          registrationResult: registrationResult,
          clearError: true,
        ));
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Clear all persisted filters on logout
    // Requirement: 26.5
    FilterPersistenceService().clearAllFilters();

    final result = await logoutUseCase();

    result.fold(
      (failure) {
        // Even if logout fails on server, still mark as unauthenticated locally
        emit(const AuthUnauthenticated());
      },
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Checking authentication status...');
    emit(const AuthLoading());

    // First check if token exists locally
    final isAuthenticatedResult = await checkAuthStatusUseCase();

    await isAuthenticatedResult.fold(
      (failure) async {
        print('🔴 [BLOC] Auth check failed: ${failure.message}');
        emit(const AuthUnauthenticated());
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          print('🟢 [BLOC] Token found locally, validating with server...');
          
          // Token exists locally, now validate with server
          final userResult = await getCurrentUserUseCase();
          userResult.fold(
            (failure) {
              print('🔴 [BLOC] Server validation failed: ${failure.message}');
              // If server validation fails (e.g., 401), mark as unauthenticated
              emit(const AuthUnauthenticated());
            },
            (user) {
              print('🟢 [BLOC] Authentication validated successfully for: ${user.email}');
              emit(AuthAuthenticated(user: user));
            },
          );
        } else {
          print('⚠️ [BLOC] No token found locally');
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await resetPasswordUseCase(
      ResetPasswordParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(message: _formatErrorMessage(failure.message))),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  Future<void> _onPasswordResetWithTokenRequested(
    AuthPasswordResetWithTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await resetPasswordWithTokenUseCase(
      ResetPasswordWithTokenParams(
        token: event.token,
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(message: _formatErrorMessage(failure.message))),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  Future<void> _onPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Store current state to restore if needed
    final currentState = state;
    
    emit(const AuthLoading());

    final result = await changePasswordUseCase(
      ChangePasswordParams(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
      (failure) {
        // Restore previous state on error
        if (currentState is AuthAuthenticated) {
          emit(currentState);
        }
        emit(AuthError(message: _formatErrorMessage(failure.message)));
      },
      (_) => emit(const AuthPasswordChangeSuccess()),
    );
  }

  Future<void> _onLoadOrganizations(
    LoadOrganizationsEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Loading organizations...');
    emit(state.copyWith(isLoadingOrganizations: true));

    final result = await getOrganizationsUseCase();

    result.fold(
      (failure) {
        print('🔴 [BLOC] Failed to load organizations: ${failure.message}');
        emit(state.copyWith(
          isLoadingOrganizations: false,
          status: AuthStatus.error,
          errorMessage: 'Failed to load organizations: ${failure.message}',
        ));
      },
      (organizations) {
        print('🟢 [BLOC] Loaded ${organizations.length} organizations');
        emit(state.copyWith(
          isLoadingOrganizations: false,
          organizations: organizations,
        ));
      },
    );
  }

  Future<void> _onLoadDepartments(
    LoadDepartmentsEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Loading departments for organization ${event.organizationId}...');
    emit(state.copyWith(isLoadingDepartments: true, departments: []));

    final result = await getDepartmentsUseCase(event.organizationId);

    result.fold(
      (failure) {
        print('🔴 [BLOC] Failed to load departments: ${failure.message}');
        emit(state.copyWith(
          isLoadingDepartments: false,
          status: AuthStatus.error,
          errorMessage: 'Failed to load departments: ${failure.message}',
        ));
      },
      (departments) {
        print('🟢 [BLOC] Loaded ${departments.length} departments');
        emit(state.copyWith(
          isLoadingDepartments: false,
          departments: departments,
        ));
      },
    );
  }

  Future<void> _onOrganizationSelected(
    OrganizationSelectedEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [BLOC] Organization selected: ${event.organizationId}');
    emit(state.copyWith(
      selectedOrganizationId: event.organizationId,
      departments: [], // Clear departments when organization changes
    ));
  }

  /// Format error messages for better user experience
  String _formatErrorMessage(String message) {
    // Remove technical details and provide user-friendly messages
    if (message.contains('401') || message.toLowerCase().contains('unauthorized')) {
      return 'Invalid email or password. Please try again.';
    } else if (message.contains('422') || message.toLowerCase().contains('validation')) {
      return message; // Validation messages are usually already user-friendly
    } else if (message.contains('429') || message.toLowerCase().contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    } else if (message.contains('500') || message.toLowerCase().contains('server error')) {
      return 'Server error. Please try again later.';
    } else if (message.toLowerCase().contains('network') || 
               message.toLowerCase().contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Return original message if no specific formatting applies
    return message;
  }
}
