import 'package:equatable/equatable.dart';

/// Organization entity representing a top-level organizational unit
class Organization extends Equatable {
  final int id;
  final String name;

  const Organization({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
