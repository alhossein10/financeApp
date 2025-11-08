/// Main Export DTO that matches Laravel API specification
/// Used for both request responses and status checks
/// API Response: { "success": true, "data": { "id": 1, "format": "pdf", "status": "processing", "download_url": null } }
class ExportDto {
  final int id;
  final String format;
  final String status;
  final String? downloadUrl;

  ExportDto({
    required this.id,
    required this.format,
    required this.status,
    this.downloadUrl,
  });

  factory ExportDto.fromJson(Map<String, dynamic> json) {
    // Handle both direct data and nested data structure
    final data = json['data'] ?? json;
    
    return ExportDto(
      id: data['id'] as int,
      format: data['format'] as String,
      status: data['status'] as String,
      downloadUrl: data['download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format,
      'status': status,
      if (downloadUrl != null) 'download_url': downloadUrl,
    };
  }

  // Convenience getter for exportId as string (for compatibility)
  String get exportId => id.toString();

  // Status helpers
  bool get isProcessing => status == 'processing' || status == 'queued';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  // Copy with method for updates
  ExportDto copyWith({
    int? id,
    String? format,
    String? status,
    String? downloadUrl,
  }) {
    return ExportDto(
      id: id ?? this.id,
      format: format ?? this.format,
      status: status ?? this.status,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
