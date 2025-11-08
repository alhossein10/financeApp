import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/expenses/presentation/bloc/expense_bloc.dart';
import '../features/expenses/presentation/bloc/expense_event.dart';
import '../features/expenses/presentation/bloc/expense_state.dart';
import '../features/expenses/domain/entities/expense.dart' as domain;
import '../features/expenses/data/datasources/expense_cache_datasource.dart';

import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../state/filters.dart';
import '../utils/pdf_export_helper.dart';
import '../core/widgets/watermark_background.dart';
import '../injection_container.dart' as di;

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _busy = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      // Load expenses if not already loaded
      final expenseState = context.read<ExpenseBloc>().state;
      if (expenseState is! ExpenseLoaded) {
        context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
      }
      
    }
  }

  Future<List<ExpenseRecord>> _getFilteredExpenses() async {
    final expenseState = context.read<ExpenseBloc>().state;
    if (expenseState is! ExpenseLoaded) return [];

    // Start with all domain expenses
    var domainExpenses = List<domain.Expense>.from(expenseState.expenses);

    final currencyFilter = ExpenseFilterNotifier.instance.value;
    final dateFilter = DateFilterNotifier.instance.value;
    final userFilter = UserFilterNotifier.instance.value;

    // Apply currency filter on domain expenses first
    if (currencyFilter != ExpenseCurrencyFilter.all) {
      domainExpenses = domainExpenses.where((e) {
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
    }

    // Apply date filter on domain expenses
    if (dateFilter.type != DateFilterType.all) {
      final now = DateTime.now();
      domainExpenses = domainExpenses.where((e) {
        final expenseDate = e.expenseDate;
        switch (dateFilter.type) {
          case DateFilterType.today:
            return expenseDate.year == now.year &&
                expenseDate.month == now.month &&
                expenseDate.day == now.day;
          case DateFilterType.thisWeek:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            return expenseDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                expenseDate.isBefore(weekEnd.add(const Duration(days: 1)));
          case DateFilterType.thisMonth:
            return expenseDate.year == now.year &&
                expenseDate.month == now.month;
          case DateFilterType.custom:
            if (dateFilter.startDate != null && dateFilter.endDate != null) {
              return expenseDate.isAfter(
                    dateFilter.startDate!.subtract(const Duration(days: 1)),
                  ) &&
                  expenseDate.isBefore(
                    dateFilter.endDate!.add(const Duration(days: 1)),
                  );
            }
            return true;
          case DateFilterType.all:
            return true;
        }
      }).toList();
    }

    // Apply user filter (for admin flavor)
    if (userFilter != null && userFilter.isNotEmpty) {
      final filteredUserId = int.tryParse(userFilter);
      if (filteredUserId != null) {
        domainExpenses = domainExpenses.where((e) {
          return e.userId == filteredUserId;
        }).toList();
      }
    }


    // Convert filtered domain expenses to ExpenseRecord
    final items = domainExpenses.map((e) {
      // Debug the invoice status conversion
      final domainInvoiceStatus = e.invoiceStatus;
      final domainIndex = domainInvoiceStatus.index;
      final mappedStatus = InvoiceStatus.values[domainIndex];
      
      print('[ExportPage] Mapping expense ${e.id}: domain.invoiceStatus=$domainInvoiceStatus (index=$domainIndex) -> InvoiceStatus.$mappedStatus');
      print('[ExportPage]   Domain enum values: ${domain.InvoiceStatus.values}');
      print('[ExportPage]   Model enum values: ${InvoiceStatus.values}');
      print('[ExportPage]   invoiceFilePath="${e.invoiceFilePath}", invoiceCloudFileId="${e.invoiceCloudFileId}"');
      
      return ExpenseRecord(
        id: e.id,
        description: e.description,
        priceUsd: e.priceUsd,
        priceSyp: e.priceSyp,
        priceTry: e.priceTry,
        invoiceStatus: mappedStatus,
        invoiceFilePath: e.invoiceCloudFileId ?? e.invoiceFilePath,
        expenseDate: e.expenseDate,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
    }).toList();

    return items;
  }

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      // Reload expenses to ensure we have the latest data from server (not cache)
      if (_currentUserId != null) {
        print('[ExportPage] 🚀 Starting PDF export...');
        
        // Clear cache to force fresh data from server (needed for proper userId values)
        try {
          final cacheDataSource = di.sl<ExpenseCacheDataSource>();
          await cacheDataSource.clearAllCache();
          print('[ExportPage] 🗑️ Cleared expense cache to force server fetch');
        } catch (e) {
          print('[ExportPage] ⚠️ Failed to clear cache: $e');
        }
        
        // Use a completer to wait for expenses to load (like invoice export)
        final completer = Completer<void>();
        late StreamSubscription subscription;
        
        subscription = context.read<ExpenseBloc>().stream.listen((state) {
          if (state is ExpenseLoaded) {
            print('[ExportPage] ✅ Expenses loaded: ${state.expenses.length} expenses');
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          } else if (state is ExpenseError) {
            print('[ExportPage] ❌ Error loading expenses: ${state.message}');
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });
        
        // Trigger the load
        print('[ExportPage] 📥 Loading expenses from server...');
        context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
        
        // Wait for expenses to load (with timeout)
        await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[ExportPage] ⚠️ Timeout waiting for expenses to load');
            subscription.cancel();
          },
        );
      }
      
      final items = await _getFilteredExpenses();
      
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('no_expenses_to_export') ?? 'No expenses to export')),
          );
        }
        return;
      }

      // ===== Load Arabic fonts (Amiri) =====
      final amiriRegular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final arabicFont = pw.Font.ttf(amiriRegular);
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Expenses List',
                style: pw.TextStyle(font: arabicFont, fontSize: 18),
              ),
            ),

            // وضع Directionality حول الجدول لتمكين RTL بشكل صحيح
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      // لون خلفية خفيف للرؤوس (استخدم PdfColors إن أردت ألوان)
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'USD',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'SYP',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'TRY',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Invoice',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Data rows
                  ...items.map((e) {
                    final invoiceText =
                        e.invoiceStatus == InvoiceStatus.invoiceAvailable
                        ? 'Yes'
                        : 'No';
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            e.description,
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            e.priceUsd?.toStringAsFixed(2) ?? '-',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            e.priceSyp?.toStringAsFixed(0) ?? '-',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            e.priceTry?.toStringAsFixed(2) ?? '-',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            invoiceText,
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Add Summary Section
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Summary',
                            style: pw.TextStyle(font: arabicFont, fontSize: 16),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                            style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          items.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0)).toStringAsFixed(2),
                            style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          items.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0)).toStringAsFixed(0),
                            style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          items.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0)).toStringAsFixed(2),
                            style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'expenses.pdf'));
      await file.writeAsBytes(await doc.save());
      await OpenFilex.open(file.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportExcel() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      // Reload expenses to ensure we have the latest data
      if (_currentUserId != null) {
        context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final items = await _getFilteredExpenses();
      
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('no_expenses_to_export') ?? 'No expenses to export')),
          );
        }
        return;
      }

      final book = xls.Excel.createExcel();
      final sheet = book['Expenses'];

      // Header row in English
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Description'),
        xls.TextCellValue('USD'),
        xls.TextCellValue('SYP'),
        xls.TextCellValue('TRY'),
        xls.TextCellValue('Invoice'),
      ]);

      // Create default style for cells - Excel doesn't embed fonts,
      // so Arabic display depends on fonts available on user's system
      // Using Arial Unicode MS or Tahoma which support Arabic
      final arabicStyle = xls.CellStyle(
        fontFamily: 'Tahoma', // Better Arabic support than Arial
        fontSize: 12,
      );

      for (final e in items) {
        final hasInvoice = e.invoiceStatus == InvoiceStatus.invoiceAvailable;
        sheet.appendRow(<xls.CellValue?>[
          xls.TextCellValue(e.description),
          xls.TextCellValue(e.priceUsd?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(e.priceSyp?.toStringAsFixed(0) ?? '-'),
          xls.TextCellValue(e.priceTry?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(hasInvoice ? 'Yes' : 'No'),
        ]);

        // استخدام style على الصف المضاف
        final rowIndex = sheet.maxRows - 1;
        for (var col = 0; col < 5; col++) {
          final cell = sheet.cell(
            xls.CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex,
            ),
          );
          cell.cellStyle = arabicStyle;
        }

        // تمييز الصفوف التي تحتوي على فاتورة
        if (hasInvoice) {
          final highlightStyle = xls.CellStyle(
            backgroundColorHex: xls.ExcelColor.fromHexString('#DFF0D8'),
            fontFamily: 'Tahoma',
            fontSize: 12,
          );
          for (var col = 0; col < 5; col++) {
            final cell = sheet.cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: rowIndex,
              ),
            );
            cell.cellStyle = highlightStyle;
          }
        }
      }

      // Add Summary Section
      sheet.appendRow(<xls.CellValue?>[]);  // Empty row
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Summary'),
      ]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Total'),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0)).toStringAsFixed(0)),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(''),
      ]);

      // Apply bold style to summary rows
      final summaryStyle = xls.CellStyle(
        backgroundColorHex: xls.ExcelColor.fromHexString('#E8F4F8'),
        fontFamily: 'Arial',
        fontSize: 12,
        bold: true,
      );
      final summaryRowIndex = sheet.maxRows - 1;
      for (var col = 0; col < 5; col++) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: summaryRowIndex,
          ),
        );
        cell.cellStyle = summaryStyle;
      }

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'expenses.xlsx'));
      final bytes = book.save(fileName: 'expenses.xlsx');
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(file.path);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportInvoiceImages() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    
    try {
      print('[ExportPage] 🚀 Starting invoice export...');
      
      // Reload expenses to ensure we have the latest data from server
      if (_currentUserId != null) {
        print('[ExportPage] 📥 Reloading expenses for user $_currentUserId');
        
        // Clear cache to force fresh data from server (needed for invoice export)
        try {
          final cacheDataSource = di.sl<ExpenseCacheDataSource>();
          await cacheDataSource.clearAllCache();
          print('[ExportPage] 🗑️ Cleared expense cache to force server fetch');
        } catch (e) {
          print('[ExportPage] ⚠️ Failed to clear cache: $e');
        }
        
        // Use a completer to wait for the bloc state change
        final completer = Completer<void>();
        late StreamSubscription subscription;
        
        subscription = context.read<ExpenseBloc>().stream.listen((state) {
          if (state is ExpenseLoaded) {
            print('[ExportPage] ✅ Expenses loaded: ${state.expenses.length} expenses');
            final expensesWithIds = state.expenses.where((e) => e.id != null).length;
            final expensesWithInvoices = state.expenses.where((e) => e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable).length;
            print('[ExportPage] 📊 Expenses with IDs: $expensesWithIds, Expenses with invoices: $expensesWithInvoices');
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          } else if (state is ExpenseError) {
            print('[ExportPage] ❌ Error loading expenses: ${state.message}');
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });
        
        // Trigger the load
        context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
        
        // Wait for the load to complete (with timeout)
        await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[ExportPage] ⚠️ Timeout waiting for expenses to load');
            subscription.cancel();
          },
        );
      }
      
      final expenseState = context.read<ExpenseBloc>().state;
      print('[ExportPage] 📊 Expense state: ${expenseState.runtimeType}');
      
      if (expenseState is! ExpenseLoaded) {
        final errorMsg = 'Expenses not loaded. Current state: ${expenseState.runtimeType}';
        print('[ExportPage] ❌ $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      final items = await _getFilteredExpenses();
      print('[ExportPage] 📋 Got ${items.length} filtered expenses');
      
      if (items.isEmpty) {
        print('[ExportPage] ⚠️ No expenses found after filtering');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('no_expenses_to_export') ?? 'No expenses to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Debug: Log all expenses to see their invoice status
      print('[ExportPage] 📊 Analyzing all ${items.length} expenses for invoices:');
      print('[ExportPage] 📊 Original domain expenses count: ${expenseState.expenses.length}');
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print('[ExportPage]   Expense[$i] ID=${item.id}, description="${item.description}", invoiceStatus=${item.invoiceStatus}, filePath="${item.invoiceFilePath}", cloudFileId="${item.invoiceCloudFileId}"');
        
        // Also check the original domain expense (by index since IDs might be null)
        if (i < expenseState.expenses.length) {
          final domainExpense = expenseState.expenses[i];
          print('[ExportPage]     Domain expense[$i]: id=${domainExpense.id}, invoiceStatus=${domainExpense.invoiceStatus}, invoiceFilePath="${domainExpense.invoiceFilePath}", invoiceCloudFileId="${domainExpense.invoiceCloudFileId}"');
        }
      }

      // Filter items with invoices
      // An expense has an invoice if:
      // 1. invoiceStatus is invoiceAvailable AND
      // 2. Either has a local file path/cloud file ID OR has an expense ID (can download from API)
      final itemsWithInvoices = items.where((e) {
        final hasInvoiceStatus = e.invoiceStatus == InvoiceStatus.invoiceAvailable;
        final hasId = e.id != null;
        final hasFilePath = e.invoiceFilePath != null && e.invoiceFilePath!.isNotEmpty;
        final hasCloudFileId = e.invoiceCloudFileId != null && e.invoiceCloudFileId!.isNotEmpty;
        
        print('[ExportPage]   Checking expense ${e.id}: hasInvoiceStatus=$hasInvoiceStatus, hasId=$hasId, hasFilePath=$hasFilePath, hasCloudFileId=$hasCloudFileId');
        
        if (!hasInvoiceStatus) {
          print('[ExportPage]     ❌ Rejected: invoiceStatus is ${e.invoiceStatus}, not invoiceAvailable');
          return false;
        }
        
        // If expense has an ID, we can try to download from API
        if (hasId) {
          print('[ExportPage]     ✅ Accepted: has invoice status and ID (can download from API)');
          return true;
        }
        
        // Otherwise, check for local file or cloud file ID
        final hasFile = hasFilePath || hasCloudFileId;
        if (hasFile) {
          print('[ExportPage]     ✅ Accepted: has invoice status and file path/cloud ID');
        } else {
          print('[ExportPage]     ❌ Rejected: has invoice status but no ID or file path');
        }
        return hasFile;
      }).toList();
      
      print('[ExportPage] 🔍 Filtered ${items.length} expenses, found ${itemsWithInvoices.length} with invoices');
      for (final item in itemsWithInvoices) {
        print('[ExportPage] 📄 Expense ${item.id}: status=${item.invoiceStatus}, filePath=${item.invoiceFilePath}, cloudFileId=${item.invoiceCloudFileId}');
      }
      
      if (itemsWithInvoices.isEmpty) {
        print('[ExportPage] ⚠️ No expenses with invoices found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('no_invoices_to_export') ?? 'No invoices to export'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      print('[ExportPage] 📤 Calling PdfExportHelper.exportInvoiceImages with ${itemsWithInvoices.length} expenses');
      
      try {
        await PdfExportHelper.exportInvoiceImages(itemsWithInvoices);
        print('[ExportPage] ✅ Invoice export completed successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice export completed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (exportError, stackTrace) {
        print('[ExportPage] ❌ Error during PDF export:');
        print('[ExportPage] Error: $exportError');
        print('[ExportPage] Stack trace: $stackTrace');
        
        if (mounted) {
          // Show detailed error dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Export Error', style: TextStyle(color: Colors.red)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Failed to export invoice images:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      exportError.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    if (exportError.toString().length > 200)
                      const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    const Text('Check console logs for more details.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e, stackTrace) {
      print('[ExportPage] ❌ Fatal error in _exportInvoiceImages:');
      print('[ExportPage] Error: $e');
      print('[ExportPage] Stack trace: $stackTrace');
      
      if (mounted) {
        // Show error dialog with full details
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Export Failed', style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('An error occurred while exporting invoices:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Check the console for detailed logs.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return WatermarkBackground(
      child: BlocListener<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          // Automatically refresh when expenses are loaded
          if (state is ExpenseLoaded && mounted) {
            setState(() {});
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add refresh button
                FilledButton.icon(
                  onPressed: _busy ? null : () {
                    if (_currentUserId != null) {
                      context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.translate('refresh_data') ?? 'Refresh Data'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.translate('export_pdf') ?? 'Export PDF'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _exportExcel,
                  icon: const Icon(Icons.grid_on),
                  label: Text(l10n.translate('export_excel') ?? 'Export Excel'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _exportInvoiceImages,
                  icon: const Icon(Icons.image),
                  label: Text(l10n.translate('export_invoices') ?? 'Export Invoices'),
                ),

                if (_busy) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
