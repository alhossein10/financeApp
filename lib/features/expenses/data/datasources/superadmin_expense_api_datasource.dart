import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/superadmin_expense_view_dto.dart';
import '../models/expense_dto.dart';

/// API data source for SuperAdmin expense operations
abstract class SuperAdminExpenseApiDataSource {
  /// Get aggregated expense summary across all admin groups
  /// Throws [ApiException] if the request fails
  Future<SuperAdminExpenseViewDto> getExpenseSummary();

  /// Get expenses for a specific admin group
  /// Throws [ApiException] if the request fails
  Future<ExpenseListResponse> getExpensesByGroup(
    String groupId, {
    int page = 1,
    int perPage = 50,
  });
}

class SuperAdminExpenseApiDataSourceImpl implements SuperAdminExpenseApiDataSource {
  final ApiClient apiClient;

  SuperAdminExpenseApiDataSourceImpl({required this.apiClient});

  @override
  Future<SuperAdminExpenseViewDto> getExpenseSummary() async {
    try {
      print('[SuperAdminExpenseApiDataSource] Fetching expense summary...');
      
      final response = await apiClient.get('/superadmin/expenses/summary');

      print('[SuperAdminExpenseApiDataSource] Response status: ${response.statusCode}');
      print('[SuperAdminExpenseApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (data.containsKey('data')) {
          print('[SuperAdminExpenseApiDataSource] ✅ Summary fetched successfully (wrapped response)');
          return SuperAdminExpenseViewDto.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // Response is not wrapped, use directly
          print('[SuperAdminExpenseApiDataSource] ✅ Summary fetched successfully (direct response)');
          return SuperAdminExpenseViewDto.fromJson(data);
        }
      } else if (response.statusCode == 404) {
        // Backend endpoint not implemented yet - return empty data
        print('[SuperAdminExpenseApiDataSource] ⚠️ Endpoint not found (404) - Backend not implemented yet');
        print('[SuperAdminExpenseApiDataSource] ℹ️ Returning empty data structure');
        
        // Return empty data structure
        return const SuperAdminExpenseViewDto(
          groupSummaries: [],
          grandTotal: 0.0,
          totalExpenseCount: 0,
        );
      } else {
        print('[SuperAdminExpenseApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch expense summary',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      // If it's a 404, handle gracefully
      if (e.statusCode == 404) {
        print('[SuperAdminExpenseApiDataSource] ⚠️ Endpoint not found (404) - Backend not implemented yet');
        return const SuperAdminExpenseViewDto(
          groupSummaries: [],
          grandTotal: 0.0,
          totalExpenseCount: 0,
        );
      }
      print('[SuperAdminExpenseApiDataSource] ❌ ApiException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('[SuperAdminExpenseApiDataSource] ❌ Unexpected error: $e');
      print('[SuperAdminExpenseApiDataSource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch expense summary: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseListResponse> getExpensesByGroup(
    String groupId, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('[SuperAdminExpenseApiDataSource] Fetching expenses for group $groupId...');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      final response = await apiClient.get(
        '/superadmin/expenses/by-group/$groupId',
        queryParams: queryParams,
      );

      print('[SuperAdminExpenseApiDataSource] Response status: ${response.statusCode}');
      print('[SuperAdminExpenseApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Handle both wrapped and unwrapped responses
        if (responseData.containsKey('success') && responseData['success'] == true) {
          // Response is wrapped with success flag
          print('[SuperAdminExpenseApiDataSource] ✅ Expenses fetched successfully (wrapped response)');
          return ExpenseListResponse.fromJson(responseData);
        } else {
          // Direct response
          print('[SuperAdminExpenseApiDataSource] ✅ Expenses fetched successfully (direct response)');
          return ExpenseListResponse.fromJson(responseData);
        }
      } else if (response.statusCode == 404) {
        // Backend endpoint not implemented yet - return empty data
        print('[SuperAdminExpenseApiDataSource] ⚠️ Endpoint not found (404) - Backend not implemented yet');
        print('[SuperAdminExpenseApiDataSource] ℹ️ Returning empty expense list');
        
        // Return empty expense list
        return ExpenseListResponse(
          data: const [],
          currentPage: page,
          perPage: perPage,
          total: 0,
          lastPage: 1,
        );
      } else {
        print('[SuperAdminExpenseApiDataSource] ❌ Failed with status ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch expenses for group',
          statusCode: response.statusCode,
        );
      }
    } on ApiException catch (e) {
      // If it's a 404, handle gracefully
      if (e.statusCode == 404) {
        print('[SuperAdminExpenseApiDataSource] ⚠️ Endpoint not found (404) - Backend not implemented yet');
        return ExpenseListResponse(
          data: const [],
          currentPage: page,
          perPage: perPage,
          total: 0,
          lastPage: 1,
        );
      }
      print('[SuperAdminExpenseApiDataSource] ❌ ApiException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('[SuperAdminExpenseApiDataSource] ❌ Unexpected error: $e');
      print('[SuperAdminExpenseApiDataSource] Stack trace: $stackTrace');
      throw ApiException(
        message: 'Failed to fetch expenses for group: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
