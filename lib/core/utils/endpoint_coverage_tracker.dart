import 'dart:io';

/// Endpoint Coverage Tracker
/// 
/// Analyzes the Flutter codebase to verify complete feature parity
/// between the Postman API v3.1 collection and implemented endpoints.
/// 
/// This tool checks all 12 endpoint categories and generates a coverage report.
class EndpointCoverageTracker {
  /// All endpoints defined in Postman API v3.1 Collection
  /// Organized by category for easy verification
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
      'POST /auth/reset-password',
      'PUT /auth/change-password',
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
      'GET /calculated-balance',
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

  /// Mapping of endpoints to their implementation files
  /// This helps verify which endpoints are actually implemented
  static const Map<String, String> endpointImplementations = {
    // Public endpoints
    'GET /organizations': 'lib/features/organizations/data/datasources/organizations_api_datasource.dart',
    'GET /organizations/{id}/departments': 'lib/features/organizations/data/datasources/organizations_api_datasource.dart',
    
    // Authentication endpoints
    'POST /auth/register': 'lib/core/services/laravel_auth_service.dart',
    'POST /auth/login': 'lib/core/services/laravel_auth_service.dart',
    'GET /auth/me': 'lib/core/services/laravel_auth_service.dart',
    'POST /auth/refresh': 'lib/core/services/laravel_auth_service.dart',
    'POST /auth/logout': 'lib/core/services/laravel_auth_service.dart',
    'POST /auth/forgot-password': 'lib/core/services/laravel_auth_service.dart',
    'POST /auth/reset-password': 'lib/core/services/laravel_auth_service.dart',
    'PUT /auth/change-password': 'lib/core/services/laravel_auth_service.dart',
    
    // SuperAdmin endpoints
    'GET /super-admin/analytics': 'lib/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart',
    'GET /superadmin/group': 'lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart',
    'GET /superadmin/group/members': 'lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart',
    'POST /superadmin/group/regenerate-code': 'lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart',
    'DELETE /superadmin/group/members/{id}': 'lib/features/superadmin/data/datasources/superadmin_group_api_datasource.dart',
    
    // Expenses endpoints
    'GET /expenses': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'POST /expenses': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'GET /expenses/{id}': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'PUT /expenses/{id}': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'DELETE /expenses/{id}': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'POST /expenses/{id}/invoice': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'GET /expenses/{id}/invoice': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    'DELETE /expenses/{id}/invoice': 'lib/features/expenses/data/datasources/expense_api_datasource.dart',
    
    // Transfers endpoints
    'GET /transfers': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    'POST /transfers': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    'GET /transfers/{id}': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    'PUT /transfers/{id}': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    'DELETE /transfers/{id}': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    'POST /transfers/{id}/exchange': 'lib/features/transfers/data/datasources/transfer_api_datasource.dart',
    
    // Incoming endpoints
    'GET /incoming': 'lib/features/incoming/data/datasources/incoming_api_datasource.dart',
    'POST /incoming': 'lib/features/incoming/data/datasources/incoming_api_datasource.dart',
    'GET /incoming/{id}': 'lib/features/incoming/data/datasources/incoming_api_datasource.dart',
    'PUT /incoming/{id}': 'lib/features/incoming/data/datasources/incoming_api_datasource.dart',
    'DELETE /incoming/{id}': 'lib/features/incoming/data/datasources/incoming_api_datasource.dart',
    
    // Fund Box endpoints
    'GET /fund-box': 'lib/features/fund_box/data/datasources/fund_box_api_datasource.dart',
    'GET /fund-box?currency={currency}': 'lib/features/fund_box/data/datasources/fund_box_api_datasource.dart',
    'GET /fund-box?user_id={id}': 'lib/features/fund_box/data/datasources/fund_box_api_datasource.dart',
    'GET /calculated-balance': 'lib/features/fund_box/data/datasources/fund_box_api_datasource.dart',
    'PUT /fund-box': 'lib/features/fund_box/data/datasources/fund_box_api_datasource.dart',
    
    // Exchanges endpoints
    'POST /exchanges': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    'GET /exchanges': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    'GET /exchanges?currency={currency}': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    'GET /exchanges/{id}': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    'GET /exchanges/transfer/{id}': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    'GET /exchanges/transfer/{id}/balance': 'lib/features/exchanges/data/datasources/exchange_api_datasource.dart',
    
    // Admin Groups endpoints
    'GET /admin/group': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    'POST /admin/group/regenerate': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    'GET /admin/group/members': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    'DELETE /admin/group/members/{id}': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    'POST /user/join-group': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    'GET /user/group-info': 'lib/features/admin_group/data/datasources/admin_group_api_datasource.dart',
    
    // Admin Dashboard endpoints
    'GET /admin/dashboard/stats': 'lib/features/admin/data/datasources/admin_api_datasource.dart',
    'GET /admin/dashboard/users': 'lib/features/admin/data/datasources/admin_api_datasource.dart',
    'GET /admin/dashboard/expenses': 'lib/features/admin/data/datasources/admin_api_datasource.dart',
    'GET /admin/dashboard/analytics': 'lib/features/admin/data/datasources/admin_api_datasource.dart',
    
    // Audit Logs endpoints
    'GET /audit-logs': 'lib/features/admin/data/datasources/audit_log_api_datasource.dart',
    'GET /audit-logs/{id}': 'lib/features/admin/data/datasources/audit_log_api_datasource.dart',
    
    // Export & Sync endpoints
    'GET /export': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'POST /export/expenses/pdf': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'POST /export/expenses/excel': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'POST /export/system-wide': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'GET /export/{id}/status': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'GET /export/{id}/download': 'lib/features/export/data/datasources/export_api_datasource.dart',
    'POST /sync/batch': 'lib/core/services/batch_sync_service.dart',
    'GET /sync/changes': 'lib/core/services/batch_sync_service.dart',
    'POST /sync/resolve': 'lib/core/services/conflict_resolution_service.dart',
  };

