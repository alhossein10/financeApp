import '../../../../core/utils/date_formatter.dart';

/// DTO for export request
/// Matches Laravel API specification for /export/expenses/pdf and /export/expenses/excel
class ExportRequestDto {
  final DateTime? startDate;
  final DateTime? endDate;
  final String format;

  ExportRequestDto({
    this.startDate,
    this.endDate,
    required this.format,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      if (startDate != null) 'date_from': DateFormatter.toApiDate(startDate!),
      if (endDate != null) 'date_to': DateFormatter.toApiDate(endDate!),
    };
  }
}
