/// Organization Data Transfer Object
/// 
/// Represents an organization from the public API endpoint.
/// This is a public endpoint that doesn't require authentication.
class OrganizationDto {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationDto({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Create OrganizationDto from JSON
  factory OrganizationDto.fromJson(Map<String, dynamic> json) {
    return OrganizationDto(
      id: json['id'] as int,
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

  /// Convert OrganizationDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'OrganizationDto(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrganizationDto &&
        other.id == id &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ description.hashCode;
  }
}