  /// Calculate coverage for all endpoint categories
  Future<Map<String, CoverageResult>> calculateCoverage() async {
    final coverage = <String, CoverageResult>{};
    
    for (final category in postmanEndpoints.keys) {
      final endpoints = postmanEndpoints[category]!;
      final implemented = await _countImplementedEndpoints(category, endpoints);
      
      coverage[category] = CoverageResult(
        category: category,
        totalEndpoints: endpoints.length,
        implementedEndpoints: implemented,
        coveragePercentage: (implemented / endpoints.length) * 100,
        endpoints: endpoints,
      );
    }
    
    return coverage;
  }

  /// Count how many endpoints in a category are implemented
  Future<int> _countImplementedEndpoints(
    String category,
    List<String> endpoints,
  ) async {
    int count = 0;
    
    for (final endpoint in endpoints) {
      if (await _isEndpointImplemented(endpoint)) {
        count++;
      }
    }
    
    return count;
  }

  /// Check if a specific endpoint is implemented
  Future<bool> _isEndpointImplemented(String endpoint) async {
    // Check if endpoint has a known implementation file
    if (!endpointImplementations.containsKey(endpoint)) {
      return false;
    }
    
    final filePath = endpointImplementations[endpoint]!;
    final file = File(filePath);
    
    // Check if the implementation file exists
    if (!await file.exists()) {
      return false;
    }
    
    // Read file content to verify endpoint is actually implemented
    final content = await file.readAsString();
    
    // Extract the endpoint path for verification
    final endpointPath = _extractEndpointPath(endpoint);
    
    // Check if the endpoint path appears in the file
    return content.contains(endpointPath);
  }

  /// Extract the endpoint path from the full endpoint string
  /// Example: "GET /expenses" -> "/expenses"
  String _extractEndpointPath(String endpoint) {
    final parts = endpoint.split(' ');
    if (parts.length >= 2) {
      return parts[1];
    }
    return endpoint;
  }

