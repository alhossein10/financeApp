import 'package:equatable/equatable.dart';

/// Session entity representing a user session in the domain layer
class Session extends Equatable {
  final int id;
  final int userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime lastActivity;

  const Session({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.lastActivity,
  });

  /// Check if the session is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the session is still active
  bool get isActive => !isExpired;

  @override
  List<Object?> get props => [
        id,
        userId,
        token,
        createdAt,
        expiresAt,
        lastActivity,
      ];
}
