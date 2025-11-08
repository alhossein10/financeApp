/// Helper class for managing pagination in API requests
class PaginationHelper {
  /// Default page size for list requests
  static const int defaultPageSize = 15;
  
  /// Maximum page size allowed
  static const int maxPageSize = 100;

  /// Calculate pagination parameters
  static Map<String, dynamic> getPaginationParams({
    int page = 1,
    int perPage = defaultPageSize,
  }) {
    // Ensure page is at least 1
    final validPage = page < 1 ? 1 : page;
    
    // Ensure perPage is within limits
    final validPerPage = perPage < 1 
        ? defaultPageSize 
        : (perPage > maxPageSize ? maxPageSize : perPage);
    
    return {
      'page': validPage,
      'per_page': validPerPage,
    };
  }

  /// Check if there are more pages available
  static bool hasMorePages({
    required int currentPage,
    required int totalPages,
  }) {
    return currentPage < totalPages;
  }

  /// Calculate total pages from total items
  static int calculateTotalPages({
    required int totalItems,
    required int perPage,
  }) {
    if (totalItems == 0 || perPage == 0) return 0;
    return (totalItems / perPage).ceil();
  }

  /// Get next page number
  static int? getNextPage({
    required int currentPage,
    required int totalPages,
  }) {
    return hasMorePages(currentPage: currentPage, totalPages: totalPages)
        ? currentPage + 1
        : null;
  }

  /// Get previous page number
  static int? getPreviousPage({
    required int currentPage,
  }) {
    return currentPage > 1 ? currentPage - 1 : null;
  }
}

/// Pagination metadata from API responses
class PaginationMeta {
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;
  final int? nextPage;
  final int? previousPage;

  PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
    this.nextPage,
    this.previousPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? PaginationHelper.defaultPageSize,
      totalItems: json['total'] ?? 0,
      totalPages: json['last_page'] ?? 0,
      nextPage: json['next_page'],
      previousPage: json['prev_page'],
    );
  }

  bool get hasNextPage => nextPage != null;
  bool get hasPreviousPage => previousPage != null;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({
    required this.data,
    required this.meta,
  });

  bool get hasMore => meta.hasNextPage;
  int? get nextPage => meta.nextPage;
  
  /// Create PaginatedResponse from API response
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataList = (json['data'] as List<dynamic>?)
        ?.map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList() ?? [];
    
    final meta = PaginationMeta.fromJson(json);
    
    return PaginatedResponse(
      data: dataList,
      meta: meta,
    );
  }
  
  /// Merge with another paginated response (for infinite scroll)
  PaginatedResponse<T> merge(PaginatedResponse<T> other) {
    return PaginatedResponse(
      data: [...data, ...other.data],
      meta: other.meta,
    );
  }
  
  /// Create empty paginated response
  factory PaginatedResponse.empty() {
    return PaginatedResponse(
      data: [],
      meta: PaginationMeta(
        currentPage: 1,
        perPage: PaginationHelper.defaultPageSize,
        totalItems: 0,
        totalPages: 0,
      ),
    );
  }
}
