# Design Document: Postman API v3.1 Complete Verification

## Overview

This design document outlines the technical approach for verifying and implementing complete feature parity between the Postman API v3.1 collection and the Flutter application. The solution ensures all 12 endpoint categories are fully integrated with proper Bearer token authentication, multi-currency support, SuperAdmin features, and comprehensive error handling.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ SuperAdmin   │  │ Admin        │  │ User         │     │
│  │ UI           │  │ UI           │  │ UI           │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
├─────────────────────────────────────────────────────────────┤
│  BLoC Layer (State Management)                              │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Use Cases)                                   │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ API Datasources  │  │ Cache Datasources│               │
│  └──────────────────┘  └──────────────────┘               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  API Client   │
                    │ (with Bearer  │
                    │  Token Auth)  │
                    └───────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         Laravel Backend API v3.1 (Postman Collection)       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  12 Endpoint Categories:                             │  │
│  │  1. Public (Organizations, Departments)              │  │
│  │  2. Authentication (Register, Login, Refresh)        │  │
│  │  3. SuperAdmin (Analytics, Group Management)         │  │
│  │  4. Expenses (Multi-Currency, Invoices)              │  │
│  │  5. Transfers (SuperAdmin→Admin, Admin→User)         │  │
│  │  6. Incoming                                          │  │
│  │  7. Fund Box (Multi-Currency: USD, SYP, TRY)         │  │
│  │  8. Exchanges (Balance-Based)                        │  │
│  │  9. Admin Groups                                      │  │
│  │  10. Admin Dashboard                                  │  │
│  │  11. Audit Logs                                       │  │
│  │  12. Data Export & Sync                               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. Bearer Token Authentication System

**Purpose:** Ensure all protected endpoints include proper Bearer token authentication

**Implementation:**

```dart
class BearerTokenInterceptor extends Interceptor {
  final TokenManager tokenManager;
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }
    
    // Get current token
    final token = await tokenManager.getToken();
    
    if (token != null) {
      // Add Bearer token to Authorization header
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      final refreshed = await _refreshToken();
      
      if (refreshed) {
        // Retry original request with new token
        return handler.resolve(await _retry(err.requestOptions));
      } else {
        // Redirect to login
        await _handleLogout();
      }
    }
    
    handler.next(err);
  }
  
  bool _isPublicEndpoint(String path) {
    return path.contains('/organizations') ||
           path.contains('/auth/register') ||
           path.contains('/auth/login');
  }
}
```

### 2. SuperAdmin Features Integration

**SuperAdmin Analytics Datasource:**

```dart
class SuperAdminAnalyticsApiDatasource {
  final ApiClient apiClient;
  
  Future<SuperAdminAnalyticsDto> getAnalytics({
    required String period, // '15days', 'month', 'all'
  }) async {
    final response = await apiClient.get(
      '/super-admin/analytics',
      queryParams: {'period': period},
      // Bearer token automatically added by interceptor
    );
    
    return SuperAdminAnalyticsDto.fromJson(response.data['data']);
  }
}
```

**SuperAdmin Group Management Datasource:**

```dart
class SuperAdminGroupApiDatasource {
  final ApiClient apiClient;
  
  Future<SuperAdminGroupDto> getGroupInfo() async {
    final response = await apiClient.get('/superadmin/group');
    return SuperAdminGroupDto.fromJson(response.data['data']);
  }
  
  Future<PaginatedResponse<AdminMemberDto>> getMembers({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await apiClient.get(
      '/superadmin/group/members',
      queryParams: {'page': page, 'per_page': perPage},
    );
    
    return PaginatedResponse.fromJson(
      response.data,
      (json) => AdminMemberDto.fromJson(json),
    );
  }
  
  Future<SuperAdminGroupDto> regenerateCode() async {
    final response = await apiClient.post('/superadmin/group/regenerate-code');
    return SuperAdminGroupDto.fromJson(response.data['data']);
  }
  
  Future<void> removeMember(int adminId) async {
    await apiClient.delete('/superadmin/group/members/$adminId');
  }
}
```

### 3. Multi-Currency Fund Box Integration

**Multi-Currency Fund Box DTO:**

```dart
class MultiCurrencyFundBoxDto {
  final int id;
  final int userId;
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime lastCalculatedAt;
  final DateTime updatedAt;
  
  MultiCurrencyFundBoxDto({
    required this.id,
    required this.userId,
    required this.balanceUsd,
    required this.balanceSyp,
    required this.balanceTry,
    required this.lastCalculatedAt,
    required this.updatedAt,
  });
  
  factory MultiCurrencyFundBoxDto.fromJson(Map<String, dynamic> json) {
    return MultiCurrencyFundBoxDto(
      id: json['id'],
      userId: json['user_id'],
      balanceUsd: (json['balance_usd'] ?? 0.0).toDouble(),
      balanceSyp: (json['balance_syp'] ?? 0.0).toDouble(),
      balanceTry: (json['balance_try'] ?? 0.0).toDouble(),
      lastCalculatedAt: DateTime.parse(json['last_calculated_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
```

