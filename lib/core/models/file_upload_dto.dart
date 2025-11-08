/// Data Transfer Object for file upload responses
class FileUploadDto {
  final int id;
  final String filename;
  final String path; // Encrypted path for download
  final String type; // 'receipt', 'invoice', 'document'
  final int size;
  final String mimeType;
  final DateTime uploadedAt;

  FileUploadDto({
    required this.id,
    required this.filename,
    required this.path,
    required this.type,
    required this.size,
    required this.mimeType,
    required this.uploadedAt,
  });

  /// Create from JSON response
  factory FileUploadDto.fromJson(Map<String, dynamic> json) {
    return FileUploadDto(
      id: json['id'] as int,
      filename: json['filename'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      mimeType: json['mime_type'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  /// Convert to JSON for requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'path': path,
      'type': type,
      'size': size,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FileUploadDto(id: $id, filename: $filename, type: $type, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FileUploadDto &&
        other.id == id &&
        other.filename == filename &&
        other.path == path &&
        other.type == type &&
        other.size == size &&
        other.mimeType == mimeType &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      filename,
      path,
      type,
      size,
      mimeType,
      uploadedAt,
    );
  }
}

/// Valid file types for upload
enum FileType {
  receipt('receipt'),
  invoice('invoice'),
  document('document');

  final String value;
  const FileType(this.value);

  static FileType fromString(String value) {
    return FileType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid file type: $value'),
    );
  }
}
