import 'dart:io';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../domain/entities/expense.dart';
import '../models/expense_dto.dart';

// Export ExpenseListResponse for use in other files
export '../models/expense_dto.dart' show ExpenseListResponse;

/// API data source for expense operations
abstract class ExpenseApiDataSource {
  /// Get expenses with pagination and filters
  /// Throws [ApiException] if the request fails
  Future<ExpenseListResponse> getExpenses({
    int page = 1,
    int perPage = 15,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    SyncStatus? syncStatus,
  });

  /// Get a single expense by ID
  /// Throws [ApiException] if the request fails
  Future<ExpenseDto> getExpense(int id);

  /// Create a new expense
  /// Throws [ApiException] if the request fails
  Future<ExpenseDto> createExpense(ExpenseDto expense, {File? photoFile});

  /// Update an existing expense
  /// Throws [ApiException] if the request fails
  Future<ExpenseDto> updateExpense(int id, ExpenseDto expense, {File? photoFile});

  /// Delete an expense
  /// Throws [ApiException] if the request fails
  Future<void> deleteExpense(int id);
}

class ExpenseApiDataSourceImpl implements ExpenseApiDataSource {
  final ApiClient apiClient;

  ExpenseApiDataSourceImpl({required this.apiClient});

  @override
  Future<ExpenseListResponse> getExpenses({
    int page = 1,
    int perPage = 100,  // Increased from 15 to show more expenses
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    SyncStatus? syncStatus,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      // Add category filter if provided
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      // Use date_from and date_to parameters as per Laravel API spec
      if (startDate != null) {
        queryParams['date_from'] = _formatDate(startDate);
      }

      if (endDate != null) {
        queryParams['date_to'] = _formatDate(endDate);
      }

      // Note: syncStatus is not supported by Laravel API, it's a local-only filter

      print('[ExpenseApiDataSource] 📡 Requesting expenses from API');
      print('[ExpenseApiDataSource]    Endpoint: /expenses');
      print('[ExpenseApiDataSource]    Query params: $queryParams');
      print('[ExpenseApiDataSource]    Full URL will include: ?page=$page&per_page=$perPage');

      final response = await apiClient.get(
        '/expenses',
        queryParams: queryParams,
      );

      print('[ExpenseApiDataSource] 📥 Response received:');
      print('[ExpenseApiDataSource]    Status: ${response.statusCode}');
      print('[ExpenseApiDataSource]    Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        
        print('[ExpenseApiDataSource] 🔍 Parsing response...');
        print('[ExpenseApiDataSource]    Has success key: ${responseData.containsKey('success')}');
        print('[ExpenseApiDataSource]    Has data key: ${responseData.containsKey('data')}');
        print('[ExpenseApiDataSource]    Has meta key: ${responseData.containsKey('meta')}');
        
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            print('[ExpenseApiDataSource]    Data is List with ${data.length} items');
          } else {
            print('[ExpenseApiDataSource]    Data type: ${data.runtimeType}');
          }
        }
        
        // Handle both wrapped and unwrapped responses
        if (responseData.containsKey('success') && responseData['success'] == true) {
          // Response is wrapped with success flag
          final parsed = ExpenseListResponse.fromJson(responseData);
          print('[ExpenseApiDataSource] ✅ Parsed response: ${parsed.data.length} expenses, total: ${parsed.total}');
          return parsed;
        } else {
          // Direct response
          final parsed = ExpenseListResponse.fromJson(responseData);
          print('[ExpenseApiDataSource] ✅ Parsed response: ${parsed.data.length} expenses, total: ${parsed.total}');
          return parsed;
        }
      } else {
        print('[ExpenseApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch expenses',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[ExpenseApiDataSource] ❌ ApiException: ${e.message} (status: ${e.statusCode})');
      rethrow;
    } catch (e, stackTrace) {
      print('[ExpenseApiDataSource] ❌ Unexpected error: $e');
      print('[ExpenseApiDataSource]    Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch expenses: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Format date to YYYY-MM-DD for API requests
  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<ExpenseDto> getExpense(int id) async {
    try {
      final response = await apiClient.get('/expenses/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ExpenseDto.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to fetch expense',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch expense: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseDto> createExpense(ExpenseDto expense, {File? photoFile}) async {
    try {
      print('[ExpenseApiDataSource] Creating expense...');
      print('[ExpenseApiDataSource]   Description: ${expense.description}');
      print('[ExpenseApiDataSource]   USD: ${expense.priceUsd}, SYP: ${expense.priceSyp}, TRY: ${expense.priceTry}');
      print('[ExpenseApiDataSource]   Has photo: ${photoFile != null}');
      
      // Validate payment method before sending to API
      expense.validate();
      print('[ExpenseApiDataSource] ✅ Validation passed');
      
      final response = photoFile != null
          ? await apiClient.uploadFile(
              '/expenses',
              photoFile,
              fields: expense.toFormData(),
              fileFieldName: 'photo',
            )
          : await apiClient.post(
              '/expenses',
              body: expense.toJson(),
            );

      print('[ExpenseApiDataSource] Response status: ${response.statusCode}');
      print('[ExpenseApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (data.containsKey('data')) {
          print('[ExpenseApiDataSource] ✅ Expense created successfully (wrapped response)');
          return ExpenseDto.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // Response is not wrapped, use directly
          print('[ExpenseApiDataSource] ✅ Expense created successfully (direct response)');
          return ExpenseDto.fromJson(data);
        }
      } else {
        print('[ExpenseApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to create expense',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      print('[ExpenseApiDataSource] ❌ ApiException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('[ExpenseApiDataSource] ❌ Unexpected error: $e');
      print('[ExpenseApiDataSource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to create expense: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseDto> updateExpense(int id, ExpenseDto expense, {File? photoFile}) async {
    try {
      // Validate payment method before sending to API
      expense.validate();
      
      final response = photoFile != null
          ? await apiClient.uploadFile(
              '/expenses/$id',
              photoFile,
              fields: {
                ...expense.toFormData(),
                '_method': 'PUT', // Laravel method spoofing for file uploads
              },
              fileFieldName: 'photo',
            )
          : await apiClient.put(
              '/expenses/$id',
              body: expense.toJson(),
            );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (data.containsKey('data')) {
          return ExpenseDto.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // Response is not wrapped, use directly
          return ExpenseDto.fromJson(data);
        }
      } else {
        throw ApiException(
          message: 'Failed to update expense',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update expense: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteExpense(int id) async {
    try {
      final response = await apiClient.delete('/expenses/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Failed to delete expense',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete expense: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
