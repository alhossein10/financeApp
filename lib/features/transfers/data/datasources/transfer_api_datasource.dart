import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/exchange_dto.dart';
import '../models/transfer_dto.dart';

/// API data source for transfer operations
abstract class TransferApiDataSource {
  /// Get transfers with pagination and filters
  /// Throws [ApiException] if the request fails
  Future<TransferListResponse> getTransfers({
    int page = 1,
    int perPage = 15,
    DateTime? startDate,
    DateTime? endDate,
    int? recipientUserId,
  });

  /// Get a single transfer by ID
  /// Throws [ApiException] if the request fails
  Future<TransferDto> getTransfer(int id);

  /// Create a new transfer
  /// Throws [ApiException] if the request fails
  Future<TransferDto> createTransfer(TransferDto transfer);

  /// Update an existing transfer
  /// Throws [ApiException] if the request fails
  Future<TransferDto> updateTransfer(int id, TransferDto transfer);

  /// Delete a transfer
  /// Throws [ApiException] if the request fails
  Future<void> deleteTransfer(int id);

  /// Add exchange information to a transfer
  /// Throws [ApiException] if the request fails
  Future<ExchangeDto> addExchange(int transferId, ExchangeDto exchange);
}

class TransferApiDataSourceImpl implements TransferApiDataSource {
  final ApiClient apiClient;

  TransferApiDataSourceImpl({required this.apiClient});

