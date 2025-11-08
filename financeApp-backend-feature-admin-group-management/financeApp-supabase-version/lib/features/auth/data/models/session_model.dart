import '../../domain/entities/session.dart';

/// Session model for data layer, extends Session entity
/// Handles serialization/deserialization to/from database
class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.userId,
    required super.token,
    required super.createdAt,
    required super.expiresAt,
    required super.lastActivity,
  });

  /// Create SessionModel from database map
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      token: map['token'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      lastActivity: DateTime.fromMillisecondsSinceEpoch(map['last_activity'] as int),
    );
  }

  /// Convert SessionModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'created_at': createdAt.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'last_activity': lastActivity.millisecondsSinceEpoch,
    };
  }

  /// Create SessionModel from Session entity
  factory SessionModel.fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      userId: session.userId,
      token: session.token,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      lastActivity: session.lastActivity,
    );
  }

  /// Create a copy of SessionModel with updated fields
  SessionModel copyWith({
    int? id,
    int? userId,
    String? token,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActivity,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}
