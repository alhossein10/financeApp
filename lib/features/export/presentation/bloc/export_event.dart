import 'package:equatable/equatable.dart';

/// Base class for export events
abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request PDF export
class RequestPdfExportEvent extends ExportEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const RequestPdfExportEvent({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to request Excel export
class RequestExcelExportEvent extends ExportEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const RequestExcelExportEvent({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to check export status
class CheckExportStatusEvent extends ExportEvent {
  final String exportId;

  const CheckExportStatusEvent(this.exportId);

  @override
  List<Object?> get props => [exportId];
}

/// Event to download completed export
class DownloadExportEvent extends ExportEvent {
  final String exportId;
  final String savePath;

  const DownloadExportEvent({
    required this.exportId,
    required this.savePath,
  });

  @override
  List<Object?> get props => [exportId, savePath];
}

/// Event to cancel export
class CancelExportEvent extends ExportEvent {
  const CancelExportEvent();
}

/// Event to retry failed export
class RetryExportEvent extends ExportEvent {
  const RetryExportEvent();
}

/// Event to request invoice images export
class RequestInvoiceImagesExportEvent extends ExportEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const RequestInvoiceImagesExportEvent({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