  @override
  Future<TransferListResponse> getTransfers({
    int page = 1,
    int perPage = 15,
    DateTime? startDate,
    DateTime? endDate,
    int? recipientUserId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (startDate != null) {
        queryParams['date_from'] = DateFormatter.toApiDate(startDate);
      }

      if (endDate != null) {
        queryParams['date_to'] = DateFormatter.toApiDate(endDate);
      }

      if (recipientUserId != null) {
        queryParams['recipient_user_id'] = recipientUserId;
      }

      print('[TransferApiDataSource] 📡 Requesting transfers from API');
      print('[TransferApiDataSource]    Endpoint: /transfers');
      print('[TransferApiDataSource]    Query params: $queryParams');
      print('[TransferApiDataSource]    Full URL will include: ?page=$page&per_page=$perPage');

      final response = await apiClient.get(
        '/transfers',
        queryParams: queryParams,
      );

      print('[TransferApiDataSource] 📥 Response received:');
      print('[TransferApiDataSource]    Status: ${response.statusCode}');
      print('[TransferApiDataSource]    Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        
        print('[TransferApiDataSource] 🔍 Parsing response...');
        print('[TransferApiDataSource]    Has success key: ${responseData.containsKey('success')}');
        print('[TransferApiDataSource]    Has data key: ${responseData.containsKey('data')}');
        print('[TransferApiDataSource]    Has meta key: ${responseData.containsKey('meta')}');
        
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            print('[TransferApiDataSource]    Data is List with ${data.length} items');
          } else {
            print('[TransferApiDataSource]    Data type: ${data.runtimeType}');
          }
        }
        
        final parsed = TransferListResponse.fromJson(responseData);
        print('[TransferApiDataSource] ✅ Parsed response: ${parsed.data.length} transfers, total: ${parsed.total}');
        
        if (parsed.data.isEmpty && parsed.total == 0) {
          print('[TransferApiDataSource] ⚠️ WARNING: API returned empty array but transfers exist in database!');
          print('[TransferApiDataSource] ⚠️ This indicates a backend filtering issue:');
          print('[TransferApiDataSource] ⚠️ 1. Check if transfers have admin_group_id = NULL');
          print('[TransferApiDataSource] ⚠️ 2. Check if authenticated user has matching admin_group_id');
          print('[TransferApiDataSource] ⚠️ 3. Check backend API filtering logic in TransferController');
        }
        
        return parsed;
      } else {
        print('[TransferApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch transfers',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[TransferApiDataSource] ❌ ApiException: ${e.message} (status: ${e.statusCode})');
      rethrow;
    } catch (e, stackTrace) {
      print('[TransferApiDataSource] ❌ Unexpected error: $e');
      print('[TransferApiDataSource]    Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch transfers: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransferDto> getTransfer(int id) async {
    try {
      final response = await apiClient.get('/transfers/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return TransferDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to fetch transfer',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch transfer: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransferDto> createTransfer(TransferDto transfer) async {
    try {
      print('[TransferApiDataSource] 📤 Creating transfer...');
      print('[TransferApiDataSource]    Recipient: ${transfer.recipientName}');
      print('[TransferApiDataSource]    Amount USD: ${transfer.amountUsd}');
      print('[TransferApiDataSource]    Recipient User ID: ${transfer.recipientUserId}');
      print('[TransferApiDataSource]    Admin Group ID: ${transfer.adminGroupId}');
      
      // Build request body with correct field mappings
      final body = <String, dynamic>{
        'recipient_name': transfer.recipientName,
        'amount_usd': transfer.amountUsd,
        'transfer_date': transfer.transferDate, // Already in YYYY-MM-DD format
      };
      
      // Add recipient_user_id if present (required for SuperAdmin transfers to admins)
      if (transfer.recipientUserId != null) {
        body['recipient_user_id'] = transfer.recipientUserId;
        print('[TransferApiDataSource]    ✅ Including recipient_user_id: ${transfer.recipientUserId}');
      } else {
        print('[TransferApiDataSource]    ⚠️ WARNING: recipient_user_id is NULL - backend should set admin_group_id from recipient');
      }
      
      // Add admin_group_id if present (should be set from recipient's admin_group_id for SuperAdmin transfers)
      // Note: Backend should also set this automatically from recipient_user_id, but we send it explicitly as a workaround
      if (transfer.adminGroupId != null) {
        body['admin_group_id'] = transfer.adminGroupId;
        print('[TransferApiDataSource]    ✅ Including admin_group_id: ${transfer.adminGroupId}');
      } else {
        print('[TransferApiDataSource]    ⚠️ WARNING: admin_group_id is NULL - backend MUST set this from recipient_user_id');
      }
      
      // Add optional notes if present
      if (transfer.notes != null && transfer.notes!.isNotEmpty) {
        body['notes'] = transfer.notes!;
      }

      print('[TransferApiDataSource]    Request body: $body');

      final response = await apiClient.post(
        '/transfers',
        body: body,
      );

      print('[TransferApiDataSource] 📥 Response received:');
      print('[TransferApiDataSource]    Status: ${response.statusCode}');
      print('[TransferApiDataSource]    Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final createdTransfer = TransferDto.fromJson(data['data'] as Map<String, dynamic>);
        
        print('[TransferApiDataSource] ✅ Transfer created successfully');
        print('[TransferApiDataSource]    Created transfer ID: ${createdTransfer.id}');
        print('[TransferApiDataSource]    Created transfer admin_group_id: ${createdTransfer.adminGroupId}');
        
        if (createdTransfer.adminGroupId == null) {
          print('[TransferApiDataSource] ⚠️ WARNING: Created transfer has admin_group_id = NULL');
          print('[TransferApiDataSource] ⚠️ This transfer may not appear in transfer list due to backend filtering');
        }
        
        return createdTransfer;
      } else {
        print('[TransferApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to create transfer',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[TransferApiDataSource] ❌ ApiException: ${e.message} (status: ${e.statusCode})');
      rethrow;
    } catch (e, stackTrace) {
      print('[TransferApiDataSource] ❌ Unexpected error: $e');
      print('[TransferApiDataSource]    Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to create transfer: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransferDto> updateTransfer(int id, TransferDto transfer) async {
    try {
      // Build request body with correct field mappings
      final body = <String, dynamic>{
        'recipient_name': transfer.recipientName,
        'amount_usd': transfer.amountUsd,
        'transfer_date': transfer.transferDate, // Already in YYYY-MM-DD format
      };
      
      // Add optional notes if present
      if (transfer.notes != null && transfer.notes!.isNotEmpty) {
        body['notes'] = transfer.notes!;
      }

      final response = await apiClient.put(
        '/transfers/$id',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return TransferDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to update transfer',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update transfer: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTransfer(int id) async {
    try {
      final response = await apiClient.delete('/transfers/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Failed to delete transfer',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete transfer: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExchangeDto> addExchange(int transferId, ExchangeDto exchange) async {
    try {
      final response = await apiClient.post(
        '/transfers/$transferId/exchange',
        body: exchange.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ExchangeDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to add exchange',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to add exchange: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
