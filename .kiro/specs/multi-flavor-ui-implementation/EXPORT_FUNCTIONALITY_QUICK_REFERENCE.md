# Export Functionality - Quick Reference Guide

## Overview
Export functionality allows Admin and User roles to export expense data in multiple formats with filter application.

## Export Pages

### Admin Export Page
**Location:** `lib/features/admin/presentation/pages/admin_export_page.dart`

**Constructor:**
```dart
AdminExportPage({
  DateTimeRange? dateRange,
  String? currencyFilter,
  int? userFilter,
})
```

**Features:**
- Export to PDF
- Export to Excel
- Export Invoice Images to PDF Bundle
- Applies date, currency, and user filters
- Shows all group expenses (Admin + Users)

### User Export Page
**Location:** `lib/features/user/presentation/pages/user_export_page.dart`

**Constructor:**
```dart
UserExportPage({
  DateTimeRange? dateRange,
  String? currencyFilter,
})
```

**Features:**
- Export to PDF
- Export to Excel
- Export Invoice Images to PDF Bundle
- Applies date and currency filters
- Shows ONLY user's own expenses

## Navigation Example

### From Admin Expenses Page
```dart
// Add export button to AppBar or FAB
IconButton(
  icon: Icon(Icons.download),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ExportBloc(
            exportApiDataSource: context.read<ExportApiDataSource>(),
          ),
          child: AdminExportPage(
            dateRange: _dateRange,
            currencyFilter: _currencyFilter,
            userFilter: _userFilter,
          ),
        ),
      ),
    );
  },
)
```

### From User Expenses Page
```dart
// Add export button to AppBar or FAB
IconButton(
  icon: Icon(Icons.download),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ExportBloc(
            exportApiDataSource: context.read<ExportApiDataSource>(),
          ),
          child: UserExportPage(
            dateRange: _dateRange,
            currencyFilter: _currencyFilter,
          ),
        ),
      ),
    );
  },
)
```

## API Endpoints

### Export Expenses to PDF
```
POST /api/v1/export/expenses/pdf
Body: {
  "format": "pdf",
  "date_from": "2024-01-01",  // optional
  "date_to": "2024-12-31"     // optional
}
Response: {
  "success": true,
  "data": {
    "id": 1,
    "format": "pdf",
    "status": "completed",
    "download_url": "https://..."
  }
}
```

### Export Expenses to Excel
```
POST /api/v1/export/expenses/excel
Body: {
  "format": "excel",
  "date_from": "2024-01-01",  // optional
  "date_to": "2024-12-31"     // optional
}
Response: {
  "success": true,
  "data": {
    "id": 2,
    "format": "excel",
    "status": "completed",
    "download_url": "https://..."
  }
}
```

### Export Invoice Images
```
POST /api/v1/export/expenses/invoices
Body: {
  "format": "invoice_bundle",
  "date_from": "2024-01-01",  // optional
  "date_to": "2024-12-31"     // optional
}
Response: {
  "success": true,
  "data": {
    "id": 3,
    "format": "invoice_bundle",
    "status": "processing",
    "download_url": null
  }
}
```

### Check Export Status
```
GET /api/v1/export/{id}/status
Response: {
  "success": true,
  "data": {
    "id": 3,
    "format": "invoice_bundle",
    "status": "completed",
    "download_url": "https://...",
    "progress": 100
  }
}
```

### Download Export
```
GET /api/v1/export/{id}/download
Response: Binary file download
```

## Export States

### State Flow
```
ExportInitial
    ↓ (User clicks export button)
ExportRequesting
    ↓ (API responds)
ExportQueued (if status = "queued" or "processing")
    ↓ (Polling every 2 seconds)
ExportProcessing (with progress %)
    ↓ (Status becomes "completed")
ExportReady
    ↓ (Auto-download triggered)
ExportDownloading (with progress %)
    ↓ (Download complete)
ExportDownloaded
    ↓ (User opens file or starts new export)
ExportInitial
```

### Error Flow
```
Any State
    ↓ (Error occurs)
ExportFailed
    ↓ (User clicks retry)
ExportRequesting (retry with same parameters)
```

## File Naming

