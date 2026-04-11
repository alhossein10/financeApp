/// Department Data Transfer Object
/// 
/// Represents a department within an organization from the public API endpoint.
/// This is a public endpoint that doesn't require authentication.
class DepartmentDto {
  final int id;
  final int organizationId;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DepartmentDto({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Create DepartmentDto from JSON
  factory DepartmentDto.fromJson(Map<String, dynamic> json) {
    return DepartmentDto(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert DepartmentDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DepartmentDto(id: $id, organizationId: $organizationId, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DepartmentDto &&
        other.id == id &&
        other.organizationId == organizationId &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        organizationId.hashCode ^
        name.hashCode ^
        description.hashCode;
  }
}
