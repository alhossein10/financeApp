# Analytics Export Service - Usage Guide

## Overview
The `AnalyticsExportService` provides frontend-only export functionality for Superadmin Analytics, generating PDF and Excel reports directly on the device without requiring backend support.

## Features

### PDF Export
- Professional report layout
- Multi-page support
- Formatted tables
- Currency symbols
- Period and generation date
- Global summary section
- Individual admin group sections

### Excel Export
- Multi-sheet workbook
- Summary sheet with totals
- Detailed admin groups sheet
- Proper data types (text, int, double)
- Formatted headers
- Easy to analyze in spreadsheet software

## Dependencies

The service uses the following packages:
- `pdf: ^3.11.0` - PDF generation
- `excel: ^4.0.6` - Excel generation
- `path_provider: ^2.1.5` - File system access
- `open_filex: ^4.5.0` - Open files
- `share_plus: ^10.1.1` - Share files

## Usage

### Basic Usage

```dart
import 'package:finance_app/features/superadmin/services/analytics_export_service.dart';

final exportService = AnalyticsExportService();

// Export to PDF
final pdfPath = await exportService.exportToPdf(
  adminGroups: filteredGroups,
  period: 'month',
  generatedAt: DateTime.now(),
);

// Export to Excel
final excelPath = await exportService.exportToExcel(
  adminGroups: filteredGroups,
  period: '15days',
  generatedAt: DateTime.now(),
);

// Open the file
await exportService.openFile(pdfPath);

// Share the file
await exportService.shareFile(pdfPath, 'analytics_report.pdf');
```

### In SuperadminAnalyticsPage

The service is already integrated in the analytics page:

```dart
class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  late final AnalyticsExportService _exportService;

  @override
  void initState() {
    super.initState();
    _exportService = AnalyticsExportService();
  }

  Future<void> _exportToPdf(BuildContext context, bool isArabic) async {
    // Get filtered data
    final filteredGroups = _selectedAdminGroupId == null
        ? _analytics!.adminGroups
        : _analytics!.adminGroups
            .where((group) => group.adminGroupId == _selectedAdminGroupId)
            .toList();

    // Export
    final filePath = await _exportService.exportToPdf(
      adminGroups: filteredGroups,
      period: _selectedPeriod,
      generatedAt: _analytics!.generatedAt,
    );

    // Show success dialog
    // ... (see implementation)
  }
}
```

## PDF Report Structure

### Page Layout
- **Format:** A4
- **Margins:** 32 points on all sides
- **Font:** Default PDF font

### Sections

#### 1. Header
```
SuperAdmin Analytics Report
```

#### 2. Report Information
```
Period: Last 15 Days          Generated: 2024-01-15 10:30
```

#### 3. Global Summary Table
| Category  | Count | USD      | SYP        | TRY       |
|-----------|-------|----------|------------|-----------|
| Invoices  | 150   | $5000.00 | 2500000 ل.س | 100000.00 ₺ |
| Transfers | 100   | $10000.00| 5000000 ل.س | 200000.00 ₺ |

#### 4. Admin Group Sections
For each admin group:
```
Group Name
Group ID: 123
Admins: 5 | Users: 25

[Table with Invoice and Transfer statistics]
```

## Excel Report Structure

### Sheet 1: Summary
```
SuperAdmin Analytics Report

Period:     Last Month
Generated:  2024-01-15 10:30

Global Summary
Category    Count   USD         SYP         TRY
Invoices    150     5000.00     2500000     100000.00
Transfers   100     10000.00    5000000     200000.00
```

### Sheet 2: Admin Groups
```
Group ID | Group Name | Admins | Users | Invoice Count | Invoice USD | Invoice SYP | Invoice TRY | Transfer Count | Transfer USD | Transfer SYP | Transfer TRY
---------|------------|--------|-------|---------------|-------------|-------------|-------------|----------------|--------------|--------------|-------------
1        | Group A    | 5      | 25    | 75            | 2500.00     | 1250000     | 50000.00    | 50             | 5000.00      | 2500000      | 100000.00
2        | Group B    | 3      | 15    | 75            | 2500.00     | 1250000     | 50000.00    | 50             | 5000.00      | 2500000      | 100000.00
```

## File Management

### File Location
Files are saved to the device's temporary directory:
- **Android:** `/data/data/com.example.app/cache/`
- **iOS:** `NSTemporaryDirectory()`

### File Naming
- **PDF:** `analytics_report_[timestamp].pdf`
- **Excel:** `analytics_report_[timestamp].xlsx`

Where `[timestamp]` is milliseconds since epoch.

