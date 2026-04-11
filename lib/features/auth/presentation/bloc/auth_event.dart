import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String? organizationName;
  final String? departmentName;
  final String? adminGroupName; // SuperAdmin group name (for SuperAdmin registration)
  final String? groupCode; // Admin group code (for users joining admin groups)
  final String? superAdminGroupCode; // SuperAdmin group code (for admins joining SuperAdmin groups)
  final String role;

  const AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.organizationName,
    this.departmentName,
    this.adminGroupName,
    this.groupCode,
    this.superAdminGroupCode,
    this.role = 'user',
  });

  @override
  List<Object?> get props => [username, email, password, confirmPassword, organizationName, departmentName, adminGroupName, groupCode, superAdminGroupCode, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthPasswordChangeRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const AuthPasswordChangeRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class AuthPasswordResetWithTokenRequested extends AuthEvent {
  final String token;
  final String email;
  final String password;

  const AuthPasswordResetWithTokenRequested({
    required this.token,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [token, email, password];
}

class LoadOrganizationsEvent extends AuthEvent {
  const LoadOrganizationsEvent();
}

class LoadDepartmentsEvent extends AuthEvent {
  final int organizationId;

  const LoadDepartmentsEvent(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

class OrganizationSelectedEvent extends AuthEvent {
  final int organizationId;

  const OrganizationSelectedEvent(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}
