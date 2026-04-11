# Export Feature Usage Guide

## Quick Start

### For Users
1. Open the app and login
2. Tap the **Export** icon in the bottom navigation
3. (Optional) Select a date range using the calendar pickers
4. Select export format: **PDF** or **Excel**
5. Tap the **Export** button
6. Wait for the export to complete (status updates automatically)
7. File downloads automatically when ready
8. Tap **Open File** to view the export

### For Developers

#### Access ExportBloc
```dart
// Get ExportBloc from dependency injection
final exportBloc = di.sl<ExportBloc>();

// Or use BlocProvider in widget tree
final exportBloc = context.read<ExportBloc>();
```

#### Request PDF Export
```dart
context.read<ExportBloc>().add(
  RequestPdfExportEvent(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ),
);
```

#### Request Excel Export
```dart
context.read<ExportBloc>().add(
  RequestExcelExportEvent(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ),
);
```

#### Listen to Export States
```dart
BlocListener<ExportBloc, ExportState>(
  listener: (context, state) {
    if (state is ExportReady) {
      print('Export ready: ${state.exportId}');
    } else if (state is ExportFailed) {
      print('Export failed: ${state.message}');
    }
  },
  child: YourWidget(),
);
```

## UI Components

### Date Range Picker
- **Start Date**: Select the beginning of the date range
- **End Date**: Select the end of the date range
- **Clear Dates**: Reset both dates to export all data

### Format Selection
- **PDF**: Export as PDF document (red icon)
- **Excel**: Export as Excel spreadsheet (green icon)

### Export Button
- **Enabled**: Ready to export
- **Disabled**: Export in progress
- **Loading**: Shows spinner during export

### Status Display
Shows current export status with icon and message:
- 🔵 **Requesting**: Sending export request to server
- 🟠 **Queued**: Export queued for processing
- 🔵 **Processing**: Export being generated (with progress %)
- 🟢 **Ready**: Export ready for download
- 🔵 **Downloading**: Downloading export file (with progress %)
- 🟢 **Completed**: Export downloaded successfully
- 🔴 **Failed**: Export failed (with error message)

## Export Flow

### Successful Export
```
User taps "Export"
  ↓
Status: "Requesting export..."
  ↓
Status: "Export queued"
  ↓
Status: "Processing export... 25%"
  ↓ (polling every 2 seconds)
Status: "Processing export... 50%"
  ↓ (polling every 2 seconds)
Status: "Processing export... 75%"
  ↓ (polling every 2 seconds)
Status: "Export ready"
  ↓ (automatic download)
Status: "Downloading export... 50%"
  ↓
Status: "Export completed"
  ↓
User taps "Open File"
  ↓
File opens in default viewer
```

### Failed Export with Retry
```
User taps "Export"
  ↓
Status: "Requesting export..."
  ↓
Network error occurs
  ↓
Status: "Export failed: Network error"
  ↓
User taps "Retry"
  ↓
Export re-attempted with same parameters
  ↓
Status: "Requesting export..."
  ↓
... continues to successful export
```

## API Integration

### Automatic Bearer Token
All export API calls automatically include Bearer token:

```dart
// You don't need to manually add the token
final response = await exportApiDataSource.exportExpensesToPdf();

// The ApiClient automatically adds:
// Authorization: Bearer {token}
```

### Token Refresh
If token expires during export:
1. `BearerTokenInterceptor` detects 401 error
2. Automatically refreshes token
3. Retries original request with new token
4. Export continues seamlessly

### Error Handling
```dart
try {
  final response = await exportApiDataSource.exportExpensesToPdf();
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Unauthorized - token expired
  } else if (e.statusCode == 403) {
    // Forbidden - insufficient permissions
  } else if (e.statusCode == 422) {
    // Validation error
  } else if (e.statusCode == 500) {
    // Server error
  }
}
```

## Customization

### Change Polling Interval
In `lib/features/export/presentation/bloc/export_bloc.dart`:

```dart
_statusPollTimer = Timer.periodic(
  const Duration(seconds: 2), // Change this value
  (_) => add(CheckExportStatusEvent(exportId)),
);
```

### Change Export File Location
In `lib/features/export/presentation/pages/export_page.dart`:

```dart
Future<void> _downloadExport(String exportId) async {
  // Change this to your preferred directory
  final directory = await getApplicationDocumentsDirectory();
  final savePath = '${directory.path}/export_$timestamp.$extension';
  
  context.read<ExportBloc>().add(
    DownloadExportEvent(exportId: exportId, savePath: savePath),
  );
}
```

### Customize Export Filename
```dart
// Current format: export_YYYYMMDD_HHMMSS.pdf
final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
final fileName = 'export_$timestamp.$extension';

// Custom format: expenses_January_2024.pdf
final monthYear = DateFormat('MMMM_yyyy').format(DateTime.now());
final fileName = 'expenses_$monthYear.$extension';
```

## Localization

### Add Translations
In `lib/l10n/app_localizations.dart`:

```dart
// English
'export_data': 'Export Data',
'date_range': 'Date Range',
'start_date': 'Start Date',
'end_date': 'End Date',
'export_format': 'Export Format',
'pdf': 'PDF',
'excel': 'Excel',
'export': 'Export',
'exporting': 'Exporting...',

// Arabic
'export_data': 'تصدير البيانات',
'date_range': 'نطاق التاريخ',
'start_date': 'تاريخ البداية',
'end_date': 'تاريخ النهاية',
'export_format': 'صيغة التصدير',
'pdf': 'PDF',
'excel': 'Excel',
'export': 'تصدير',
'exporting': 'جاري التصدير...',
```

