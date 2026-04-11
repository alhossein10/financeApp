# Export API Quick Reference

## Overview
Quick reference guide for using the Export API with Bearer token authentication.

## API Endpoints

### 1. Export Expenses to PDF
```dart
// Request PDF export
final response = await exportApiDataSource.exportExpensesToPdf(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);

// Response
ExportResponseDto {
  id: 123,
  format: 'pdf',
  status: 'processing', // or 'completed', 'failed'
  downloadUrl: null, // or URL if completed
}
```

**Endpoint:** `POST /export/expenses/pdf`  
**Auth:** Bearer token (automatic)  
**Body:**
```json
{
  "format": "pdf",
  "date_from": "2024-01-01",
  "date_to": "2024-12-31"
}
```

### 2. Export Expenses to Excel
```dart
// Request Excel export
final response = await exportApiDataSource.exportExpensesToExcel(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);

// Response
ExportResponseDto {
  id: 124,
  format: 'excel',
  status: 'completed',
  downloadUrl: 'https://api.example.com/export/124/download',
}
```

**Endpoint:** `POST /export/expenses/excel`  
**Auth:** Bearer token (automatic)  
**Body:**
```json
{
  "format": "excel",
  "date_from": "2024-01-01",
  "date_to": "2024-12-31"
}
```

### 3. Get Export Status
```dart
// Check export status
final status = await exportApiDataSource.getExportStatus('123');

// Response
ExportStatusDto {
  id: 123,
  format: 'pdf',
  status: 'processing',
  progress: 75,
  downloadUrl: null,
}
```

**Endpoint:** `GET /export/{id}/status`  
**Auth:** Bearer token (automatic)  
**Note:** May not be available in all backends

### 4. Download Export
```dart
// Download completed export
final filePath = await exportApiDataSource.downloadExport(
  '123',
  '/path/to/save/export.pdf',
);

// Returns: '/path/to/save/export.pdf'
```

**Endpoint:** `GET /export/{id}/download`  
**Auth:** Bearer token (automatic)  
**Response:** File bytes

### 5. Export System-Wide (Admin Only)
```dart
// Request system-wide export (Admin only)
final response = await exportApiDataSource.exportSystemWide(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
  format: 'pdf', // or 'excel'
);

// Response
ExportResponseDto {
  id: 125,
  format: 'pdf',
  status: 'processing',
  downloadUrl: null,
}
```

**Endpoint:** `POST /export/system-wide`  
**Auth:** Bearer token (automatic, admin role required)  
**Body:**
```json
{
  "format": "pdf",
  "date_from": "2024-01-01",
  "date_to": "2024-12-31"
}
```

### 6. Get Exports List
```dart
// Get list of exports
final exports = await exportApiDataSource.getExports();

// Response
List<ExportResponseDto> [
  ExportResponseDto { id: 123, format: 'pdf', status: 'completed', ... },
  ExportResponseDto { id: 124, format: 'excel', status: 'processing', ... },
]
```

**Endpoint:** `GET /export`  
**Auth:** Bearer token (automatic)  
**Response:**
```json
{
  "data": [
    { "id": 123, "format": "pdf", "status": "completed", "download_url": "..." },
    { "id": 124, "format": "excel", "status": "processing", "download_url": null }
  ]
}
```

## Using the Export BLoC

### Request Export
```dart
// Request PDF export
context.read<ExportBloc>().add(
  RequestPdfExportEvent(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ),
);

// Request Excel export
context.read<ExportBloc>().add(
  RequestExcelExportEvent(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ),
);
```

### Listen to Export States
```dart
BlocConsumer<ExportBloc, ExportState>(
  listener: (context, state) {
    if (state is ExportReady) {
      // Export is ready, download it
      _downloadExport(state.exportId);
    } else if (state is ExportDownloaded) {
      // Export downloaded successfully
      _openFile(state.filePath);
    } else if (state is ExportFailed) {
      // Export failed
      _showError(state.message);
    }
  },
  builder: (context, state) {
    if (state is ExportProcessing) {
      return CircularProgressIndicator(value: state.progress / 100);
    }
    return ExportButton();
  },
);
```

### Download Export
```dart
// Download export when ready
context.read<ExportBloc>().add(
  DownloadExportEvent(
    exportId: '123',
    savePath: '/path/to/save/export.pdf',
  ),
);
```

### Retry Failed Export
```dart
// Retry failed export
context.read<ExportBloc>().add(const RetryExportEvent());
```

### Cancel Export
```dart
// Cancel export and reset
context.read<ExportBloc>().add(const CancelExportEvent());
```

## Export States

### ExportInitial
No export in progress.

### ExportRequesting
Export request is being sent to API.

### ExportQueued
Export has been queued for processing.
```dart
ExportQueued {
  exportId: '123',
  status: 'queued',
  message: 'Export request submitted',
}
```

### ExportProcessing
Export is being processed.
```dart
ExportProcessing {
  exportId: '123',
  progress: 75, // 0-100
}
```

### ExportReady
Export is ready for download.
```dart
ExportReady {
  exportId: '123',
  downloadUrl: 'https://api.example.com/export/123/download',
}
```

### ExportDownloading
Export is being downloaded.
```dart
ExportDownloading {
  exportId: '123',
  progress: 50, // 0-100
}
```

### ExportDownloaded
Export has been downloaded successfully.
```dart
ExportDownloaded {
  exportId: '123',
  filePath: '/path/to/export.pdf',
}
```

