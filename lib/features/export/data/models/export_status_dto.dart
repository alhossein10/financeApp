import '../../../../core/utils/date_formatter.dart';

/// DTO for export status
/// Matches Laravel API specification for export status endpoint
/// Note: The API may not have a dedicated status endpoint, so this uses the same structure as ExportResponseDto
class ExportStatusDto {
  final int id;
  final String format;
  final String status;
  final String? downloadUrl;
  final int? progress;
  final String? errorMessage;
  final DateTime? completedAt;
  final DateTime? createdAt;

  ExportStatusDto({
    required this.id,
    required this.format,
    required this.status,
    this.downloadUrl,
    this.progress,
    this.errorMessage,
    this.completedAt,
    this.createdAt,
  });

  factory ExportStatusDto.fromJson(Map<String, dynamic> json) {
    // Handle both direct data and nested data structure
    final data = json['data'] ?? json;
    
    return ExportStatusDto(
      id: data['id'] as int,
      format: data['format'] as String,
      status: data['status'] as String,
      downloadUrl: data['download_url'] as String?,
      progress: data['progress'] as int?,
      errorMessage: data['error_message'] as String?,
      completedAt: DateFormatter.fromApiTimestampNullable(data['completed_at'] as String?),
      createdAt: DateFormatter.fromApiTimestampNullable(data['created_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format,
      'status': status,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (progress != null) 'progress': progress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (completedAt != null) 'completed_at': DateFormatter.toApiTimestamp(completedAt!),
      if (createdAt != null) 'created_at': DateFormatter.toApiTimestamp(createdAt!),
    };
  }

  // Convenience getter for exportId as string (for compatibility)
  String get exportId => id.toString();

  bool get isProcessing => status == 'processing' || status == 'queued';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
