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

import '../core/config/flavor_config.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/admin/presentation/bloc/admin_bloc.dart';
import '../features/admin/presentation/bloc/admin_state.dart';
import '../features/admin/presentation/bloc/admin_event.dart';
import '../features/expenses/presentation/bloc/expense_bloc.dart';
import '../features/expenses/presentation/bloc/expense_state.dart';
import '../features/exchanges/presentation/bloc/exchange_bloc.dart';
import '../features/exchanges/presentation/bloc/exchange_state.dart';
import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../state/filters.dart';
import '../utils/pdf_export_helper.dart';
import '../core/widgets/watermark_background.dart';

class ExportPageNew extends StatefulWidget {
  const ExportPageNew({super.key});

  @override
  State<ExportPageNew> createState() => _ExportPageNewState();
}

class _ExportPageNewState extends State<ExportPageNew> {
  bool _busy = false;
  int? _currentUserId;
  int? _selectedUserId;

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
    }
    
    // Load user activity for admin flavor
    if (FlavorConfig.instance.isAdmin) {
      context.read<AdminBloc>().add(const FetchUserActivityRequested());
    }
  }

  List<ExpenseRecord> _getFilteredExpenses() {
    final expenseState = context.read<ExpenseBloc>().state;
    if (expenseState is! ExpenseLoaded) return [];

    var items = expenseState.expenses.map((e) => ExpenseRecord(
      id: e.id,
      description: e.description,
      priceUsd: e.priceUsd,
      priceSyp: e.priceSyp,
      priceTry: e.priceTry,
      invoiceStatus: InvoiceStatus.values[e.invoiceStatus.index],
      invoiceFilePath: e.invoiceCloudFileId ?? e.invoiceFilePath,
      expenseDate: e.expenseDate,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    )).toList();

    // Apply user filter if selected
    if (_selectedUserId != null) {
      // Note: This assumes expenses have userId field
      // If not available, this filter won't work
      items = items.where((e) => e.id == _selectedUserId).toList();
    }

    final currencyFilter = ExpenseFilterNotifier.instance.value;
    final dateFilter = DateFilterNotifier.instance.value;

    // Apply currency filter
    if (currencyFilter != ExpenseCurrencyFilter.all) {
      items = items.where((e) {
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
    if (dateFilter.type != DateFilterType.all) {
      final now = DateTime.now();
      items = items.where((e) {
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

    return items;
  }

  Future<void> _exportPdf() async {
    setState(() => _busy = true);
    try {
      final items = _getFilteredExpenses();

      final regularFontData = await rootBundle.load(
        'assets/fonts/Amiri-Regular.ttf',
      );
      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      final arabicFont = pw.Font.ttf(regularFontData);
      final arabicFontBold = pw.Font.ttf(boldFontData);
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

            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'description',
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
                          'فاتورة',
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
                        ? 'نعم'
                        : 'لا';
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
                'SUM',
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
                          'الإجمالي',
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
    setState(() => _busy = true);
    try {
      final items = _getFilteredExpenses();

      final book = xls.Excel.createExcel();
      final sheet = book['Expenses'];

      // Header row
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('الوصف'),
        xls.TextCellValue('دولار'),
        xls.TextCellValue('ليرة سورية'),
        xls.TextCellValue('ليرة تركية'),
        xls.TextCellValue('فاتورة'),
      ]);

      final arabicStyle = xls.CellStyle(
        fontFamily: 'Arial',
        fontSize: 12,
      );

      for (final e in items) {
        final hasInvoice = e.invoiceStatus == InvoiceStatus.invoiceAvailable;
        sheet.appendRow(<xls.CellValue?>[
          xls.TextCellValue(e.description),
          xls.TextCellValue(e.priceUsd?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(e.priceSyp?.toStringAsFixed(0) ?? '-'),
          xls.TextCellValue(e.priceTry?.toStringAsFixed(2) ?? '-'),
          xls.TextCellValue(hasInvoice ? 'نعم' : 'لا'),
        ]);

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

        if (hasInvoice) {
          final highlightStyle = xls.CellStyle(
            backgroundColorHex: xls.ExcelColor.fromHexString('#DFF0D8'),
            fontFamily: 'Arial',
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
      sheet.appendRow(<xls.CellValue?>[]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('الملخص'),
      ]);
      sheet.appendRow(<xls.CellValue?>[
        xls.TextCellValue('الإجمالي'),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceUsd ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceSyp ?? 0)).toStringAsFixed(0)),
        xls.TextCellValue(items.fold(0.0, (sum, e) => sum + (e.priceTry ?? 0)).toStringAsFixed(2)),
        xls.TextCellValue(''),
      ]);

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
    setState(() => _busy = true);
    try {
      final items = _getFilteredExpenses();
      await PdfExportHelper.exportInvoiceImages(items);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('export_error') ?? 'Export error'}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportExchanges() async {
    setState(() => _busy = true);
    try {
      final exchangeState = context.read<ExchangeBloc>().state;
      if (exchangeState is! ExchangesLoaded) {
        throw Exception('No exchanges loaded');
      }

      var exchanges = exchangeState.exchanges;
      
      // Apply user filter if selected
      if (_selectedUserId != null) {
        exchanges = exchanges.where((e) => e.userId == _selectedUserId).toList();
      }

      String? userName;
      if (_selectedUserId != null) {
        final adminState = context.read<AdminBloc>().state;
        if (adminState is AdminUserActivityLoaded) {
          final user = adminState.userActivity.firstWhere(
            (u) => u.id == _selectedUserId,
            orElse: () => adminState.userActivity.first,
          );
          userName = user.name;
        }
      }

      await PdfExportHelper.exportExchanges(
        exchanges: exchanges,
        userName: userName,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('export_error') ?? 'Export error'}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportUserData() async {
    if (_selectedUserId == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('please_select_user') ?? 'Please select a user')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Get exchanges
      final exchangeState = context.read<ExchangeBloc>().state;
      if (exchangeState is! ExchangesLoaded) {
        throw Exception('No exchanges loaded');
      }
      final exchanges = exchangeState.exchanges
          .where((e) => e.userId == _selectedUserId)
          .toList();

      // Get expenses
      final expenses = _getFilteredExpenses();

      // Get user name
      String userName = 'User';
      final adminState = context.read<AdminBloc>().state;
      if (adminState is AdminUserActivityLoaded) {
        final user = adminState.userActivity.firstWhere(
          (u) => u.id == _selectedUserId,
          orElse: () => adminState.userActivity.first,
        );
        userName = user.name;
      }

      await PdfExportHelper.exportUserData(
        exchanges: exchanges,
        expenses: expenses,
        userName: userName,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('export_error') ?? 'Export error'}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = FlavorConfig.instance.isAdmin;
    
    return WatermarkBackground(
      child: Column(
        children: [
          // User filter for admin
          if (isAdmin)
            BlocBuilder<AdminBloc, AdminState>(
              builder: (context, adminState) {
                if (adminState is AdminUserActivityLoaded) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedUserId,
                      decoration: InputDecoration(
                        labelText: l10n.translate('filter_by_user') ?? 'Filter by User',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(l10n.translate('all_users') ?? 'All Users'),
                        ),
                        ...adminState.userActivity.map((user) {
                          return DropdownMenuItem<int?>(
                            value: user.id,
                            child: Text(user.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUserId = value;
                        });
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expenses Export
                    Text(
                      l10n.translate('expenses') ?? 'Expenses',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(l10n.translate('export_pdf') ?? 'Export PDF'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportExcel,
                      icon: const Icon(Icons.grid_on),
                      label: Text(l10n.translate('export_excel') ?? 'Export Excel'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportInvoiceImages,
                      icon: const Icon(Icons.image),
                      label: Text(l10n.translate('export_invoices') ?? 'Export Invoices'),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Exchanges Export
                    Text(
                      l10n.translate('exchanges') ?? 'Exchanges',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportExchanges,
                      icon: const Icon(Icons.currency_exchange),
                      label: Text(l10n.translate('export_exchanges') ?? 'Export Exchanges'),
                    ),
                    
                    if (isAdmin) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Combined Export
                      Text(
                        l10n.translate('combined_export') ?? 'Combined Export',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _exportUserData,
                        icon: const Icon(Icons.person_pin),
                        label: Text(l10n.translate('export_user_data') ?? 'Export User Data'),
                      ),
                    ],
                    
                    if (_busy) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
