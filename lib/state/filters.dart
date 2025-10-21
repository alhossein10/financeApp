import 'package:flutter/foundation.dart';

enum ExpenseCurrencyFilter { all, usd, syp, tr }
enum DateFilterType { all, today, thisWeek, thisMonth, custom }

class DateFilter {
  final DateFilterType type;
  final DateTime? startDate;
  final DateTime? endDate;

  const DateFilter({
    required this.type,
    this.startDate,
    this.endDate,
  });
}

class ExpenseFilterNotifier extends ValueNotifier<ExpenseCurrencyFilter> {
  ExpenseFilterNotifier() : super(ExpenseCurrencyFilter.all);

  static final ExpenseFilterNotifier instance = ExpenseFilterNotifier();
}

class DateFilterNotifier extends ValueNotifier<DateFilter> {
  DateFilterNotifier() : super(const DateFilter(type: DateFilterType.all));

  static final DateFilterNotifier instance = DateFilterNotifier();
}


