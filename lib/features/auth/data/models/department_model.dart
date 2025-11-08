import '../../domain/entities/department.dart';

/// Data model for Department with JSON serialization
class DepartmentModel extends Department {
  const DepartmentModel({
    required int id,
    required int organizationId,
    required String name,
  }) : super(
          id: id,
          organizationId: organizationId,
          name: name,
        );

  /// Creates a DepartmentModel from JSON
  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      name: json['name'] as String,
    );
  }

  /// Converts the DepartmentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
    };
  }

  /// Creates a copy of this model with updated fields
  DepartmentModel copyWith({
    int? id,
    int? organizationId,
    String? name,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
    );
  }
}
