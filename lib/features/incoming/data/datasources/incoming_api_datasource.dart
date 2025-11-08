import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/incoming_dto.dart';

/// API data source for incoming operations
abstract class IncomingApiDataSource {
  /// Get incoming transactions with pagination and filters
  /// Throws [ApiException] if the request fails
  Future<IncomingListResponse> getIncoming({
    int page = 1,
    int perPage = 15,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get a single incoming transaction by ID
  /// Throws [ApiException] if the request fails
  Future<IncomingDto> getIncomingById(int id);

  /// Create a new incoming transaction
  /// Throws [ApiException] if the request fails
  Future<IncomingDto> createIncoming(IncomingDto incoming);

  /// Update an existing incoming transaction
  /// Throws [ApiException] if the request fails
  Future<IncomingDto> updateIncoming(int id, IncomingDto incoming);

  /// Delete an incoming transaction
  /// Throws [ApiException] if the request fails
  Future<void> deleteIncoming(int id);
}

class IncomingApiDataSourceImpl implements IncomingApiDataSource {
  final ApiClient apiClient;

  IncomingApiDataSourceImpl({required this.apiClient});

  @override
  Future<IncomingListResponse> getIncoming({
    int page = 1,
    int perPage = 15,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (startDate != null) {
        // Format as YYYY-MM-DD
        queryParams['date_from'] = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      }

      if (endDate != null) {
        // Format as YYYY-MM-DD
        queryParams['date_to'] = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }

      final response = await apiClient.get(
        '/incoming',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        return IncomingListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw ApiException(
          message: 'Failed to fetch incoming transactions',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch incoming transactions: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IncomingDto> getIncomingById(int id) async {
    try {
      final response = await apiClient.get('/incoming/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return IncomingDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to fetch incoming transaction',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch incoming transaction: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IncomingDto> createIncoming(IncomingDto incoming) async {
    try {
      // Validate payment method before sending
      incoming.validate();
      
      final body = incoming.toJson();
      
      final response = await apiClient.post(
        '/incoming',
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return IncomingDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to create incoming transaction',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create incoming transaction: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<IncomingDto> updateIncoming(int id, IncomingDto incoming) async {
    try {
      // Validate payment method before sending
      incoming.validate();
      
      final body = incoming.toJson();
      
      final response = await apiClient.put(
        '/incoming/$id',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return IncomingDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to update incoming transaction',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update incoming transaction: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteIncoming(int id) async {
    try {
      final response = await apiClient.delete('/incoming/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Failed to delete incoming transaction',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete incoming transaction: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
