import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/superadmin_analytics_dto.dart';
import 'package:intl/intl.dart' as intl;

/// Service for exporting Superadmin Analytics to PDF and Excel with full Arabic support
class AnalyticsExportService {
  // Cache for Arabic fonts
  static pw.Font? _arabicRegularFont;
  static pw.Font? _arabicBoldFont;
  
  /// Load Arabic fonts for PDF generation with proper text shaping
  Future<void> _loadArabicFonts() async {
    if (_arabicRegularFont == null || _arabicBoldFont == null) {
      // Try Tajawal font first (better PDF support)
      try {
        final regularFontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
        _arabicRegularFont = pw.Font.ttf(regularFontData);
        _arabicBoldFont = pw.Font.ttf(regularFontData); // Use same for bold
      } catch (e) {
        // Fallback to Amiri
        final regularFontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
        final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
        
        _arabicRegularFont = pw.Font.ttf(regularFontData);
        _arabicBoldFont = pw.Font.ttf(boldFontData);
      }
    }
  }
  
  /// Check if current locale is Arabic
  bool get _isArabic {
    return intl.Intl.getCurrentLocale().startsWith('ar');
  }
  
  /// Get appropriate font based on weight
  pw.Font _getFont({bool bold = false}) {
    if (bold) {
      return _arabicBoldFont ?? pw.Font.helveticaBold();
    }
    return _arabicRegularFont ?? pw.Font.helvetica();
  }
  
  /// Get text direction based on locale
  pw.TextDirection get _textDirection {
    return _isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  }
  
