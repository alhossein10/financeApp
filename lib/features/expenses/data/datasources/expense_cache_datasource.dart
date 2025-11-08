import '../../../../core/services/cache_service.dart';
import '../models/expense_dto.dart';

/// Cache data source for expense operations
abstract class ExpenseCacheDataSource {
  Future<ExpenseListResponse?> getCachedExpenses({
    int page = 1,
    int perPage = 15,
  });

  Future<void> cacheExpenses(
    ExpenseListResponse response, {
    int page = 1,
    int perPage = 15,
  });

  Future<ExpenseDto?> getCachedExpense(int id);

  Future<void> cacheExpense(ExpenseDto expense);

  Future<void> invalidateExpenseCache(int id);

  Future<void> clearAllCache();
}

class ExpenseCacheDataSourceImpl implements ExpenseCacheDataSource {
  final CacheService cacheService;
  static const Duration _cacheDuration = Duration(minutes: 15);

  ExpenseCacheDataSourceImpl({required this.cacheService});

  String _getExpenseListKey(int page, int perPage) => 'expenses_list_${page}_$perPage';
  String _getExpenseKey(int id) => 'expense_$id';

  @override
  Future<ExpenseListResponse?> getCachedExpenses({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final key = _getExpenseListKey(page, perPage);
      final cached = await cacheService.get<Map<String, dynamic>>(key);
      
      if (cached != null) {
        return ExpenseListResponse.fromJson(cached);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExpenses(
    ExpenseListResponse response, {
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final key = _getExpenseListKey(page, perPage);
      final json = {
        'data': response.data.map((e) => e.toJson()).toList(),
        'current_page': response.currentPage,
        'last_page': response.lastPage,
        'per_page': response.perPage,
        'total': response.total,
      };
      
      await cacheService.set(key, json, ttl: _cacheDuration);
      
      // Also cache individual expenses
      for (final expense in response.data) {
        if (expense.id != null) {
          await cacheExpense(expense);
        }
      }
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<ExpenseDto?> getCachedExpense(int id) async {
    try {
      final key = _getExpenseKey(id);
      final cached = await cacheService.get<Map<String, dynamic>>(key);
      
      if (cached != null) {
        return ExpenseDto.fromJson(cached);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExpense(ExpenseDto expense) async {
    try {
      if (expense.id != null) {
        final key = _getExpenseKey(expense.id!);
        await cacheService.set(key, expense.toJson(), ttl: _cacheDuration);
      }
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> invalidateExpenseCache(int id) async {
    try {
      final key = _getExpenseKey(id);
      await cacheService.delete(key);
      
      // Also invalidate list caches (simple approach - clear all list caches)
      // In production, you might want a more sophisticated approach
      await _invalidateListCaches();
    } catch (e) {
      // Silently fail cache operations
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await cacheService.clear();
    } catch (e) {
      // Silently fail cache operations
    }
  }

  Future<void> _invalidateListCaches() async {
    // Clear common list cache keys
    for (int page = 1; page <= 10; page++) {
      for (int perPage in [15, 25, 50]) {
        final key = _getExpenseListKey(page, perPage);
        await cacheService.delete(key);
      }
    }
  }
}
