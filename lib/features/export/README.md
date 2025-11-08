# Export API Integration

## Overview
This module provides API integration for exporting expense data to PDF and Excel formats using the Laravel backend.

## Usage

### 1. Request PDF Export

```dart
// Get the export BLoC
final exportBloc = context.read<ExportBloc>();

// Request PDF export with date range
exportBloc.add(RequestPdfExportEvent(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
));
```

### 2. Request Excel Export

```dart
// Request Excel export with date range
exportBloc.add(RequestExcelExportEvent(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
));
```

### 3. Listen to Export States

```dart
BlocListener<ExportBloc, ExportState>(
  listener: (context, state) {
    if (state is ExportRequesting) {
      // Show loading indicator
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Requesting export...'),
            ],
          ),
        ),
      );
    } else if (state is ExportQueued) {
      // Export queued for processing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export queued: ${state.status}')),
      );
    } else if (state is ExportProcessing) {
      // Export is being processed (if status polling is available)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing: ${state.progress}%')),
      );
    } else if (state is ExportReady) {
      // Export is ready for download
      Navigator.pop(context); // Close loading dialog
      
      // Trigger download
      final savePath = '/path/to/save/file.pdf';
      context.read<ExportBloc>().add(DownloadExportEvent(
        exportId: state.exportId,
        savePath: savePath,
      ));
    } else if (state is ExportDownloading) {
      // File is being downloaded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading...')),
      );
    } else if (state is ExportDownloaded) {
      // Download complete
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: ${state.filePath}')),
      );
      
      // Open the file
      OpenFilex.open(state.filePath);
    } else if (state is ExportFailed) {
      // Export failed
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: YourWidget(),
)
```

### 4. Download Export

```dart
// Download the export file
final savePath = await getApplicationDocumentsDirectory();
final filePath = '${savePath.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.pdf';

exportBloc.add(DownloadExportEvent(
  exportId: exportId,
  savePath: filePath,
));
```

### 5. Cancel Export

```dart
// Cancel ongoing export
exportBloc.add(CancelExportEvent());
```

### 6. Retry Failed Export

```dart
// Retry the last failed export
exportBloc.add(RetryExportEvent());
```

## API Endpoints

### Export Expenses to PDF
- **Endpoint**: `POST /export/expenses/pdf`
- **Request Body**:
  ```json
  {
    "format": "pdf",
    "date_from": "2024-01-01",
    "date_to": "2024-12-31"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "data": {
      "id": 1,
      "format": "pdf",
      "status": "processing",
      "download_url": null
    }
  }
  ```

### Export Expenses to Excel
- **Endpoint**: `POST /export/expenses/excel`
- **Request Body**:
  ```json
  {
    "format": "excel",
    "date_from": "2024-01-01",
    "date_to": "2024-12-31"
  }
  ```
- **Response**: Same as PDF export

### Download Export
- **Endpoint**: `GET /export/{id}/download`
- **Response**: File download (binary data)

## Export States

| State | Description |
|-------|-------------|
| `ExportInitial` | Initial state, no export in progress |
| `ExportRequesting` | Export request is being sent to API |
| `ExportQueued` | Export has been queued for processing |
| `ExportProcessing` | Export is being processed (with progress) |
| `ExportReady` | Export is ready for download |
| `ExportDownloading` | Export file is being downloaded |
| `ExportDownloaded` | Export file has been downloaded successfully |
| `ExportFailed` | Export or download failed |

## Export Status

The export status can be one of:
- `processing` - Export is being generated
- `queued` - Export is queued for processing
- `completed` - Export is ready for download
- `failed` - Export generation failed

## Notes

1. **Synchronous Processing**: The API may process exports synchronously, returning a `completed` status immediately. The BLoC handles this case.

2. **Status Polling**: If the API returns `processing` status, the BLoC will poll for status updates every 3 seconds. However, the current API may not have a dedicated status endpoint.

3. **Date Formatting**: All dates are formatted as YYYY-MM-DD using `DateFormatter.toApiDate()`.

4. **File Storage**: Downloaded files are saved to the path specified by the caller. Consider using `path_provider` to get appropriate directories:
   - `getApplicationDocumentsDirectory()` - User documents
   - `getTemporaryDirectory()` - Temporary files
   - `getExternalStorageDirectory()` - External storage (Android)

5. **Error Handling**: All API errors are caught and converted to `ExportFailed` state with user-friendly messages.

## Example: Complete Export Flow

```dart
class ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportReady) {
          _downloadExport(context, state.exportId);
        } else if (state is ExportDownloaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export saved to: ${state.filePath}')),
          );
          OpenFilex.open(state.filePath);
        } else if (state is ExportFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ExportRequesting || 
                         state is ExportProcessing || 
                         state is ExportDownloading;

        return ElevatedButton.icon(
          onPressed: isLoading ? null : () => _requestExport(context),
          icon: isLoading 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.download),
          label: Text(isLoading ? 'Exporting...' : 'Export to PDF'),
        );
      },
    );
  }

  void _requestExport(BuildContext context) {
    context.read<ExportBloc>().add(RequestPdfExportEvent(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime.now(),
    ));
  }

  Future<void> _downloadExport(BuildContext context, String exportId) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/expenses_$timestamp.pdf';

    context.read<ExportBloc>().add(DownloadExportEvent(
      exportId: exportId,
      savePath: filePath,
    ));
  }
}
```

## Testing

Unit tests are available in:
- `test/features/export/data/models/export_dto_test.dart`
- `test/features/export/data/models/export_request_dto_test.dart`
- `test/features/export/data/datasources/export_api_datasource_test.dart`

Run tests with:
```bash
flutter test test/features/export/
```
