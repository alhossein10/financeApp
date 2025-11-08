import 'package:equatable/equatable.dart';

/// Domain entity representing a user's fund box
/// Contains multi-currency balances (USD, SYP, TRY) and metadata
class FundBox extends Equatable {
  final int id;
  final int userId;
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime? lastCalculatedAt;
  final DateTime updatedAt;

  const FundBox({
    required this.id,
    required this.userId,
    required this.balanceUsd,
    required this.balanceSyp,
    required this.balanceTry,
    this.lastCalculatedAt,
    required this.updatedAt,
  });

  FundBox copyWith({
    int? id,
    int? userId,
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
    DateTime? lastCalculatedAt,
    DateTime? updatedAt,
  }) {
    return FundBox(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      balanceSyp: balanceSyp ?? this.balanceSyp,
      balanceTry: balanceTry ?? this.balanceTry,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        balanceUsd,
        balanceSyp,
        balanceTry,
        lastCalculatedAt,
        updatedAt,
      ];
}
