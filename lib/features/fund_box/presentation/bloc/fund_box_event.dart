import 'package:equatable/equatable.dart';

/// Base class for all FundBox events
abstract class FundBoxEvent extends Equatable {
  const FundBoxEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load fund box for a specific user
class LoadFundBox extends FundBoxEvent {
  final int userId;
  final String? currency; // Optional: 'USD', 'SYP', or 'TRY'

  const LoadFundBox(this.userId, {this.currency});

  @override
  List<Object?> get props => [userId, currency];
}

/// Event to update fund box balance
/// Supports multi-currency updates
class UpdateFundBalance extends FundBoxEvent {
  final int userId;
  final double? balanceUsd;
  final double? balanceSyp;
  final double? balanceTry;
  final double? newBalance; // Legacy parameter for backward compatibility

  const UpdateFundBalance({
    required this.userId,
    this.balanceUsd,
    this.balanceSyp,
    this.balanceTry,
    this.newBalance,
  });

  @override
  List<Object?> get props => [userId, balanceUsd, balanceSyp, balanceTry, newBalance];
}

/// Event to refresh fund box data
class RefreshFundBox extends FundBoxEvent {
  final int userId;
  final String? currency; // Optional: 'USD', 'SYP', or 'TRY'

  const RefreshFundBox(this.userId, {this.currency});

  @override
  List<Object?> get props => [userId, currency];
}

/// Event to load calculated balance from transactions (real-time calculation)
/// Use this when you need the most up-to-date balance calculated from transactions
class LoadCalculatedBalance extends FundBoxEvent {
  final String? currency; // Optional: 'USD', 'SYP', or 'TRY'

  const LoadCalculatedBalance({this.currency});

  @override
  List<Object?> get props => [currency];
}