**Fund Box API Datasource:**

```dart
class FundBoxApiDatasource {
  final ApiClient apiClient;
  
  // Get all balances
  Future<MultiCurrencyFundBoxDto> getFundBox() async {
    final response = await apiClient.get('/fund-box');
    return MultiCurrencyFundBoxDto.fromJson(response.data['data']);
  }
  
  // Get specific currency balance
  Future<MultiCurrencyFundBoxDto> getFundBoxByCurrency(String currency) async {
    final response = await apiClient.get(
      '/fund-box',
      queryParams: {'currency': currency}, // USD, SYP, or TRY
    );
    return MultiCurrencyFundBoxDto.fromJson(response.data['data']);
  }
  
  // Admin/SuperAdmin: Get user's fund box
  Future<MultiCurrencyFundBoxDto> getUserFundBox({
    required int userId,
    String? currency,
  }) async {
    final queryParams = {'user_id': userId.toString()};
    if (currency != null) {
      queryParams['currency'] = currency;
    }
    
    final response = await apiClient.get(
      '/fund-box',
      queryParams: queryParams,
    );
    return MultiCurrencyFundBoxDto.fromJson(response.data['data']);
  }
}
```

### 4. Multi-Currency Expense Integration

**Multi-Currency Expense DTO:**

```dart
class MultiCurrencyExpenseDto {
  final int? id;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final bool hasInvoice;
  final String? invoicePath;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  MultiCurrencyExpenseDto({
    this.id,
    required this.description,
    this.priceUsd,
    this.priceSyp,
    this.priceTry,
    required this.hasInvoice,
    this.invoicePath,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory MultiCurrencyExpenseDto.fromJson(Map<String, dynamic> json) {
    return MultiCurrencyExpenseDto(
      id: json['id'],
      description: json['description'],
      priceUsd: json['price_usd']?.toDouble(),
      priceS yp: json['price_syp']?.toDouble(),
      priceTry: json['price_try']?.toDouble(),
      hasInvoice: json['has_invoice'] ?? false,
      invoicePath: json['invoice_path'],
      expenseDate: DateTime.parse(json['expense_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (priceSyp != null) 'price_syp': priceSyp,
      if (priceTry != null) 'price_try': priceTry,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
    };
  }
}
```

### 5. Balance-Based Exchange Integration

**Exchange DTO:**

```dart
class ExchangeDto {
  final int? id;
  final int? transferId; // Optional link to transfer
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double? exchangeRate;
  final double? convertedAmount;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
  
  ExchangeDto({
    this.id,
    this.transferId,
    required this.targetCurrency,
    required this.amountUsd,
    this.exchangeRate,
    this.convertedAmount,
    required this.exchangeDate,
    this.notes,
    required this.createdAt,
  });
  
  factory ExchangeDto.fromJson(Map<String, dynamic> json) {
    return ExchangeDto(
      id: json['id'],
      transferId: json['transfer_id'],
      targetCurrency: json['target_currency'],
      amountUsd: json['amount_usd'].toDouble(),
      exchangeRate: json['exchange_rate']?.toDouble(),
      convertedAmount: json['converted_amount']?.toDouble(),
      exchangeDate: DateTime.parse(json['exchange_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (transferId != null) 'transfer_id': transferId,
      'target_currency': targetCurrency,
      'amount_usd': amountUsd,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (convertedAmount != null) 'converted_amount': convertedAmount,
      'exchange_date': exchangeDate.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
    };
  }
}
```

**Exchange API Datasource:**

```dart
class ExchangeApiDatasource {
  final ApiClient apiClient;
  
  Future<ExchangeDto> createExchange(ExchangeDto exchange) async {
    final response = await apiClient.post(
      '/exchanges',
      body: exchange.toJson(),
    );
    return ExchangeDto.fromJson(response.data['data']);
  }
  
  Future<List<ExchangeDto>> getExchanges({String currency = 'all'}) async {
    final response = await apiClient.get(
      '/exchanges',
      queryParams: {'currency': currency}, // 'all', 'SYP', or 'TRY'
    );
    
    return (response.data['data'] as List)
        .map((json) => ExchangeDto.fromJson(json))
        .toList();
  }
  
  Future<ExchangeDto> getExchange(int id) async {
    final response = await apiClient.get('/exchanges/$id');
    return ExchangeDto.fromJson(response.data['data']);
  }
  
  Future<List<ExchangeDto>> getExchangesByTransfer(int transferId) async {
    final response = await apiClient.get('/exchanges/transfer/$transferId');
    return (response.data['data'] as List)
        .map((json) => ExchangeDto.fromJson(json))
        .toList();
  }
  
  Future<TransferBalanceInfoDto> getTransferBalanceInfo(int transferId) async {
    final response = await apiClient.get('/exchanges/transfer/$transferId/balance');
    return TransferBalanceInfoDto.fromJson(response.data['data']);
  }
}
```