### Use Translations
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.translate('export_data') ?? 'Export Data');
```

## Testing

### Manual Testing Checklist
- [ ] Open export page
- [ ] Select start date
- [ ] Select end date
- [ ] Verify end date validation (must be after start date)
- [ ] Clear dates
- [ ] Select PDF format
- [ ] Select Excel format
- [ ] Tap export button
- [ ] Verify status updates
- [ ] Verify progress indicators
- [ ] Verify automatic download
- [ ] Open downloaded file
- [ ] Simulate network error
- [ ] Verify error display
- [ ] Tap retry button
- [ ] Verify retry works
- [ ] Tap cancel button
- [ ] Verify reset to initial state

### Unit Testing
```dart
test('RequestPdfExportEvent should emit ExportRequesting then ExportQueued', () async {
  // Arrange
  final mockDataSource = MockExportApiDataSource();
  final bloc = ExportBloc(exportApiDataSource: mockDataSource);
  
  when(mockDataSource.exportExpensesToPdf(any, any))
      .thenAnswer((_) async => ExportResponseDto(
            id: 123,
            format: 'pdf',
            status: 'queued',
          ));
  
  // Act
  bloc.add(RequestPdfExportEvent(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ));
  
  // Assert
  await expectLater(
    bloc.stream,
    emitsInOrder([
      isA<ExportRequesting>(),
      isA<ExportQueued>(),
    ]),
  );
});
```

### Widget Testing
```dart
testWidgets('Export button should trigger export', (tester) async {
  // Arrange
  final mockBloc = MockExportBloc();
  when(mockBloc.state).thenReturn(const ExportInitial());
  
  await tester.pumpWidget(
    BlocProvider<ExportBloc>.value(
      value: mockBloc,
      child: const MaterialApp(home: ExportPage()),
    ),
  );
  
  // Act
  await tester.tap(find.text('Export'));
  await tester.pump();
  
  // Assert
  verify(mockBloc.add(any)).called(1);
});
```

## Troubleshooting

### Export Not Starting
**Symptoms:**
- Tap export button, nothing happens
- No status updates

**Solutions:**
1. Check network connectivity
2. Verify user is authenticated
3. Check Bearer token is valid
4. Review console logs for errors

### Status Stuck on "Requesting"
**Symptoms:**
- Status shows "Requesting export..." forever
- No progress updates

**Solutions:**
1. Check backend API is running
2. Verify export endpoint is accessible
3. Check backend logs for errors
4. Verify polling is working (network tab)

### Download Fails
**Symptoms:**
- Export completes but download fails
- Error message about file permissions

**Solutions:**
1. Check storage permissions
2. Verify available storage space
3. Check file path is valid
4. Try different download location

### File Won't Open
**Symptoms:**
- Download succeeds but file won't open
- "No app found to open file" error

**Solutions:**
1. Install PDF/Excel viewer app
2. Check file is not corrupted
3. Verify file extension is correct
4. Try opening file manually from file manager

## Best Practices

### 1. Always Handle Errors
```dart
BlocListener<ExportBloc, ExportState>(
  listener: (context, state) {
    if (state is ExportFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              context.read<ExportBloc>().add(const RetryExportEvent());
            },
          ),
        ),
      );
    }
  },
  child: ExportUI(),
);
```

### 2. Show Loading Indicators
```dart
BlocBuilder<ExportBloc, ExportState>(
  builder: (context, state) {
    if (state is ExportRequesting || state is ExportProcessing) {
      return const CircularProgressIndicator();
    }
    return ExportButton();
  },
);
```

### 3. Validate Date Ranges
```dart
Future<void> _selectEndDate(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: _endDate ?? _startDate ?? DateTime.now(),
    firstDate: _startDate ?? DateTime(2020), // End date must be after start date
    lastDate: DateTime.now(),
  );
  
  if (picked != null) {
    setState(() => _endDate = picked);
  }
}
```

### 4. Clean Up Resources
```dart
@override
void dispose() {
  // Cancel export if page is closed
  context.read<ExportBloc>().add(const CancelExportEvent());
  super.dispose();
}
```

### 5. Provide User Feedback
```dart
if (state is ExportDownloaded) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Export downloaded successfully'),
      backgroundColor: Colors.green,
      action: SnackBarAction(
        label: 'Open',
        onPressed: () => _openFile(state.filePath),
      ),
    ),
  );
}
```

## Additional Resources

- [Export API Quick Reference](EXPORT_API_QUICK_REFERENCE.md)
- [Export API Verification](TASK_10_EXPORT_API_VERIFICATION.md)
- [Export UI Implementation](TASK_10.1_EXPORT_UI_SUMMARY.md)
- [Export Integration Complete](EXPORT_INTEGRATION_COMPLETE.md)
- [Bearer Token Verification](../core/api/BEARER_TOKEN_VERIFICATION.md)

## Support

For issues or questions:
1. Check console logs for errors
2. Review API documentation
3. Test with Postman
4. Check backend logs
5. Contact backend team if API issues persist
