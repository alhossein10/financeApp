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

class UserFilterNotifier extends ValueNotifier<String?> {
  UserFilterNotifier() : super(null);

  static final UserFilterNotifier instance = UserFilterNotifier();
}

class RecipientFilterNotifier extends ValueNotifier<String?> {
  RecipientFilterNotifier() : super(null);

  static final RecipientFilterNotifier instance = RecipientFilterNotifier();
}

