import 'package:equatable/equatable.dart';

class Incoming extends Equatable {
  final int? id;
  final int userId;
  final String description;
  final double amountUsd;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Incoming({
    this.id,
    required this.userId,
    required this.description,
    required this.amountUsd,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        description,
        amountUsd,
        transactionDate,
        createdAt,
        updatedAt,
      ];
}
