import '../../domain/entities/organization.dart';

/// Data model for Organization with JSON serialization
class OrganizationModel extends Organization {
  const OrganizationModel({
    required int id,
    required String name,
  }) : super(
          id: id,
          name: name,
        );

  /// Creates an OrganizationModel from JSON
  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  /// Converts the OrganizationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a copy of this model with updated fields
  OrganizationModel copyWith({
    int? id,
    String? name,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