### 6. SuperAdmin and Admin Transfer Integration

**Transfer with Recipient DTO:**

```dart
class TransferWithRecipientDto {
  final int? id;
  final int? recipientUserId; // Required for SuperAdmin→Admin and Admin→User
  final String recipientName;
  final double amountUsd;
  final DateTime transferDate;
  final String? notes;
  final DateTime createdAt;
  
  TransferWithRecipientDto({
    this.id,
    this.recipientUserId,
    required this.recipientName,
    required this.amountUsd,
    required this.transferDate,
    this.notes,
    required this.createdAt,
  });
  
  factory TransferWithRecipientDto.fromJson(Map<String, dynamic> json) {
    return TransferWithRecipientDto(
      id: json['id'],
      recipientUserId: json['recipient_user_id'],
      recipientName: json['recipient_name'],
      amountUsd: json['amount_usd'].toDouble(),
      transferDate: DateTime.parse(json['transfer_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (recipientUserId != null) 'recipient_user_id': recipientUserId,
      'recipient_name': recipientName,
      'amount_usd': amountUsd,
      'transfer_date': transferDate.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
    };
  }
}
```

### 7. Admin Group Management Integration

**Admin Group API Datasource:**

```dart
class AdminGroupApiDatasource {
  final ApiClient apiClient;
  
  // Admin endpoints
  Future<AdminGroupDto> getAdminGroupInfo() async {
    final response = await apiClient.get('/admin/group');
    return AdminGroupDto.fromJson(response.data['data']);
  }
  
  Future<List<GroupMemberDto>> getGroupMembers() async {
    final response = await apiClient.get('/admin/group/members');
    return (response.data['data'] as List)
        .map((json) => GroupMemberDto.fromJson(json))
        .toList();
  }
  
  Future<AdminGroupDto> regenerateGroupCode() async {
    final response = await apiClient.post('/admin/group/regenerate');
    return AdminGroupDto.fromJson(response.data['data']);
  }
  
  Future<void> removeGroupMember(int userId) async {
    await apiClient.delete('/admin/group/members/$userId');
  }
  
  // User endpoints
  Future<void> joinGroup(String groupCode) async {
    await apiClient.post(
      '/user/join-group',
      body: {'group_code': groupCode},
    );
  }
  
  Future<GroupInfoDto> getUserGroupInfo() async {
    final response = await apiClient.get('/user/group-info');
    return GroupInfoDto.fromJson(response.data['data']);
  }
}
```

### 8. Pagination Helper

**Pagination Support:**

```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  
  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });
  
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
  
  bool get hasMore => currentPage < lastPage;
}
```

### 9. Feature Parity Verification System

**Endpoint Coverage Tracker:**

```dart
class EndpointCoverageTracker {
  static const Map<String, List<String>> postmanEndpoints = {
    'Public': [
      'GET /organizations',
      'GET /organizations/{id}/departments',
    ],
    'Authentication': [
      'POST /auth/register',
      'POST /auth/login',
      'GET /auth/me',
      'POST /auth/refresh',
      'POST /auth/logout',
      'POST /auth/forgot-password',
    ],
    'SuperAdmin': [
      'GET /super-admin/analytics',
      'GET /superadmin/group',
      'GET /superadmin/group/members',
      'POST /superadmin/group/regenerate-code',
      'DELETE /superadmin/group/members/{id}',
    ],
    'Expenses': [
      'GET /expenses',
      'POST /expenses',
      'GET /expenses/{id}',
      'PUT /expenses/{id}',
      'DELETE /expenses/{id}',
      'POST /expenses/{id}/invoice',
      'GET /expenses/{id}/invoice',
      'DELETE /expenses/{id}/invoice',
    ],
    'Transfers': [
      'GET /transfers',
      'POST /transfers',
      'GET /transfers/{id}',
      'PUT /transfers/{id}',
      'DELETE /transfers/{id}',
      'POST /transfers/{id}/exchange',
    ],
    'Incoming': [
      'GET /incoming',
      'POST /incoming',
      'GET /incoming/{id}',
      'PUT /incoming/{id}',
      'DELETE /incoming/{id}',
    ],
    'Fund Box': [
      'GET /fund-box',
      'GET /fund-box?currency={currency}',
      'GET /fund-box?user_id={id}',
      'PUT /fund-box',
    ],
    'Exchanges': [
      'POST /exchanges',
      'GET /exchanges',
      'GET /exchanges?currency={currency}',
      'GET /exchanges/{id}',
      'GET /exchanges/transfer/{id}',
      'GET /exchanges/transfer/{id}/balance',
    ],
    'Admin Groups': [
      'GET /admin/group',
      'POST /admin/group/regenerate',
      'GET /admin/group/members',
      'DELETE /admin/group/members/{id}',
      'POST /user/join-group',
      'GET /user/group-info',
    ],
    'Admin Dashboard': [
      'GET /admin/dashboard/stats',
      'GET /admin/dashboard/users',
      'GET /admin/dashboard/expenses',
      'GET /admin/dashboard/analytics',
    ],
    'Audit Logs': [
      'GET /audit-logs',
      'GET /audit-logs/{id}',
    ],
    'Export & Sync': [
      'GET /export',
      'POST /export/expenses/pdf',
      'POST /export/expenses/excel',
      'POST /export/system-wide',
      'GET /export/{id}/status',
      'GET /export/{id}/download',
      'POST /sync/batch',
      'GET /sync/changes',
      'POST /sync/resolve',
    ],
  };
  
  Future<Map<String, double>> calculateCoverage() async {
    final coverage = <String, double>{};
    
    for (final category in postmanEndpoints.keys) {
      final endpoints = postmanEndpoints[category]!;
      final implemented = await _countImplementedEndpoints(category, endpoints);
      coverage[category] = (implemented / endpoints.length) * 100;
    }
    
    return coverage;
  }
  
  Future<int> _countImplementedEndpoints(
    String category,
    List<String> endpoints,
  ) async {
    // Check if datasource exists and has methods for each endpoint
    // This would be implemented based on your project structure
    return endpoints.length; // Placeholder
  }
}
```

