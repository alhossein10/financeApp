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

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../../../features/expenses/presentation/bloc/expense_event.dart';
import '../../../../features/expenses/presentation/bloc/expense_state.dart';
import '../../../../features/expenses/domain/entities/expense.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/watermark_background.dart';
import '../../../../state/filters.dart';
import '../../../../models/expense.dart' as models;
import '../../../../utils/pdf_export_helper.dart';

/// User Export Page
/// Exports ONLY the user's own expenses with filters applied from the Expenses page
class UserExportPage extends StatefulWidget {
  const UserExportPage({super.key});

  @override
  State<UserExportPage> createState() => _UserExportPageState();
}

class _UserExportPageState extends State<UserExportPage> {
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
      final expenseState = context.read<ExpenseBloc>().state;
      if (expenseState is! ExpenseLoaded) {
        context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
      }
    }
  }

  /// Get filtered expenses based on active filters from ExpensePage
  /// User flavor only exports their own expenses
  Future<List<Expense>> _getFilteredExpenses() async {
    final expenseState = context.read<ExpenseBloc>().state;
    if (expenseState is! ExpenseLoaded) return [];

    var expenses = List<Expense>.from(expenseState.expenses);

    // Apply currency filter
    final currencyFilter = ExpenseFilterNotifier.instance.value;
    if (currencyFilter != ExpenseCurrencyFilter.all) {
      expenses = expenses.where((e) {
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

    // Apply date filter
    final dateFilter = DateFilterNotifier.instance.value;
    if (dateFilter.type != DateFilterType.all) {
      final now = DateTime.now();
      expenses = expenses.where((e) {
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
    }

    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WatermarkBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.exportMyExpenses),
          centerTitle: true,
        ),
        body: BlocListener<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseLoaded && mounted) {
              setState(() {});
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(l10n),
                const SizedBox(height: 16),
                _buildActiveFiltersCard(l10n),
                const SizedBox(height: 24),
                _buildExportOptionsCard(l10n),
                if (_busy) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.exportUserInfo,
                style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersCard(AppLocalizations l10n) {
    final currencyFilter = ExpenseFilterNotifier.instance.value;
    final dateFilter = DateFilterNotifier.instance.value;
    
    final hasFilters = currencyFilter != ExpenseCurrencyFilter.all ||
        dateFilter.type != DateFilterType.all;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.activeFilters,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasFilters)
              Text(
                l10n.noFiltersApplied,
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (currencyFilter != ExpenseCurrencyFilter.all)
                    Chip(
                      avatar: const Icon(Icons.attach_money, size: 16),
                      label: Text(currencyFilter.name.toUpperCase()),
                    ),
                  if (dateFilter.type != DateFilterType.all)
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_getDateFilterLabel(dateFilter)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              l10n.exportWillApplyFilters,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateFilterLabel(DateFilter filter) {
    switch (filter.type) {
      case DateFilterType.today:
        return 'Today';
      case DateFilterType.thisWeek:
        return 'This Week';
      case DateFilterType.thisMonth:
        return 'This Month';
      case DateFilterType.custom:
        if (filter.startDate != null && filter.endDate != null) {
          return '${filter.startDate!.day}/${filter.startDate!.month} - ${filter.endDate!.day}/${filter.endDate!.month}';
        }
        return 'Custom';
      case DateFilterType.all:
        return 'All';
    }
  }

  Widget _buildExportOptionsCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportOptions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildExportButton(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              label: l10n.exportToPdf,
              description: l10n.exportPdfDescription,
              onPressed: _busy ? null : _exportToPdf,
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              icon: Icons.grid_on,
              iconColor: Colors.green,
              label: l10n.exportToExcel,
              description: l10n.exportExcelDescription,
              onPressed: _busy ? null : _exportToExcel,
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              icon: Icons.photo_library,
              iconColor: Colors.blue,
              label: l10n.exportInvoiceImages,
              description: l10n.exportInvoicesDescription,
              onPressed: _busy ? null : _exportInvoiceImages,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final expenses = await _getFilteredExpenses();
      
      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noExpensesToExport)),
          );
        }
        return;
      }

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
                'My Expenses',
                style: pw.TextStyle(font: arabicFont, fontSize: 18),
              ),
            ),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('USD', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('SYP', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('TRY', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Invoice', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      ),
                    ],
                  ),
                  ...expenses.map((e) {
                    final invoiceText = e.invoiceStatus == InvoiceStatus.invoiceAvailable ? 'Yes' : 'No';
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.description, style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceUsd?.toStringAsFixed(2) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceSyp?.toStringAsFixed(0) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(e.priceTry?.toStringAsFixed(2) ?? '-', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(invoiceText, style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.Header(
              level: 1,
              child: pw.Text('Summary', style: pw.TextStyle(font: arabicFont, fontSize: 16)),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Total USD: ${expenses.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0)).toStringAsFixed(2)}',
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
            pw.Text(
              'Total SYP: ${expenses.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0)).toStringAsFixed(0)}',
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
            pw.Text(
              'Total TRY: ${expenses.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0)).toStringAsFixed(2)}',
              style: pw.TextStyle(font: arabicFont, fontSize: 12),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'my_expenses.pdf'));
      await file.writeAsBytes(await doc.save());
      await OpenFilex.open(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportCompleted), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportToExcel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final expenses = await _getFilteredExpenses();
      
      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noExpensesToExport)),
          );
        }
        return;
      }

      final book = xls.Excel.createExcel();
      final sheet = book['My Expenses'];

      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Description'),
        xls.TextCellValue('USD'),
        xls.TextCellValue('SYP'),
        xls.TextCellValue('TRY'),
        xls.TextCellValue('Invoice'),
      ]);

      for (final e in expenses) {
        final hasInvoice = e.invoiceStatus == InvoiceStatus.invoiceAvailable;
        sheet.appendRow(<xls.CellValue?>[
          xls.TextCellValue(e.description),
          xls.TextCellValue(e.priceUsd?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(e.priceSyp?.toStringAsFixed(0) ?? '-'),
          xls.TextCellValue(e.priceTry?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(hasInvoice ? 'Yes' : 'No'),
        ]);
      }

      sheet.appendRow(<xls.CellValue?>[]);
      sheet.appendRow(<xls.CellValue?>[xls.TextCellValue('Summary')]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('Total'),
        xls.TextCellValue(expenses.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(expenses.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0)).toStringAsFixed(0)),
        xls.TextCellValue(expenses.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(''),
      ]);

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'my_expenses.xlsx'));
      final bytes = book.save(fileName: 'my_expenses.xlsx');
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(file.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportCompleted), backgroundColor: Colors.green),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportInvoiceImages() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    
    try {
      // Get expense state directly to check what we have
      final expenseState = context.read<ExpenseBloc>().state;
      if (expenseState is! ExpenseLoaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for expenses to load'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Debug: Log total expenses and invoices
      final allExpenses = expenseState.expenses;
      final allWithInvoices = allExpenses.where((e) => 
        e.invoiceStatus == InvoiceStatus.invoiceAvailable
      ).length;
      print('[Export] Total expenses: ${allExpenses.length}, With invoices: $allWithInvoices');
      
      final expenses = await _getFilteredExpenses();
      print('[Export] After filters: ${expenses.length} expenses');
      
      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noExpensesToExport)),
          );
        }
        return;
      }

      // Filter for expenses with invoices BEFORE converting
      final expensesWithInvoices = expenses.where((e) {
        final hasInvoice = e.invoiceStatus == InvoiceStatus.invoiceAvailable;
        if (hasInvoice) {
          print('[Export] Expense ${e.id} has invoice: path=${e.invoiceFilePath}, cloudId=${e.invoiceCloudFileId}');
        }
        return hasInvoice;
      }).toList();

      print('[Export] Filtered expenses with invoices: ${expensesWithInvoices.length}');

      if (expensesWithInvoices.isEmpty) {
        if (mounted) {
          // Show more helpful message
          final currencyFilter = ExpenseFilterNotifier.instance.value;
          final dateFilter = DateFilterNotifier.instance.value;
          String message = l10n.noInvoicesToExport;
          
          if (currencyFilter != ExpenseCurrencyFilter.all || dateFilter.type != DateFilterType.all) {
            message += '\n\nTry removing filters to see all invoices';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Convert to ExpenseRecord for PdfExportHelper
      final expenseRecords = expensesWithInvoices.map((e) {
        return models.ExpenseRecord(
          id: e.id,
          description: e.description,
          priceUsd: e.priceUsd,
          priceSyp: e.priceSyp,
          priceTry: e.priceTry,
          invoiceStatus: models.InvoiceStatus.values[e.invoiceStatus.index],
          invoiceFilePath: e.invoiceCloudFileId ?? e.invoiceFilePath,
          invoiceCloudFileId: e.invoiceCloudFileId,
          expenseDate: e.expenseDate,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
        );
      }).toList();

      print('[Export] Starting PDF export with ${expenseRecords.length} records');
      await PdfExportHelper.exportInvoiceImages(expenseRecords);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportCompleted} (${expensesWithInvoices.length} invoices)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[Export] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
