import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/fund_box/data/models/fund_box_dto.dart';
import '../../features/expenses/data/models/expense_dto.dart';
import '../../features/transfers/data/models/transfer_dto.dart';
import '../../core/api/models/user_dto.dart';

/// Service for caching offline data
/// Handles caching of financial box balances, expenses, transfers, and user profile data
class OfflineCacheService {
  static const String _fundBoxBoxName = 'offline_fund_box';
  static const String _expensesBoxName = 'offline_expenses';
  static const String _transfersBoxName = 'offline_transfers';
  static const String _userProfileBoxName = 'offline_user_profile';
  static const String _metadataBoxName = 'offline_cache_metadata';

  Box? _fundBoxBox;
  Box? _expensesBox;
  Box? _transfersBox;
  Box? _userProfileBox;
  Box? _metadataBox;

  bool _isInitialized = false;

  /// Initialize all cache boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    _fundBoxBox = await Hive.openBox(_fundBoxBoxName);
    _expensesBox = await Hive.openBox(_expensesBoxName);
    _transfersBox = await Hive.openBox(_transfersBoxName);
    _userProfileBox = await Hive.openBox(_userProfileBoxName);
    _metadataBox = await Hive.openBox(_metadataBoxName);

    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('OfflineCacheService not initialized. Call initialize() first.');
    }
  }

  // ==================== Fund Box Caching ====================

  /// Cache fund box balance for a user
  Future<void> cacheFundBox(String userId, FundBoxDto fundBox) async {
    _ensureInitialized();
    await _fundBoxBox!.put(userId, fundBox.toJson());
    await _updateMetadata('fundBox_$userId', DateTime.now());
  }

  /// Get cached fund box balance
  Future<FundBoxDto?> getCachedFundBox(String userId) async {
    _ensureInitialized();
    final data = _fundBoxBox!.get(userId);
    if (data == null) return null;

    try {
      return FundBoxDto.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      print('[OfflineCacheService] Error parsing cached fund box: $e');
      return null;
    }
  }

  /// Check if fund box cache exists for user
  bool hasCachedFundBox(String userId) {
    _ensureInitialized();
    return _fundBoxBox!.containsKey(userId);
  }

  // ==================== Expenses Caching ====================

  /// Cache expenses list for a user
  Future<void> cacheExpenses(String userId, List<ExpenseDto> expenses) async {
    _ensureInitialized();
    final expensesJson = expenses.map((e) => e.toJson()).toList();
    await _expensesBox!.put(userId, expensesJson);
    await _updateMetadata('expenses_$userId', DateTime.now());
  }

  /// Get cached expenses list
  Future<List<ExpenseDto>> getCachedExpenses(String userId) async {
    _ensureInitialized();
    final data = _expensesBox!.get(userId);
    if (data == null) return [];

    try {
      final List<dynamic> expensesList = data as List<dynamic>;
      return expensesList
          .map((e) => ExpenseDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      print('[OfflineCacheService] Error parsing cached expenses: $e');
      return [];
    }
  }

  /// Check if expenses cache exists for user
  bool hasCachedExpenses(String userId) {
    _ensureInitialized();
    return _expensesBox!.containsKey(userId);
  }

  /// Add single expense to cache
  Future<void> addExpenseToCache(String userId, ExpenseDto expense) async {
    _ensureInitialized();
    final cachedExpenses = await getCachedExpenses(userId);
    cachedExpenses.insert(0, expense); // Add to beginning
    await cacheExpenses(userId, cachedExpenses);
  }

  /// Update expense in cache
  Future<void> updateExpenseInCache(String userId, ExpenseDto expense) async {
    _ensureInitialized();
    final cachedExpenses = await getCachedExpenses(userId);
    final index = cachedExpenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      cachedExpenses[index] = expense;
      await cacheExpenses(userId, cachedExpenses);
    }
  }

  /// Remove expense from cache
  Future<void> removeExpenseFromCache(String userId, String expenseId) async {
    _ensureInitialized();
    final cachedExpenses = await getCachedExpenses(userId);
    cachedExpenses.removeWhere((e) => e.id == expenseId);
    await cacheExpenses(userId, cachedExpenses);
  }

  // ==================== Transfers Caching ====================

  /// Cache transfers list for a user
  Future<void> cacheTransfers(String userId, List<TransferDto> transfers) async {
    _ensureInitialized();
    final transfersJson = transfers.map((t) => t.toJson()).toList();
    await _transfersBox!.put(userId, transfersJson);
    await _updateMetadata('transfers_$userId', DateTime.now());
  }

  /// Get cached transfers list
  Future<List<TransferDto>> getCachedTransfers(String userId) async {
    _ensureInitialized();
    final data = _transfersBox!.get(userId);
    if (data == null) return [];

    try {
      final List<dynamic> transfersList = data as List<dynamic>;
      return transfersList
          .map((t) => TransferDto.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();
    } catch (e) {
      print('[OfflineCacheService] Error parsing cached transfers: $e');
      return [];
    }
  }

  /// Check if transfers cache exists for user
  bool hasCachedTransfers(String userId) {
    _ensureInitialized();
    return _transfersBox!.containsKey(userId);
  }

  /// Add single transfer to cache
  Future<void> addTransferToCache(String userId, TransferDto transfer) async {
    _ensureInitialized();
    final cachedTransfers = await getCachedTransfers(userId);
    cachedTransfers.insert(0, transfer); // Add to beginning
    await cacheTransfers(userId, cachedTransfers);
  }

  // ==================== User Profile Caching ====================

  /// Cache user profile data
  Future<void> cacheUserProfile(String userId, UserDto user) async {
    _ensureInitialized();
    await _userProfileBox!.put(userId, user.toJson());
    await _updateMetadata('userProfile_$userId', DateTime.now());
  }

  /// Get cached user profile
  Future<UserDto?> getCachedUserProfile(String userId) async {
    _ensureInitialized();
    final data = _userProfileBox!.get(userId);
    if (data == null) return null;

    try {
      return UserDto.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      print('[OfflineCacheService] Error parsing cached user profile: $e');
      return null;
    }
  }

  /// Check if user profile cache exists
  bool hasCachedUserProfile(String userId) {
    _ensureInitialized();
    return _userProfileBox!.containsKey(userId);
  }

  // ==================== Metadata Management ====================

  /// Update cache metadata (last updated timestamp)
  Future<void> _updateMetadata(String key, DateTime timestamp) async {
    await _metadataBox!.put(key, timestamp.toIso8601String());
  }

  /// Get cache metadata (last updated timestamp)
  DateTime? getCacheTimestamp(String key) {
    _ensureInitialized();
    final timestampStr = _metadataBox!.get(key);
    if (timestampStr == null) return null;
    
    try {
      return DateTime.parse(timestampStr as String);
    } catch (e) {
      return null;
    }
  }

  /// Get last updated timestamp for fund box
  DateTime? getFundBoxCacheTimestamp(String userId) {
    return getCacheTimestamp('fundBox_$userId');
  }

  /// Get last updated timestamp for expenses
  DateTime? getExpensesCacheTimestamp(String userId) {
    return getCacheTimestamp('expenses_$userId');
  }

  /// Get last updated timestamp for transfers
  DateTime? getTransfersCacheTimestamp(String userId) {
    return getCacheTimestamp('transfers_$userId');
  }

  /// Get last updated timestamp for user profile
  DateTime? getUserProfileCacheTimestamp(String userId) {
    return getCacheTimestamp('userProfile_$userId');
  }

  // ==================== Cache Management ====================

  /// Clear all cached data for a user
  Future<void> clearUserCache(String userId) async {
    _ensureInitialized();
    await _fundBoxBox!.delete(userId);
    await _expensesBox!.delete(userId);
    await _transfersBox!.delete(userId);
    await _userProfileBox!.delete(userId);
    
    // Clear metadata
    await _metadataBox!.delete('fundBox_$userId');
    await _metadataBox!.delete('expenses_$userId');
    await _metadataBox!.delete('transfers_$userId');
    await _metadataBox!.delete('userProfile_$userId');
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    _ensureInitialized();
    await _fundBoxBox!.clear();
    await _expensesBox!.clear();
    await _transfersBox!.clear();
    await _userProfileBox!.clear();
    await _metadataBox!.clear();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    _ensureInitialized();
    return {
      'fundBoxEntries': _fundBoxBox!.length,
      'expensesEntries': _expensesBox!.length,
      'transfersEntries': _transfersBox!.length,
      'userProfileEntries': _userProfileBox!.length,
      'totalEntries': _fundBoxBox!.length + 
                      _expensesBox!.length + 
                      _transfersBox!.length + 
                      _userProfileBox!.length,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _fundBoxBox?.close();
    await _expensesBox?.close();
    await _transfersBox?.close();
    await _userProfileBox?.close();
    await _metadataBox?.close();
    _isInitialized = false;
  }
}

