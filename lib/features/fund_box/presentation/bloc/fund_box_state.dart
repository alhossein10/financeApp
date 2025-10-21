import 'package:equatable/equatable.dart';

import '../../domain/entities/fund_box.dart';

/// Base class for all FundBox states
abstract class FundBoxState extends Equatable {
  const FundBoxState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operations
class FundBoxInitial extends FundBoxState {
  const FundBoxInitial();
}

/// State when loading fund box data
class FundBoxLoading extends FundBoxState {
  const FundBoxLoading();
}

/// State when fund box data is successfully loaded
class FundBoxLoaded extends FundBoxState {
  final FundBox fundBox;

  const FundBoxLoaded(this.fundBox);

  @override
  List<Object?> get props => [fundBox];
}

/// State when updating fund box balance
class FundBoxUpdating extends FundBoxState {
  final FundBox currentFundBox;

  const FundBoxUpdating(this.currentFundBox);

  @override
  List<Object?> get props => [currentFundBox];
}

/// State when an error occurs
class FundBoxError extends FundBoxState {
  final String message;

  const FundBoxError(this.message);

  @override
  List<Object?> get props => [message];
}