  /// Generate a detailed coverage report
  Future<CoverageReport> generateReport() async {
    final coverage = await calculateCoverage();
    
    // Calculate overall statistics
    int totalEndpoints = 0;
    int totalImplemented = 0;
    
    for (final result in coverage.values) {
      totalEndpoints += result.totalEndpoints;
      totalImplemented += result.implementedEndpoints;
    }
    
    final overallCoverage = (totalImplemented / totalEndpoints) * 100;
    
    return CoverageReport(
      categoryCoverage: coverage,
      totalEndpoints: totalEndpoints,
      totalImplemented: totalImplemented,
      overallCoverage: overallCoverage,
      generatedAt: DateTime.now(),
    );
  }

  /// Get list of missing endpoints
  Future<List<MissingEndpoint>> getMissingEndpoints() async {
    final missing = <MissingEndpoint>[];
    
    for (final category in postmanEndpoints.keys) {
      final endpoints = postmanEndpoints[category]!;
      
      for (final endpoint in endpoints) {
        if (!await _isEndpointImplemented(endpoint)) {
          missing.add(MissingEndpoint(
            category: category,
            endpoint: endpoint,
            priority: _determinePriority(category),
          ));
        }
      }
    }
    
    return missing;
  }

  /// Determine priority based on category
  String _determinePriority(String category) {
    const highPriority = ['Authentication', 'SuperAdmin', 'Expenses', 'Fund Box'];
    const mediumPriority = ['Transfers', 'Exchanges', 'Admin Groups', 'Admin Dashboard'];
    
    if (highPriority.contains(category)) {
      return 'HIGH';
    } else if (mediumPriority.contains(category)) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }
}

/// Coverage result for a single category
class CoverageResult {
  final String category;
  final int totalEndpoints;
  final int implementedEndpoints;
  final double coveragePercentage;
  final List<String> endpoints;

  CoverageResult({
    required this.category,
    required this.totalEndpoints,
    required this.implementedEndpoints,
    required this.coveragePercentage,
    required this.endpoints,
  });

  int get missingEndpoints => totalEndpoints - implementedEndpoints;
  bool get isComplete => implementedEndpoints == totalEndpoints;

  @override
  String toString() {
    return '$category: $implementedEndpoints/$totalEndpoints (${coveragePercentage.toStringAsFixed(1)}%)';
  }
}

/// Complete coverage report
class CoverageReport {
  final Map<String, CoverageResult> categoryCoverage;
  final int totalEndpoints;
  final int totalImplemented;
  final double overallCoverage;
  final DateTime generatedAt;

  CoverageReport({
    required this.categoryCoverage,
    required this.totalEndpoints,
    required this.totalImplemented,
    required this.overallCoverage,
    required this.generatedAt,
  });

  int get totalMissing => totalEndpoints - totalImplemented;
  bool get isComplete => totalImplemented == totalEndpoints;

  /// Generate a formatted text report
  String toFormattedString() {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 80);
    buffer.writeln('POSTMAN API v3.1 ENDPOINT COVERAGE REPORT');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln('═' * 80);
    buffer.writeln();
    
    buffer.writeln('OVERALL COVERAGE');
    buffer.writeln('─' * 80);
    buffer.writeln('Total Endpoints:      $totalEndpoints');
    buffer.writeln('Implemented:          $totalImplemented');
    buffer.writeln('Missing:              $totalMissing');
    buffer.writeln('Coverage:             ${overallCoverage.toStringAsFixed(1)}%');
    buffer.writeln();
    
    buffer.writeln('CATEGORY BREAKDOWN');
    buffer.writeln('─' * 80);
    
    for (final result in categoryCoverage.values) {
      final status = result.isComplete ? '✓' : '✗';
      buffer.writeln(
        '$status ${result.category.padRight(20)} '
        '${result.implementedEndpoints.toString().padLeft(2)}/${result.totalEndpoints.toString().padLeft(2)} '
        '(${result.coveragePercentage.toStringAsFixed(1).padLeft(5)}%)',
      );
    }
    
    buffer.writeln();
    buffer.writeln('═' * 80);
    
    return buffer.toString();
  }
}

/// Missing endpoint information
class MissingEndpoint {
  final String category;
  final String endpoint;
  final String priority;

  MissingEndpoint({
    required this.category,
    required this.endpoint,
    required this.priority,
  });

  @override
  String toString() {
    return '[$priority] $category: $endpoint';
  }
}