### File Cleanup
Temporary files are automatically cleaned by the OS. For manual cleanup:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> cleanupOldReports() async {
  final tempDir = await getTemporaryDirectory();
  final files = tempDir.listSync();
  
  for (final file in files) {
    if (file.path.contains('analytics_report_')) {
      await file.delete();
    }
  }
}
```

## Error Handling

### Common Errors

#### 1. Storage Permission Denied
```dart
try {
  final path = await exportService.exportToPdf(...);
} catch (e) {
  if (e.toString().contains('permission')) {
    // Request storage permission
  }
}
```

#### 2. Insufficient Storage
```dart
try {
  final path = await exportService.exportToExcel(...);
} catch (e) {
  if (e.toString().contains('space')) {
    // Show storage full message
  }
}
```

#### 3. File Open Failed
```dart
try {
  await exportService.openFile(path);
} catch (e) {
  // No app available to open file
  // Suggest sharing instead
}
```

## Customization

### Custom PDF Styling

Extend the service to customize PDF appearance:

```dart
class CustomAnalyticsExportService extends AnalyticsExportService {
  @override
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
          color: isHeader ? PdfColors.blue : PdfColors.black,
        ),
      ),
    );
  }
}
```

### Custom Excel Formatting

Add cell styling to Excel:

```dart
void _buildSummarySheet(Sheet sheet, ...) {
  // ... existing code ...
  
  // Style header row
  final headerStyle = CellStyle(
    backgroundColorHex: '#4472C4',
    fontColorHex: '#FFFFFF',
    bold: true,
  );
  
  for (var col = 0; col < 5; col++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 5))
      .cellStyle = headerStyle;
  }
}
```

## Performance Considerations

### Large Datasets
For admin groups with many records:

1. **Pagination:** Consider limiting to top N groups
2. **Compression:** Use PDF compression for smaller files
3. **Background Processing:** Generate in isolate for large reports

```dart
import 'dart:isolate';

Future<String> exportToPdfInBackground({
  required List<AdminGroupAnalyticsDto> adminGroups,
  required String period,
  required DateTime generatedAt,
}) async {
  final receivePort = ReceivePort();
  
  await Isolate.spawn(
    _exportPdfIsolate,
    [receivePort.sendPort, adminGroups, period, generatedAt],
  );
  
  return await receivePort.first as String;
}

void _exportPdfIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final adminGroups = args[1] as List<AdminGroupAnalyticsDto>;
  final period = args[2] as String;
  final generatedAt = args[3] as DateTime;
  
  final service = AnalyticsExportService();
  final path = await service.exportToPdf(
    adminGroups: adminGroups,
    period: period,
    generatedAt: generatedAt,
  );
  
  sendPort.send(path);
}
```

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsExportService', () {
    late AnalyticsExportService service;

    setUp(() {
      service = AnalyticsExportService();
    });

    test('exports PDF successfully', () async {
      final groups = [/* test data */];
      
      final path = await service.exportToPdf(
        adminGroups: groups,
        period: 'all',
        generatedAt: DateTime.now(),
      );
      
      expect(path, isNotEmpty);
      expect(path, contains('.pdf'));
    });

    test('exports Excel successfully', () async {
      final groups = [/* test data */];
      
      final path = await service.exportToExcel(
        adminGroups: groups,
        period: 'month',
        generatedAt: DateTime.now(),
      );
      
      expect(path, isNotEmpty);
      expect(path, contains('.xlsx'));
    });
  });
}
```

### Integration Tests

```dart
testWidgets('export PDF from analytics page', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to analytics
  await tester.tap(find.byIcon(Icons.analytics));
  await tester.pumpAndSettle();
  
  // Tap PDF export
  await tester.tap(find.byIcon(Icons.picture_as_pdf));
  await tester.pumpAndSettle();
  
  // Verify success dialog
  expect(find.text('Export Successful'), findsOneWidget);
});
```

## Best Practices

1. **Always check for null data** before exporting
2. **Show loading indicators** during generation
3. **Provide user feedback** on success/failure
4. **Offer multiple actions** (open, share, close)
5. **Handle errors gracefully** with user-friendly messages
6. **Clean up old files** periodically
7. **Test on multiple devices** (Android/iOS)
8. **Consider file size** for large datasets
9. **Use appropriate file names** with timestamps
10. **Respect user privacy** - don't upload without permission

## Troubleshooting

### PDF Generation Issues
- Ensure `pdf` package is up to date
- Check for special characters in data
- Verify page format is supported
- Test with smaller datasets first

### Excel Generation Issues
- Ensure `excel` package is up to date
- Check cell value types match
- Verify sheet names are valid
- Test with fewer columns first

### File Access Issues
- Request necessary permissions
- Check storage availability
- Verify path_provider setup
- Test on physical devices

## Future Enhancements

- [ ] Custom templates
- [ ] Chart generation in PDF
- [ ] Conditional formatting in Excel
- [ ] Email export option
- [ ] Cloud storage integration
- [ ] Scheduled exports
- [ ] Export history
- [ ] Batch export multiple periods

## Related Documentation
- [Task 14 Implementation Summary](./TASK_14_SUPERADMIN_ANALYTICS_SUMMARY.md)
- [Superadmin Analytics Quick Reference](./SUPERADMIN_ANALYTICS_QUICK_REFERENCE.md)
- [PDF Package Documentation](https://pub.dev/packages/pdf)
- [Excel Package Documentation](https://pub.dev/packages/excel)