### ExportFailed
Export has failed.
```dart
ExportFailed {
  message: 'Network error',
  exportId: '123',
}
```

## Using the Export UI Page

### Navigate to Export Page
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ExportPage()),
);
```

### Provide ExportBloc
```dart
BlocProvider(
  create: (context) => ExportBloc(
    exportApiDataSource: sl<ExportApiDataSource>(),
  ),
  child: const ExportPage(),
);
```

## Bearer Token Authentication

All export endpoints automatically include Bearer token authentication via `BearerTokenInterceptor`.

### How It Works
1. User makes export request
2. `ExportApiDataSource` calls `apiClient.post()` or `apiClient.get()`
3. `BearerTokenInterceptor` intercepts request
4. Interceptor adds `Authorization: Bearer {token}` header
5. Request sent to backend with token
6. Backend validates token and processes request

### Token Refresh
If token expires (401 error):
1. Interceptor automatically refreshes token
2. Original request is retried with new token
3. If refresh fails, user is redirected to login

### No Manual Token Handling Required
```dart
// ❌ Don't do this
final token = await tokenManager.getToken();
final response = await dio.post(
  '/export/expenses/pdf',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);

// ✅ Do this instead
final response = await apiClient.post('/export/expenses/pdf');
// Token is added automatically!
```

## Error Handling

### API Errors
```dart
try {
  final response = await exportApiDataSource.exportExpensesToPdf();
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Unauthorized - token expired or invalid
  } else if (e.statusCode == 403) {
    // Forbidden - insufficient permissions
  } else if (e.statusCode == 422) {
    // Validation error
  } else if (e.statusCode == 500) {
    // Server error
  }
}
```

### BLoC Error Handling
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

## Common Use Cases

### Export with Date Range
```dart
// Export last month's expenses
final now = DateTime.now();
final startDate = DateTime(now.year, now.month - 1, 1);
final endDate = DateTime(now.year, now.month, 0);

context.read<ExportBloc>().add(
  RequestPdfExportEvent(
    startDate: startDate,
    endDate: endDate,
  ),
);
```

### Export All Data
```dart
// Export all expenses (no date filter)
context.read<ExportBloc>().add(
  const RequestPdfExportEvent(
    startDate: null,
    endDate: null,
  ),
);
```

### Export and Open File
```dart
BlocListener<ExportBloc, ExportState>(
  listener: (context, state) async {
    if (state is ExportDownloaded) {
      // Automatically open file after download
      await OpenFilex.open(state.filePath);
    }
  },
  child: ExportUI(),
);
```

### Export with Progress Tracking
```dart
BlocBuilder<ExportBloc, ExportState>(
  builder: (context, state) {
    if (state is ExportProcessing) {
      return Column(
        children: [
          Text('Processing: ${state.progress}%'),
          LinearProgressIndicator(value: state.progress / 100),
        ],
      );
    } else if (state is ExportDownloading) {
      return Column(
        children: [
          Text('Downloading: ${state.progress}%'),
          LinearProgressIndicator(value: state.progress / 100),
        ],
      );
    }
    return ExportButton();
  },
);
```

## Testing

### Unit Test Example
```dart
test('exportExpensesToPdf should return ExportResponseDto', () async {
  // Arrange
  final mockApiClient = MockApiClient();
  final datasource = ExportApiDataSourceImpl(apiClient: mockApiClient);
  
  when(mockApiClient.post(any, body: any))
      .thenAnswer((_) async => Response(
            data: {
              'data': {
                'id': 123,
                'format': 'pdf',
                'status': 'processing',
              }
            },
            statusCode: 200,
          ));
  
  // Act
  final result = await datasource.exportExpensesToPdf(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  );
  
  // Assert
  expect(result.id, 123);
  expect(result.format, 'pdf');
  expect(result.status, 'processing');
});
```

### Widget Test Example
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
- Check if Bearer token is valid
- Verify user has permission to export
- Check network connectivity
- Review API logs for errors

### Status Polling Not Working
- Verify backend supports status endpoint
- Check polling interval (should be 2 seconds)
- Ensure export ID is correct
- Review BLoC logs

### Download Failing
- Check file path permissions
- Verify export is completed
- Check available storage space
- Review download logs

### Token Expired During Export
- Token refresh should happen automatically
- If refresh fails, user will be redirected to login
- Export can be retried after re-authentication

## Best Practices

1. **Always handle errors**
   - Use try-catch for API calls
   - Show user-friendly error messages
   - Provide retry options

2. **Show progress indicators**
   - Display loading state during export
   - Show progress percentage if available
   - Indicate when download is complete

3. **Validate date ranges**
   - Ensure end date is after start date
   - Limit date range to reasonable period
   - Show validation errors clearly

4. **Clean up resources**
   - Stop polling timer when done
   - Cancel pending requests on page exit
   - Clear temporary files after use

5. **Test thoroughly**
   - Test with different date ranges
   - Test both PDF and Excel formats
   - Test error scenarios
   - Test on different devices

## Additional Resources

- [Export API Verification Document](TASK_10_EXPORT_API_VERIFICATION.md)
- [Export UI Implementation Summary](TASK_10.1_EXPORT_UI_SUMMARY.md)
- [Complete Task Summary](TASK_10_COMPLETE_SUMMARY.md)
- [Bearer Token Verification](../core/api/BEARER_TOKEN_VERIFICATION.md)
