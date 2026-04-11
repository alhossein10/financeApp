import 'package:flutter/material.dart';

/// Filter Persistence Service
/// 
/// Manages filter state persistence during the current session.
/// Filters are stored in memory and persist when navigating between
/// Expenses and Export pages. Filters are cleared on logout.
/// 
/// Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6, 26.7, 26.8
class FilterPersistenceService {
  // Singleton instance
  static final FilterPersistenceService _instance = FilterPersistenceService._internal();
  
  factory FilterPersistenceService() {
    return _instance;
  }
  
  FilterPersistenceService._internal();

  // Filter state for Admin
  DateTimeRange? _adminDateRange;
  String? _adminCurrencyFilter;
  int? _adminUserFilter;

  // Filter state for User
  DateTimeRange? _userDateRange;
  String? _userCurrencyFilter;

  // Listeners for filter changes
  final List<VoidCallback> _listeners = [];

  /// Get Admin date range filter
  DateTimeRange? get adminDateRange => _adminDateRange;

  /// Get Admin currency filter
  String? get adminCurrencyFilter => _adminCurrencyFilter;

  /// Get Admin user filter
  int? get adminUserFilter => _adminUserFilter;

  /// Get User date range filter
  DateTimeRange? get userDateRange => _userDateRange;

  /// Get User currency filter
  String? get userCurrencyFilter => _userCurrencyFilter;

  /// Set Admin filters
  /// 
  /// Requirements: 26.1, 26.2, 26.3, 26.4
  void setAdminFilters({
    DateTimeRange? dateRange,
    String? currencyFilter,
    int? userFilter,
  }) {
    _adminDateRange = dateRange;
    _adminCurrencyFilter = currencyFilter;
    _adminUserFilter = userFilter;
    _notifyListeners();
  }

  /// Set User filters
  /// 
  /// Requirements: 26.1, 26.2, 26.3, 26.4
  void setUserFilters({
    DateTimeRange? dateRange,
    String? currencyFilter,
  }) {
    _userDateRange = dateRange;
    _userCurrencyFilter = currencyFilter;
    _notifyListeners();
  }

  /// Clear Admin filters
  /// 
  /// Requirements: 26.6
  void clearAdminFilters() {
    _adminDateRange = null;
    _adminCurrencyFilter = null;
    _adminUserFilter = null;
    _notifyListeners();
  }

  /// Clear User filters
  /// 
  /// Requirements: 26.6
  void clearUserFilters() {
    _userDateRange = null;
    _userCurrencyFilter = null;
    _notifyListeners();
  }

  /// Clear all filters (called on logout)
  /// 
  /// Requirements: 26.5
  void clearAllFilters() {
    _adminDateRange = null;
    _adminCurrencyFilter = null;
    _adminUserFilter = null;
    _userDateRange = null;
    _userCurrencyFilter = null;
    _notifyListeners();
  }

  /// Get active filter count for Admin
  /// 
  /// Requirements: 26.7
  int getAdminActiveFilterCount() {
    int count = 0;
    if (_adminDateRange != null) count++;
    if (_adminCurrencyFilter != null) count++;
    if (_adminUserFilter != null) count++;
    return count;
  }

  /// Get active filter count for User
  /// 
  /// Requirements: 26.7
  int getUserActiveFilterCount() {
    int count = 0;
    if (_userDateRange != null) count++;
    if (_userCurrencyFilter != null) count++;
    return count;
  }

  /// Check if Admin has active filters
  /// 
  /// Requirements: 26.7, 26.8
  bool get hasAdminActiveFilters =>
      _adminDateRange != null ||
      _adminCurrencyFilter != null ||
      _adminUserFilter != null;

  /// Check if User has active filters
  /// 
  /// Requirements: 26.7, 26.8
  bool get hasUserActiveFilters =>
      _userDateRange != null || _userCurrencyFilter != null;

  /// Add listener for filter changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of filter changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Dispose service (for testing purposes)
  void dispose() {
    _listeners.clear();
  }
}
