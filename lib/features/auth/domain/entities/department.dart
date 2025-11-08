import 'package:equatable/equatable.dart';

/// Department entity representing a sub-unit within an Organization
class Department extends Equatable {
  final int id;
  final int organizationId;
  final String name;

  const Department({
    required this.id,
    required this.organizationId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, organizationId, name];
}
