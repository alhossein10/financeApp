import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/registration_result.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  passwordResetSuccess,
  passwordChangeSuccess,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? groupCode; // Admin group code for admin registration
  final RegistrationResult? registrationResult; // Full registration result (includes SuperAdmin group code)
  final List<Organization> organizations;
  final List<Department> departments;
  final int? selectedOrganizationId;
  final bool isLoadingOrganizations;
  final bool isLoadingDepartments;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.groupCode,
    this.registrationResult,
    this.organizations = const [],
    this.departments = const [],
    this.selectedOrganizationId,
    this.isLoadingOrganizations = false,
    this.isLoadingDepartments = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? groupCode,
    RegistrationResult? registrationResult,
    List<Organization>? organizations,
    List<Department>? departments,
    int? selectedOrganizationId,
    bool? isLoadingOrganizations,
    bool? isLoadingDepartments,
    bool clearError = false,
    bool clearUser = false,
    bool clearGroupCode = false,
    bool clearRegistrationResult = false,
    bool clearSelectedOrganization = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      groupCode: clearGroupCode ? null : (groupCode ?? this.groupCode),
      registrationResult: clearRegistrationResult ? null : (registrationResult ?? this.registrationResult),
      organizations: organizations ?? this.organizations,
      departments: departments ?? this.departments,
      selectedOrganizationId: clearSelectedOrganization ? null : (selectedOrganizationId ?? this.selectedOrganizationId),
      isLoadingOrganizations: isLoadingOrganizations ?? this.isLoadingOrganizations,
      isLoadingDepartments: isLoadingDepartments ?? this.isLoadingDepartments,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        groupCode,
        registrationResult,
        organizations,
        departments,
        selectedOrganizationId,
        isLoadingOrganizations,
        isLoadingDepartments,
      ];
}

// Legacy state classes for backward compatibility
class AuthInitial extends AuthState {
  const AuthInitial() : super(status: AuthStatus.initial);
}

class AuthLoading extends AuthState {
  const AuthLoading() : super(status: AuthStatus.loading);
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required User user})
      : super(status: AuthStatus.authenticated, user: user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated() : super(status: AuthStatus.unauthenticated);
}

class AuthError extends AuthState {
  const AuthError({required String message})
      : super(status: AuthStatus.error, errorMessage: message);
  
  String get message => errorMessage ?? 'Unknown error';
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess() : super(status: AuthStatus.passwordResetSuccess);
}

class AuthPasswordChangeSuccess extends AuthState {
  const AuthPasswordChangeSuccess() : super(status: AuthStatus.passwordChangeSuccess);
}
