import 'package:equatable/equatable.dart';

/// Domain entity representing a user's fund box
/// Contains the balance and metadata for a user's fund storage
class FundBox extends Equatable {
  final int id;
  final int userId;
  final double balanceUsd;
  final DateTime updatedAt;

  const FundBox({
    required this.id,
    required this.userId,
    required this.balanceUsd,
    required this.updatedAt,
  });

  FundBox copyWith({
    int? id,
    int? userId,
    double? balanceUsd,
    DateTime? updatedAt,
  }) {
    return FundBox(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, balanceUsd, updatedAt];
}
