import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lib/features/expenses/presentation/bloc/expense_bloc.dart';
import 'lib/features/expenses/presentation/bloc/expense_state.dart';
import 'lib/features/expenses/domain/entities/expense.dart';
import 'lib/state/filters.dart';

/// Debug script to diagnose invoice export issue
/// 
/// This will help you understand:
/// 1. How many total expenses exist
/// 2. How many have invoices
/// 3. What filters are applied
/// 4. How many expenses remain after filtering
/// 5. How many of the filtered expenses have invoices
///
/// Run this in your app to see what's happening

void debugInvoiceExportIssue(BuildContext context) {
  print('\n========== INVOICE EXPORT DEBUG ==========');
  
  // Get expense state
  final expenseState = context.read<ExpenseBloc>().state;
  
  if (expenseState is! ExpenseLoaded) {
    print('❌ Expenses not loaded yet');
    return;
  }
  
  final allExpenses = expenseState.expenses;
  print('📊 Total expenses loaded: ${allExpenses.length}');
  
  // Count expenses with invoices
  final expensesWithInvoices = allExpenses.where((e) => 
    e.invoiceStatus == InvoiceStatus.invoiceAvailable
  ).toList();
  print('📸 Expenses with invoices: ${expensesWithInvoices.length}');
  
  // Show invoice details
  for (var i = 0; i < expensesWithInvoices.length && i < 5; i++) {
    final e = expensesWithInvoices[i];
    print('  - Expense ${e.id}: ${e.description}');
    print('    Invoice Status: ${e.invoiceStatus}');
    print('    Invoice Path: ${e.invoiceFilePath}');
    print('    Cloud File ID: ${e.invoiceCloudFileId}');
    print('    Has ID: ${e.id != null}');
  }
  
  print('\n--- ACTIVE FILTERS ---');
  
  // Check currency filter
  final currencyFilter = ExpenseFilterNotifier.instance.value;
  print('💱 Currency Filter: $currencyFilter');
  
  // Check date filter
  final dateFilter = DateFilterNotifier.instance.value;
  print('📅 Date Filter: ${dateFilter.type}');
  if (dateFilter.type == DateFilterType.custom) {
    print('   Start: ${dateFilter.startDate}');
    print('   End: ${dateFilter.endDate}');
  }
  
  // Check user filter (admin only)
  final userFilter = UserFilterNotifier.instance.value;
  if (userFilter != null && userFilter.isNotEmpty) {
    print('👤 User Filter: $userFilter');
  }
  
  print('\n--- APPLYING FILTERS ---');
  
  // Apply currency filter
  var filteredExpenses = List<Expense>.from(allExpenses);
  
  if (currencyFilter != ExpenseCurrencyFilter.all) {
    final beforeCount = filteredExpenses.length;
    filteredExpenses = filteredExpenses.where((e) {
      switch (currencyFilter) {
        case ExpenseCurrencyFilter.usd:
          return (e.priceUsd ?? 0) > 0;
        case ExpenseCurrencyFilter.syp:
          return (e.priceSyp ?? 0) > 0;
        case ExpenseCurrencyFilter.tr:
          return (e.priceTry ?? 0) > 0;
        case ExpenseCurrencyFilter.all:
          return true;
      }
    }).toList();
    print('💱 After currency filter: $beforeCount → ${filteredExpenses.length}');
  }
  
  // Apply date filter
  if (dateFilter.type != DateFilterType.all) {
    final beforeCount = filteredExpenses.length;
    final now = DateTime.now();
    filteredExpenses = filteredExpenses.where((e) {
      final expenseDate = e.expenseDate;
      switch (dateFilter.type) {
        case DateFilterType.today:
          return expenseDate.year == now.year &&
              expenseDate.month == now.month &&
              expenseDate.day == now.day;
        case DateFilterType.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return expenseDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              expenseDate.isBefore(weekEnd.add(const Duration(days: 1)));
        case DateFilterType.thisMonth:
          return expenseDate.year == now.year && expenseDate.month == now.month;
        case DateFilterType.custom:
          if (dateFilter.startDate != null && dateFilter.endDate != null) {
            return expenseDate.isAfter(dateFilter.startDate!.subtract(const Duration(days: 1))) &&
                expenseDate.isBefore(dateFilter.endDate!.add(const Duration(days: 1)));
          }
          return true;
        case DateFilterType.all:
          return true;
      }
    }).toList();
    print('📅 After date filter: $beforeCount → ${filteredExpenses.length}');
  }
  
  // Apply user filter
  if (userFilter != null && userFilter.isNotEmpty) {
    final beforeCount = filteredExpenses.length;
    final filteredUserId = int.tryParse(userFilter);
    if (filteredUserId != null) {
      filteredExpenses = filteredExpenses.where((e) => e.userId == filteredUserId).toList();
      print('👤 After user filter: $beforeCount → ${filteredExpenses.length}');
    }
  }
  
  print('\n--- FINAL RESULTS ---');
  print('✅ Filtered expenses: ${filteredExpenses.length}');
  
  // Count invoices in filtered expenses
  final filteredWithInvoices = filteredExpenses.where((e) => 
    e.invoiceStatus == InvoiceStatus.invoiceAvailable
  ).toList();
  print('📸 Filtered expenses WITH invoices: ${filteredWithInvoices.length}');
  
  if (filteredWithInvoices.isEmpty) {
    print('\n⚠️  PROBLEM FOUND:');
    print('   Your filters are excluding all expenses with invoices!');
    print('   Try:');
    print('   1. Remove filters and try again');
    print('   2. Check if your invoices match the selected currency');
    print('   3. Check if your invoices match the selected date range');
  } else {
    print('\n✅ ${filteredWithInvoices.length} invoices should be exportable');
    print('   If export still fails, the issue is in the PDF export helper');
  }
  
  // Show details of filtered expenses with invoices
  if (filteredWithInvoices.isNotEmpty) {
    print('\n--- EXPORTABLE INVOICES ---');
    for (var i = 0; i < filteredWithInvoices.length && i < 5; i++) {
      final e = filteredWithInvoices[i];
      print('  ${i + 1}. ${e.description}');
      print('     USD: ${e.priceUsd}, SYP: ${e.priceSyp}, TRY: ${e.priceTry}');
      print('     Date: ${e.expenseDate.day}/${e.expenseDate.month}/${e.expenseDate.year}');
      print('     Has ID: ${e.id != null} (${e.id})');
      print('     Invoice Path: ${e.invoiceFilePath ?? "null"}');
      print('     Cloud ID: ${e.invoiceCloudFileId ?? "null"}');
    }
  }
  
  print('\n========================================\n');
}

/// Add this button to your export page to run the debug
/// 
/// Example:
/// ```dart
/// FloatingActionButton(
///   onPressed: () => debugInvoiceExportIssue(context),
///   child: Icon(Icons.bug_report),
/// )
/// ```
