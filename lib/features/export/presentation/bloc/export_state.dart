import 'package:equatable/equatable.dart';

/// Base class for export states
abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ExportInitial extends ExportState {
  const ExportInitial();
}

/// Export request is being processed
class ExportRequesting extends ExportState {
  const ExportRequesting();
}

/// Export has been queued
class ExportQueued extends ExportState {
  final String exportId;
  final String status;
  final String? message;

  const ExportQueued({
    required this.exportId,
    required this.status,
    this.message,
  });

  @override
  List<Object?> get props => [exportId, status, message];
}

/// Export is being processed
class ExportProcessing extends ExportState {
  final String exportId;
  final int progress;

  const ExportProcessing({
    required this.exportId,
    required this.progress,
  });

  @override
  List<Object?> get props => [exportId, progress];
}

/// Export is ready for download
class ExportReady extends ExportState {
  final String exportId;
  final String downloadUrl;

  const ExportReady({
    required this.exportId,
    required this.downloadUrl,
  });

  @override
  List<Object?> get props => [exportId, downloadUrl];
}

/// Export is being downloaded
class ExportDownloading extends ExportState {
  final String exportId;
  final int progress;

  const ExportDownloading({
    required this.exportId,
    required this.progress,
  });

  @override
  List<Object?> get props => [exportId, progress];
}

/// Export download completed
class ExportDownloaded extends ExportState {
  final String exportId;
  final String filePath;

  const ExportDownloaded({
    required this.exportId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [exportId, filePath];
}

/// Export failed
class ExportFailed extends ExportState {
  final String message;
  final String? exportId;

  const ExportFailed({
    required this.message,
    this.exportId,
  });

  @override
  List<Object?> get props => [message, exportId];
}
