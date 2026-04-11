import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/domain/entities/user.dart';

/// Widget that conditionally shows content based on user role
/// Used to hide admin features from regular users
class RoleBasedWidget extends StatelessWidget {
  /// Child widget to show if user has required role
  final Widget child;

  /// Required role to show the widget
  final UserRole? requiredRole;

  /// Show only to admin users
  final bool adminOnly;

  /// Show only to regular users
  final bool userOnly;

  /// Widget to show if user doesn't have required role
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    required this.child,
    this.requiredRole,
    this.adminOnly = false,
    this.userOnly = false,
    this.fallback,
  });

  /// Factory constructor for admin-only widgets
  factory RoleBasedWidget.adminOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return RoleBasedWidget(
      adminOnly: true,
      fallback: fallback,
      child: child,
    );
  }

  /// Factory constructor for user-only widgets
  factory RoleBasedWidget.userOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return RoleBasedWidget(
      userOnly: true,
      fallback: fallback,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated || state.user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        final user = state.user!;
        final hasPermission = _checkPermission(user);

        if (hasPermission) {
          return child;
        } else {
          return fallback ?? const SizedBox.shrink();
        }
      },
    );
  }

  bool _checkPermission(User user) {
    // Check admin only
    if (adminOnly) {
      return user.isAdmin;
    }

    // Check user only
    if (userOnly) {
      return user.role == UserRole.user;
    }

    // Check specific role
    if (requiredRole != null) {
      return user.role == requiredRole;
    }

    // No restrictions, show to all authenticated users
    return true;
  }
}

/// Extension on BuildContext for easy role checking
extension RoleCheckExtension on BuildContext {
  /// Check if current user is admin
  bool get isAdmin {
    final authState = read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      return authState.user!.isAdmin;
    }
    return false;
  }

  /// Check if current user is regular user
  bool get isUser {
    final authState = read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      return authState.user!.role == UserRole.user;
    }
    return false;
  }

  /// Get current user role
  UserRole? get userRole {
    final authState = read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      return authState.user!.role;
    }
    return null;
  }

  /// Get current user
  User? get currentUser {
    final authState = read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user;
    }
    return null;
  }
}