### Admin Files
- PDF: `expenses_20241116_143022.pdf`
- Excel: `expenses_20241116_143022.xlsx`
- Invoices: `invoices_20241116_143022.pdf`

### User Files
- PDF: `my_expenses_20241116_143022.pdf`
- Excel: `my_expenses_20241116_143022.xlsx`
- Invoices: `my_invoices_20241116_143022.pdf`

## Filter Application

### Admin Filters
```dart
// Date Range
dateRange: DateTimeRange(
  start: DateTime(2024, 1, 1),
  end: DateTime(2024, 12, 31),
)

// Currency
currencyFilter: 'USD'  // or 'SYP', 'TRY', null for all

// User
userFilter: 123  // User ID, null for all users
```

### User Filters
```dart
// Date Range
dateRange: DateTimeRange(
  start: DateTime(2024, 1, 1),
  end: DateTime(2024, 12, 31),
)

// Currency
currencyFilter: 'USD'  // or 'SYP', 'TRY', null for all

// Note: No user filter - always exports own expenses
```

## UI Components

### Active Filters Card
Shows currently applied filters with chips:
- Date range chip with calendar icon
- Currency chip with money icon
- User chip with person icon (Admin only)

### Export Options Card
Three large buttons with:
- Icon (PDF/Excel/Photo)
- Title
- Description
- Loading indicator when active

### Status Card
Shows current export status:
- Icon (hourglass/queue/sync/check/error)
- Title
- Subtitle with details
- Progress bar (when applicable)
- Action buttons (Open/Retry/Cancel)

## Localization Keys

### Required Translation Keys
```
export_data
export_my_expenses
active_filters
no_filters_applied
export_will_apply_filters
export_options
export_to_pdf
export_to_excel
export_invoice_images
export_pdf_description
export_excel_description
export_invoices_description
export_status
requesting_export
export_queued
processing_export
export_ready
downloading_export
export_completed
export_failed
export_downloaded_successfully
file_saved_successfully
please_wait
complete
open
open_file
retry
cancel
export_user_info
specific_user
```

## Common Issues & Solutions

### Issue: Export button not showing
**Solution:** Add navigation button to expense page AppBar or as FAB

### Issue: Filters not applied
**Solution:** Pass filter parameters when navigating to export page

### Issue: Export fails immediately
**Solution:** Check API endpoint configuration and authentication

### Issue: Status polling not working
**Solution:** Verify backend supports GET /export/{id}/status endpoint

### Issue: File won't open
**Solution:** Ensure device has appropriate app to open PDF/Excel files

### Issue: Download fails
**Solution:** Check app permissions for file storage

## Testing Checklist

- [ ] Export to PDF works
- [ ] Export to Excel works
- [ ] Export invoice images works
- [ ] Date filter is applied correctly
- [ ] Currency filter is applied correctly
- [ ] User filter is applied correctly (Admin)
- [ ] Progress indicator shows during export
- [ ] File downloads automatically when ready
- [ ] File opens successfully
- [ ] Retry works after failure
- [ ] Cancel resets state
- [ ] User can only export own expenses (User role)
- [ ] Admin can export all group expenses
- [ ] No filters exports all data
- [ ] Multiple exports can be performed in sequence

## Performance Considerations

1. **Status Polling**: Polls every 2 seconds - ensure backend can handle frequent requests
2. **Large Exports**: Invoice bundles may take time - show progress to user
3. **File Size**: Large Excel files may take time to download - show progress
4. **Memory**: Large files are downloaded to device storage - ensure sufficient space

## Security Considerations

1. **Authorization**: Backend must verify user can only export their own data (User role)
2. **Data Scoping**: Admin can only export data from their group
3. **File Access**: Downloaded files are stored in app-private directory
4. **API Security**: All export endpoints require authentication token

## Future Enhancements

1. **Email Export**: Send export directly to email
2. **Cloud Storage**: Save to Google Drive/Dropbox
3. **Scheduled Exports**: Automatic weekly/monthly exports
4. **Custom Templates**: Allow users to customize export format
5. **Export History**: Show list of previous exports
6. **Batch Export**: Export multiple date ranges at once
7. **Export Preview**: Preview export before downloading
8. **Format Options**: Additional export formats (CSV, JSON)