## Testing Strategy

### Unit Tests

1. **API Datasource Tests**: Verify all endpoints with Bearer token
2. **DTO Tests**: Verify JSON serialization/deserialization
3. **Repository Tests**: Verify data layer integration
4. **BLoC Tests**: Verify state management

### Integration Tests

1. **SuperAdmin Flow**: Registration → Analytics → Group Management
2. **Admin Flow**: Registration with code → Transfer to User → Group Management
3. **User Flow**: Join group → Create expenses → Exchange currency
4. **Multi-Currency Flow**: Create expenses in USD/SYP/TRY → View fund box
5. **Exchange Flow**: Create exchange → View history → Check balance

### Widget Tests

1. **SuperAdmin UI**: Analytics page, Group management page
2. **Admin UI**: Dashboard, Group management
3. **User UI**: Expense creation with currency selection, Exchange page
4. **Fund Box UI**: Multi-currency display

## Error Handling

### Bearer Token Errors

```dart
class BearerTokenErrorHandler {
  static Future<void> handle401(DioError error) async {
    // Token expired or invalid
    final refreshed = await TokenManager().refreshToken();
    
    if (!refreshed) {
      // Redirect to login
      await NavigationService().navigateToLogin();
      await TokenManager().clearToken();
    }
  }
  
  static Future<void> handle403(DioError error) async {
    // Insufficient permissions
    showErrorDialog('Access Denied', 'You do not have permission to access this resource.');
  }
}
```

## Success Criteria

1. **100% Endpoint Coverage**: All 12 Postman categories fully implemented
2. **Bearer Token Authentication**: All protected endpoints include proper Authorization header
3. **Multi-Currency Support**: USD, SYP, TRY fully functional in fund box and expenses
4. **SuperAdmin Features**: Analytics and group management working
5. **Balance-Based Exchanges**: Currency exchange using total balance
6. **Role-Based Access**: SuperAdmin, Admin, User roles properly enforced
7. **Error Handling**: All HTTP status codes handled appropriately
8. **Testing**: 90%+ code coverage with unit, integration, and widget tests

## Implementation Priority

### Phase 1: Bearer Token Authentication (High Priority)
- Update API client with Bearer token interceptor
- Verify all protected endpoints include Authorization header
- Test token refresh flow

### Phase 2: SuperAdmin Features (High Priority)
- Implement SuperAdmin registration
- Implement analytics API integration
- Implement SuperAdmin group management

### Phase 3: Multi-Currency Support (High Priority)
- Update fund box to support USD, SYP, TRY
- Update expense creation for multi-currency
- Implement balance-based exchanges

### Phase 4: Transfer Enhancements (Medium Priority)
- Implement SuperAdmin→Admin transfers
- Implement Admin→User transfers
- Update transfer UI

### Phase 5: Admin Group Management (Medium Priority)
- Implement admin group endpoints
- Implement user join group
- Update group management UI

### Phase 6: Testing and Documentation (Medium Priority)
- Write comprehensive tests
- Update API documentation
- Create user guides

### Phase 7: Verification and Validation (Low Priority)
- Run endpoint coverage analysis
- Perform manual testing
- Fix any gaps identified
