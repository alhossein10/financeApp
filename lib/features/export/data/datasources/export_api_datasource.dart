import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/export_request_dto.dart';
import '../models/export_response_dto.dart';
import '../models/export_status_dto.dart';

/// API data source for export operations
/// Implements Laravel API specification for data export endpoints
abstract class ExportApiDataSource {
  /// Request PDF export of expenses
  /// POST /export/expenses/pdf
  Future<ExportResponseDto> exportExpensesToPdf({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Request Excel export of expenses
  /// POST /export/expenses/excel
  Future<ExportResponseDto> exportExpensesToExcel({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get export status (if available)
  /// Note: The API may not have a dedicated status endpoint
  /// This method may need to be implemented differently
  Future<ExportStatusDto> getExportStatus(String exportId);

  /// Download completed export
  /// GET /export/{id}/download
  Future<String> downloadExport(String exportId, String savePath);
}

/// Implementation of ExportApiDataSource
/// Implements Laravel API specification for data export
class ExportApiDataSourceImpl implements ExportApiDataSource {
  final ApiClient apiClient;

  ExportApiDataSourceImpl({required this.apiClient});

  @override
  Future<ExportResponseDto> exportExpensesToPdf({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = ExportRequestDto(
        startDate: startDate,
        endDate: endDate,
        format: 'pdf',
      ).toJson();

      final response = await apiClient.post(
        '/export/expenses/pdf',
        body: body,
      );

      return ExportResponseDto.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Failed to request PDF export: $e',
      );
    }
  }

  @override
  Future<ExportResponseDto> exportExpensesToExcel({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = ExportRequestDto(
        startDate: startDate,
        endDate: endDate,
        format: 'excel',
      ).toJson();

      final response = await apiClient.post(
        '/export/expenses/excel',
        body: body,
      );

      return ExportResponseDto.fromJson(response.data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Failed to request Excel export: $e',
      );
    }
  }

  @override
  Future<ExportStatusDto> getExportStatus(String exportId) async {
    try {
      // Note: The Laravel API may not have a dedicated status endpoint
      // This implementation assumes the status can be checked via the same export endpoint
      // or that the export is processed synchronously
      
      // For now, we'll throw an exception indicating this feature is not available
      // The BLoC should handle this gracefully
      throw ApiException(
        statusCode: 501,
        message: 'Export status checking not implemented in API',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Failed to get export status: $e',
      );
    }
  }

  @override
  Future<String> downloadExport(String exportId, String savePath) async {
    try {
      // Download the file directly from the endpoint
      // The API returns the file directly as a file download
      // Use Dio directly to download the file with proper options
      final dio = (apiClient as dynamic).dio as Dio;
      
      await dio.download(
        '/export/$exportId/download',
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      return savePath;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Failed to download export: $e',
      );
    }
  }
}
