import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/export_api_datasource.dart';
import 'export_event.dart';
import 'export_state.dart';

/// BLoC for managing export operations
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportApiDataSource exportApiDataSource;
  Timer? _statusPollTimer;
  String? _currentExportId;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;
  bool _lastWasPdf = true;

  ExportBloc({
    required this.exportApiDataSource,
  }) : super(const ExportInitial()) {
    on<RequestPdfExportEvent>(_onRequestPdfExport);
    on<RequestExcelExportEvent>(_onRequestExcelExport);
    on<CheckExportStatusEvent>(_onCheckExportStatus);
    on<DownloadExportEvent>(_onDownloadExport);
    on<CancelExportEvent>(_onCancelExport);
    on<RetryExportEvent>(_onRetryExport);
  }

  /// Handle PDF export request
  Future<void> _onRequestPdfExport(
    RequestPdfExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    emit(const ExportRequesting());

    try {
      // Store request details for retry
      _lastStartDate = event.startDate;
      _lastEndDate = event.endDate;
      _lastWasPdf = true;

      final response = await exportApiDataSource.exportExpensesToPdf(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      _currentExportId = response.exportId;

      // Check if export is already completed (synchronous processing)
      if (response.status == 'completed' && response.downloadUrl != null) {
        emit(ExportReady(
          exportId: response.exportId,
          downloadUrl: response.downloadUrl!,
        ));
      } else {
        emit(ExportQueued(
          exportId: response.exportId,
          status: response.status,
          message: 'Export request submitted',
        ));

        // Start polling for status if processing
        if (response.status == 'processing') {
          _startStatusPolling(response.exportId);
        }
      }
    } catch (e) {
      emit(ExportFailed(message: e.toString()));
    }
  }

  /// Handle Excel export request
  Future<void> _onRequestExcelExport(
    RequestExcelExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    emit(const ExportRequesting());

    try {
      // Store request details for retry
      _lastStartDate = event.startDate;
      _lastEndDate = event.endDate;
      _lastWasPdf = false;

      final response = await exportApiDataSource.exportExpensesToExcel(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      _currentExportId = response.exportId;

      // Check if export is already completed (synchronous processing)
      if (response.status == 'completed' && response.downloadUrl != null) {
        emit(ExportReady(
          exportId: response.exportId,
          downloadUrl: response.downloadUrl!,
        ));
      } else {
        emit(ExportQueued(
          exportId: response.exportId,
          status: response.status,
          message: 'Export request submitted',
        ));

        // Start polling for status if processing
        if (response.status == 'processing') {
          _startStatusPolling(response.exportId);
        }
      }
    } catch (e) {
      emit(ExportFailed(message: e.toString()));
    }
  }

  /// Handle export status check
  Future<void> _onCheckExportStatus(
    CheckExportStatusEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      final status = await exportApiDataSource.getExportStatus(event.exportId);

      if (status.isCompleted) {
        _stopStatusPolling();
        emit(ExportReady(
          exportId: status.exportId,
          downloadUrl: status.downloadUrl ?? '',
        ));
      } else if (status.isFailed) {
        _stopStatusPolling();
        emit(ExportFailed(
          message: status.errorMessage ?? 'Export failed',
          exportId: status.exportId,
        ));
      } else if (status.isProcessing) {
        emit(ExportProcessing(
          exportId: status.exportId,
          progress: status.progress ?? 0,
        ));
      }
    } catch (e) {
      _stopStatusPolling();
      emit(ExportFailed(
        message: e.toString(),
        exportId: event.exportId,
      ));
    }
  }

  /// Handle export download
  Future<void> _onDownloadExport(
    DownloadExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportDownloading(
      exportId: event.exportId,
      progress: 0,
    ));

    try {
      final filePath = await exportApiDataSource.downloadExport(
        event.exportId,
        event.savePath,
      );

      emit(ExportDownloaded(
        exportId: event.exportId,
        filePath: filePath,
      ));

      // Reset current export ID
      _currentExportId = null;
    } catch (e) {
      emit(ExportFailed(
        message: e.toString(),
        exportId: event.exportId,
      ));
    }
  }

  /// Handle export cancellation
  Future<void> _onCancelExport(
    CancelExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    _stopStatusPolling();
    _currentExportId = null;
    emit(const ExportInitial());
  }

  /// Handle export retry
  Future<void> _onRetryExport(
    RetryExportEvent event,
    Emitter<ExportState> emit,
  ) async {
    if (_lastWasPdf) {
      add(RequestPdfExportEvent(
        startDate: _lastStartDate,
        endDate: _lastEndDate,
      ));
    } else {
      add(RequestExcelExportEvent(
        startDate: _lastStartDate,
        endDate: _lastEndDate,
      ));
    }
  }

  /// Start polling for export status
  void _startStatusPolling(String exportId) {
    _stopStatusPolling();

    _statusPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        add(CheckExportStatusEvent(exportId));
      },
    );
  }

  /// Stop polling for export status
  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  @override
  Future<void> close() {
    _stopStatusPolling();
    return super.close();
  }
}
