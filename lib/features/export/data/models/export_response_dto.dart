/// DTO for export response
/// Matches Laravel API specification for export endpoints
/// API returns: { "success": true, "data": { "id": 1, "format": "pdf", "status": "processing", "download_url": null } }
class ExportResponseDto {
  final int id;
  final String format;
  final String status;
  final String? downloadUrl;

  ExportResponseDto({
    required this.id,
    required this.format,
    required this.status,
    this.downloadUrl,
  });

  factory ExportResponseDto.fromJson(Map<String, dynamic> json) {
    // Handle both direct data and nested data structure
    final data = json['data'] ?? json;
    
    return ExportResponseDto(
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
}
