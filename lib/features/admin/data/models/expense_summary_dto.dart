/// Data Transfer Object for expense summary information
/// Maps between API JSON and domain entities
/// Matches Laravel API spec: /admin/dashboard/expenses
class ExpenseSummaryDto {
  final List<CategorySummary> byCategory;
  final List<PaymentMethodSummary> byPaymentMethod;

  const ExpenseSummaryDto({
    required this.byCategory,
    required this.byPaymentMethod,
  });

  /// Create ExpenseSummaryDto from JSON response
  factory ExpenseSummaryDto.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryDto(
      byCategory: (json['by_category'] as List<dynamic>?)
              ?.map((item) => CategorySummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      byPaymentMethod: (json['by_payment_method'] as List<dynamic>?)
              ?.map((item) => PaymentMethodSummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert ExpenseSummaryDto to JSON
  Map<String, dynamic> toJson() {
    return {
      'by_category': byCategory.map((item) => item.toJson()).toList(),
      'by_payment_method': byPaymentMethod.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'ExpenseSummaryDto(byCategory: ${byCategory.length} items, '
        'byPaymentMethod: ${byPaymentMethod.length} items)';
  }
}

/// Category summary data
class CategorySummary {
  final String category;
  final double total;
  final int count;

  const CategorySummary({
    required this.category,
    required this.total,
    required this.count,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'total': total,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'CategorySummary(category: $category, total: $total, count: $count)';
  }
}

/// Payment method summary data
class PaymentMethodSummary {
  final String paymentMethod;
  final double total;

  const PaymentMethodSummary({
    required this.paymentMethod,
    required this.total,
  });

  factory PaymentMethodSummary.fromJson(Map<String, dynamic> json) {
    return PaymentMethodSummary(
      paymentMethod: json['payment_method'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_method': paymentMethod,
      'total': total,
    };
  }

  @override
  String toString() {
    return 'PaymentMethodSummary(paymentMethod: $paymentMethod, total: $total)';
  }
}