  /// Helper to wrap text with proper directionality for Arabic support
  pw.Widget _arabicText(String text, {double fontSize = 10, bool bold = false}) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _getFont(bold: bold),
          fontSize: fontSize,
        ),
      ),
    );
  }
  
  /// Localized strings - Arabic text will be handled by the font
  String get _reportTitle => _isArabic ? 'تقرير تحليلات المدير الأعلى' : 'SuperAdmin Analytics Report';
  String get _periodLabel => _isArabic ? 'الفترة:' : 'Period:';
  String get _generatedLabel => _isArabic ? 'تم الإنشاء:' : 'Generated:';
  String get _globalSummaryTitle => _isArabic ? 'الملخص العام' : 'Global Summary';
  String get _adminGroupsTitle => _isArabic ? 'تحليلات مجموعات المسؤولين' : 'Admin Groups Analytics';
  String get _categoryLabel => _isArabic ? 'الفئة' : 'Category';
  String get _countLabel => _isArabic ? 'العدد' : 'Count';
  String get _invoicesLabel => _isArabic ? 'الفواتير' : 'Invoices';
  String get _transfersLabel => _isArabic ? 'التحويلات' : 'Transfers';
  String get _groupIdLabel => _isArabic ? 'معرف المجموعة:' : 'Group ID:';
  String get _adminsLabel => _isArabic ? 'المسؤولون:' : 'Admins:';
  String get _usersLabel => _isArabic ? 'المستخدمون:' : 'Users:';
  String get _typeLabel => _isArabic ? 'النوع' : 'Type';
  
  /// Export analytics to PDF with full Arabic support
  Future<String> exportToPdf({
    required List<AdminGroupAnalyticsDto> adminGroups,
    required String period,
    required DateTime generatedAt,
  }) async {
    // Load Arabic fonts first
    await _loadArabicFonts();
    
    final pdf = pw.Document();

    // Calculate totals
    final totals = _calculateTotals(adminGroups);

    // Add pages with Arabic font support
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _getFont(),
          bold: _getFont(bold: true),
        ),
        textDirection: _textDirection,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: _arabicText(_reportTitle, fontSize: 24, bold: true),
          ),
          pw.SizedBox(height: 10),
          
          // Report Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _arabicText('$_periodLabel ${_formatPeriod(period)}'),
              _arabicText('$_generatedLabel ${_formatDateTime(generatedAt)}'),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Global Summary
          pw.Header(
            level: 1,
            child: _arabicText(_globalSummaryTitle, fontSize: 18, bold: true),
          ),
          pw.SizedBox(height: 10),
          
          _buildGlobalSummaryTable(totals),
          pw.SizedBox(height: 30),

          // Admin Groups
          pw.Header(
            level: 1,
            child: _arabicText(_adminGroupsTitle, fontSize: 18, bold: true),
          ),
          pw.SizedBox(height: 10),

          ...adminGroups.map((group) => _buildAdminGroupSection(group)),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${output.path}/analytics_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export analytics to Excel
  Future<String> exportToExcel({
    required List<AdminGroupAnalyticsDto> adminGroups,
    required String period,
    required DateTime generatedAt,
  }) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');

    // Create Summary sheet
    final summarySheet = excel['Summary'];
    _buildSummarySheet(summarySheet, adminGroups, period, generatedAt);

    // Create Admin Groups sheet
    final groupsSheet = excel['Admin Groups'];
    _buildAdminGroupsSheet(groupsSheet, adminGroups);

    // Save Excel
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${output.path}/analytics_report_$timestamp.xlsx');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }

  /// Open exported file
  Future<void> openFile(String filePath) async {
    await OpenFilex.open(filePath);
  }

  /// Share exported file
  Future<void> shareFile(String filePath, String fileName) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: fileName,
    );
  }

  // Helper methods

  Map<String, dynamic> _calculateTotals(List<AdminGroupAnalyticsDto> groups) {
    int invoiceCount = 0;
    double invoiceUsd = 0.0;
    double invoiceSyp = 0.0;
    double invoiceTry = 0.0;

    int transferCount = 0;
    double transferUsd = 0.0;
    double transferSyp = 0.0;
    double transferTry = 0.0;

    for (final group in groups) {
      invoiceCount += group.expensesCount;
      invoiceUsd += group.expensesTotalUsd;
      invoiceSyp += group.expensesTotalSyp;
      invoiceTry += group.expensesTotalTry;

      transferCount += group.transfersCount;
      transferUsd += group.transfersTotalUsd;
      transferSyp += group.transfersTotalSyp;
      transferTry += group.transfersTotalTry;
    }

    return {
      'invoiceCount': invoiceCount,
      'invoiceUsd': invoiceUsd,
      'invoiceSyp': invoiceSyp,
      'invoiceTry': invoiceTry,
      'transferCount': transferCount,
      'transferUsd': transferUsd,
      'transferSyp': transferSyp,
      'transferTry': transferTry,
    };
  }

  pw.Widget _buildGlobalSummaryTable(Map<String, dynamic> totals) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header - reverse column order for Arabic
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: _isArabic ? [
            _buildTableCell('TRY', isHeader: true),
            _buildTableCell('SYP', isHeader: true),
            _buildTableCell('USD', isHeader: true),
            _buildTableCell(_countLabel, isHeader: true),
            _buildTableCell(_categoryLabel, isHeader: true),
          ] : [
            _buildTableCell(_categoryLabel, isHeader: true),
            _buildTableCell(_countLabel, isHeader: true),
            _buildTableCell('USD', isHeader: true),
            _buildTableCell('SYP', isHeader: true),
            _buildTableCell('TRY', isHeader: true),
          ],
        ),
        // Invoices - reverse column order for Arabic
        pw.TableRow(
          children: _isArabic ? [
            _buildTableCell(totals['invoiceTry'].toStringAsFixed(2)),
            _buildTableCell(totals['invoiceSyp'].toStringAsFixed(0)),
            _buildTableCell(totals['invoiceUsd'].toStringAsFixed(2)),
            _buildTableCell(totals['invoiceCount'].toString()),
            _buildTableCell(_invoicesLabel),
          ] : [
            _buildTableCell(_invoicesLabel),
            _buildTableCell(totals['invoiceCount'].toString()),
            _buildTableCell(totals['invoiceUsd'].toStringAsFixed(2)),
            _buildTableCell(totals['invoiceSyp'].toStringAsFixed(0)),
            _buildTableCell(totals['invoiceTry'].toStringAsFixed(2)),
          ],
        ),
        // Transfers - reverse column order for Arabic
        pw.TableRow(
          children: _isArabic ? [
            _buildTableCell(totals['transferTry'].toStringAsFixed(2)),
            _buildTableCell(totals['transferSyp'].toStringAsFixed(0)),
            _buildTableCell(totals['transferUsd'].toStringAsFixed(2)),
            _buildTableCell(totals['transferCount'].toString()),
            _buildTableCell(_transfersLabel),
          ] : [
            _buildTableCell(_transfersLabel),
            _buildTableCell(totals['transferCount'].toString()),
            _buildTableCell(totals['transferUsd'].toStringAsFixed(2)),
            _buildTableCell(totals['transferSyp'].toStringAsFixed(0)),
            _buildTableCell(totals['transferTry'].toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAdminGroupSection(AdminGroupAnalyticsDto group) {
    return pw.Column(
      crossAxisAlignment: _isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        _arabicText(group.adminGroupName, fontSize: 14, bold: true),
        pw.SizedBox(height: 5),
        _arabicText('$_groupIdLabel${group.adminGroupId}'),
        _arabicText('$_adminsLabel${1} | $_usersLabel${0}'),
        pw.SizedBox(height: 10),
        
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: _isArabic ? [
                _buildTableCell('TRY', isHeader: true),
                _buildTableCell('SYP', isHeader: true),
                _buildTableCell('USD', isHeader: true),
                _buildTableCell(_countLabel, isHeader: true),
                _buildTableCell(_typeLabel, isHeader: true),
              ] : [
                _buildTableCell(_typeLabel, isHeader: true),
                _buildTableCell(_countLabel, isHeader: true),
                _buildTableCell('USD', isHeader: true),
                _buildTableCell('SYP', isHeader: true),
                _buildTableCell('TRY', isHeader: true),
              ],
            ),
            pw.TableRow(
              children: _isArabic ? [
                _buildTableCell(group.expensesTotalTry.toStringAsFixed(2)),
                _buildTableCell(group.expensesTotalSyp.toStringAsFixed(0)),
                _buildTableCell(group.expensesTotalUsd.toStringAsFixed(2)),
                _buildTableCell(group.expensesCount.toString()),
                _buildTableCell(_invoicesLabel),
              ] : [
                _buildTableCell(_invoicesLabel),
                _buildTableCell(group.expensesCount.toString()),
                _buildTableCell(group.expensesTotalUsd.toStringAsFixed(2)),
                _buildTableCell(group.expensesTotalSyp.toStringAsFixed(0)),
                _buildTableCell(group.expensesTotalTry.toStringAsFixed(2)),
              ],
            ),
            pw.TableRow(
              children: _isArabic ? [
                _buildTableCell(group.transfersTotalTry.toStringAsFixed(2)),
                _buildTableCell(group.transfersTotalSyp.toStringAsFixed(0)),
                _buildTableCell(group.transfersTotalUsd.toStringAsFixed(2)),
                _buildTableCell(group.transfersCount.toString()),
                _buildTableCell(_transfersLabel),
              ] : [
                _buildTableCell(_transfersLabel),
                _buildTableCell(group.transfersCount.toString()),
                _buildTableCell(group.transfersTotalUsd.toStringAsFixed(2)),
                _buildTableCell(group.transfersTotalSyp.toStringAsFixed(0)),
                _buildTableCell(group.transfersTotalTry.toStringAsFixed(2)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: _getFont(bold: isHeader),
            fontSize: isHeader ? 10 : 9,
          ),
        ),
      ),
    );
  }

  void _buildSummarySheet(
    Sheet sheet,
    List<AdminGroupAnalyticsDto> groups,
    String period,
    DateTime generatedAt,
  ) {
    final totals = _calculateTotals(groups);

    // Title
    sheet.appendRow([
      TextCellValue(_isArabic ? 'تقرير تحليلات المدير الأعلى' : 'SuperAdmin Analytics Report'),
    ]);
    sheet.appendRow([]);
    
    // Info
    sheet.appendRow([
      TextCellValue(_periodLabel),
      TextCellValue(_formatPeriod(period)),
    ]);
    sheet.appendRow([
      TextCellValue(_generatedLabel),
      TextCellValue(_formatDateTime(generatedAt)),
    ]);
    sheet.appendRow([]);

    // Global Summary Header
    sheet.appendRow([
      TextCellValue(_globalSummaryTitle),
    ]);
    sheet.appendRow([
      TextCellValue(_categoryLabel),
      TextCellValue(_countLabel),
      TextCellValue('USD'),
      TextCellValue('SYP'),
      TextCellValue('TRY'),
    ]);

    // Invoices
    sheet.appendRow([
      TextCellValue(_invoicesLabel),
      IntCellValue(totals['invoiceCount'] as int),
      DoubleCellValue(totals['invoiceUsd'] as double),
      DoubleCellValue(totals['invoiceSyp'] as double),
      DoubleCellValue(totals['invoiceTry'] as double),
    ]);

    // Transfers
    sheet.appendRow([
      TextCellValue(_transfersLabel),
      IntCellValue(totals['transferCount'] as int),
      DoubleCellValue(totals['transferUsd'] as double),
      DoubleCellValue(totals['transferSyp'] as double),
      DoubleCellValue(totals['transferTry'] as double),
    ]);
  }

  void _buildAdminGroupsSheet(
    Sheet sheet,
    List<AdminGroupAnalyticsDto> groups,
  ) {
    // Header
    sheet.appendRow([
      TextCellValue(_isArabic ? 'معرف المجموعة' : 'Group ID'),
      TextCellValue(_isArabic ? 'اسم المجموعة' : 'Group Name'),
      TextCellValue(_adminsLabel),
      TextCellValue(_usersLabel),
      TextCellValue(_isArabic ? 'عدد الفواتير' : 'Invoice Count'),
      TextCellValue(_isArabic ? 'فواتير USD' : 'Invoice USD'),
      TextCellValue(_isArabic ? 'فواتير SYP' : 'Invoice SYP'),
      TextCellValue(_isArabic ? 'فواتير TRY' : 'Invoice TRY'),
      TextCellValue(_isArabic ? 'عدد التحويلات' : 'Transfer Count'),
      TextCellValue(_isArabic ? 'تحويلات USD' : 'Transfer USD'),
      TextCellValue(_isArabic ? 'تحويلات SYP' : 'Transfer SYP'),
      TextCellValue(_isArabic ? 'تحويلات TRY' : 'Transfer TRY'),
    ]);

    // Data rows
    for (final group in groups) {
      sheet.appendRow([
        IntCellValue(group.adminGroupId),
        TextCellValue(group.adminGroupName),
        IntCellValue(1),
        IntCellValue(0),
        IntCellValue(group.expensesCount),
        DoubleCellValue(group.expensesTotalUsd),
        DoubleCellValue(group.expensesTotalSyp),
        DoubleCellValue(group.expensesTotalTry),
        IntCellValue(group.transfersCount),
        DoubleCellValue(group.transfersTotalUsd),
        DoubleCellValue(group.transfersTotalSyp),
        DoubleCellValue(group.transfersTotalTry),
      ]);
    }
  }

  String _formatPeriod(String period) {
    if (_isArabic) {
      switch (period) {
        case '15days':
          return 'آخر 15 يوم';
        case 'month':
          return 'الشهر الماضي';
        case 'all':
          return 'كل الوقت';
        default:
          return period;
      }
    } else {
      switch (period) {
        case '15days':
          return 'Last 15 Days';
        case 'month':
          return 'Last Month';
        case 'all':
          return 'All Time';
        default:
          return period;
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
