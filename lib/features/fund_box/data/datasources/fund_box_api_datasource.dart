import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/services/role_service.dart';
import '../models/fund_box_dto.dart';

/// API data source for fund box operations
/// Handles all fund box API communication with Laravel backend
/// Supports multi-currency balances (USD, SYP, TRY)
abstract class FundBoxApiDataSource {
  /// Get fund box data from API
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// If null, returns all currency balances
  /// Throws [ApiException] if operation fails
  Future<FundBoxDto> getFundBox({String? currency});

  /// Get calculated balance from transactions (real-time calculation)
  /// Returns balance calculated from all transactions, not from stored database value
  /// [currency] optional: 'USD', 'SYP', or 'TRY' to get specific currency balance
  /// If null, returns all currency balances
  /// Available to all authenticated users (SuperAdmin, Admin, and Regular Users)
  /// Throws [ApiException] if operation fails
  Future<FundBoxDto> getCalculatedBalance({String? currency});

  /// Update fund box balance via API
  /// Supports multi-currency updates
  /// Throws [ApiException] if operation fails
  Future<FundBoxDto> updateFundBox({
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
  });
}

/// Implementation of FundBoxApiDataSource
class FundBoxApiDataSourceImpl implements FundBoxApiDataSource {
  final ApiClient apiClient;
  final RoleService roleService;

  FundBoxApiDataSourceImpl({
    required this.apiClient,
    required this.roleService,
  });

  @override
  Future<FundBoxDto> getFundBox({String? currency}) async {
    try {
      // Check user role to determine which endpoint to use
      final isUserAdmin = await roleService.isAdmin();
      
      // Build URL with currency query parameter if provided
      String buildUrl(String basePath) {
        String url = basePath;
        if (currency != null && currency.isNotEmpty) {
          url += '?currency=$currency';
        }
        return url;
      }
      
      // Try appropriate endpoint based on user role
      String url;
      if (isUserAdmin) {
        // Admin users use the standard endpoint
        url = buildUrl('/fund-box');
        print('[FundBoxApiDataSource] Admin user - fetching from: $url');
      } else {
        // Regular users: try user-specific endpoint first
        // If backend doesn't support it, it will fall back to standard endpoint
        url = buildUrl('/users/fund-box');
        print('[FundBoxApiDataSource] Regular user - fetching from: $url');
      }
      
      print('[FundBoxApiDataSource] Making GET request to: $url');
      final response = await apiClient.get(url);
      print('[FundBoxApiDataSource] Response status: ${response.statusCode}');
      print('[FundBoxApiDataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('[FundBoxApiDataSource] Full response.data: $responseData');
        print('[FundBoxApiDataSource] response.data type: ${responseData.runtimeType}');
        
        // Handle both nested 'data' structure and direct data
        Map<String, dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'] as Map<String, dynamic>;
          print('[FundBoxApiDataSource] Extracted nested data: $data');
        } else if (responseData is Map<String, dynamic>) {
          data = responseData;
          print('[FundBoxApiDataSource] Using response.data directly: $data');
        } else {
          throw ApiException(
            statusCode: 200,
            message: 'Invalid response format: expected Map but got ${responseData.runtimeType}',
          );
        }
        
        print('[FundBoxApiDataSource] Parsing DTO from data: $data');
        try {
          final dto = FundBoxDto.fromJson(data);
          print('[FundBoxApiDataSource] ✅ Successfully created DTO: id=${dto.id}, USD=${dto.balanceUsd}, SYP=${dto.balanceSyp}, TRY=${dto.balanceTry}');
          print('[FundBoxApiDataSource] DTO lastUpdated: ${dto.lastUpdated}');
          print('[FundBoxApiDataSource] DTO lastCalculatedAt: ${dto.lastCalculatedAt}');
          return dto;
        } catch (e, stackTrace) {
          print('[FundBoxApiDataSource] ❌ Error parsing DTO: $e');
          print('[FundBoxApiDataSource] Error type: ${e.runtimeType}');
          print('[FundBoxApiDataSource] Stack trace: $stackTrace');
          rethrow;
        }
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        // If user endpoint returns 403/404 and user is not admin, try standard endpoint as fallback
        // This handles cases where backend hasn't implemented /users/fund-box yet
        if (!isUserAdmin && url.contains('/users/')) {
          print('[FundBoxApiDataSource] User endpoint failed (${response.statusCode}), trying standard endpoint...');
          final fallbackUrl = buildUrl('/fund-box');
          try {
            final fallbackResponse = await apiClient.get(fallbackUrl);
            if (fallbackResponse.statusCode == 200) {
              final fallbackData = fallbackResponse.data['data'] as Map<String, dynamic>;
              return FundBoxDto.fromJson(fallbackData);
            }
          } catch (e) {
            print('[FundBoxApiDataSource] Fallback endpoint also failed: $e');
          }
        }
        throw ApiException(
          statusCode: response.statusCode ?? 403,
          message: response.data['message'] ?? 'Access denied. Unable to access fund box.',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get fund box',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  @override
  Future<FundBoxDto> getCalculatedBalance({String? currency}) async {
    try {
      // Build URL with currency query parameter if provided
      String buildUrl(String basePath) {
        String url = basePath;
        if (currency != null && currency.isNotEmpty) {
          url += '?currency=$currency';
        }
        return url;
      }
      
      // Use the new calculated balance endpoint
      final url = buildUrl('/calculated-balance');
      print('[FundBoxApiDataSource] Fetching calculated balance from: $url');
      
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return FundBoxDto.fromJson(data);
      } else if (response.statusCode == 401) {
        throw ApiException(
          statusCode: 401,
          message: response.data['message'] ?? 'Unauthenticated',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to get calculated balance',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  @override
  Future<FundBoxDto> updateFundBox({
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      // Add currency balances if provided
      if (balanceUsd != null) {
        body['balance_usd'] = balanceUsd;
        body['total_balance'] = balanceUsd; // For backward compatibility
      }
      if (balanceSyp != null) {
        body['balance_syp'] = balanceSyp;
      }
      if (balanceTry != null) {
        body['balance_try'] = balanceTry;
      }
      
      // Only admins can update fund box, so always use admin endpoint
      final endpoint = '/fund-box';
      print('[FundBoxApiDataSource] Updating fund box at: $endpoint');
      
      final response = await apiClient.put(
        endpoint,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return FundBoxDto.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ApiException(
          statusCode: 403,
          message: 'Access denied. Admin privileges required.',
        );
      } else if (response.statusCode == 422) {
        final errors = response.data['errors'] as Map<String, dynamic>?;
        throw ApiException(
          statusCode: 422,
          message: 'Validation error',
          errors: errors,
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode ?? 500,
          message: response.data['message'] ?? 'Failed to update fund box',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }
}
