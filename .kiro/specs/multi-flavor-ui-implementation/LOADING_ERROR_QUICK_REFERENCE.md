# Loading States and Error Handling - Quick Reference

## Quick Import

```dart
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/widgets/skeleton_loader.dart';
import 'package:finance_app/core/utils/error_logger.dart';
```

## Loading States - Quick Usage

### Form Button
```dart
LoadingButton(
  onPressed: _submit,
  label: 'Submit',
  isLoading: _isLoading,
)
```

### List Loading
```dart
if (isLoading)
  SkeletonListView(itemCount: 5)
else
  ListView.builder(...)
```

### General Loading
```dart
PrimaryLoadingIndicator(message: 'Loading...')
```

### Pull to Refresh
```dart
PullToRefreshWrapper(
  onRefresh: _refresh,
  child: ListView(...),
)
```

### File Upload
```dart
FileUploadProgress(
  fileName: 'invoice.jpg',
  progress: 0.65,
  onCancel: _cancel,
)
```

### Export Progress
```dart
ExportProgress(
  exportType: 'PDF',
  status: 'Generating...',
  progress: 0.5,
)
```

### Timeout Warning
```dart
if (showTimeout)
  TimeoutWarning(
    onCancel: _cancel,
    onContinue: _continue,
  )
```

## Error Handling - Quick Usage

### Success Message
```dart
showSuccessSnackbar(context, 'Success!');
```

### Error Message
```dart
showErrorSnackbar(
  context,
  'Failed',
  onRetry: _retry,
);
```

### Network Error
```dart
showNetworkErrorSnackbar(context, onRetry: _retry);
```

### Server Error
```dart
showServerErrorSnackbar(
  context,
  supportEmail: 'support@example.com',
);
```

### Validation Error
```dart
showValidationErrorSnackbar(context, 'Invalid input');
```

### Empty State
```dart
EmptyStateWidget(
  title: 'No Items',
  message: 'Create your first item',
  onAction: _create,
  actionLabel: 'Create',
)
```

### Error State
```dart
ErrorStateWidget(
  message: 'Failed to load',
  onRetry: _retry,
)
```

### Form Field Error
```dart
ValidatedTextField(
  controller: _controller,
  label: 'Name',
  errorText: _error,
)
```

## Error Logging - Quick Usage

### Basic Error
```dart
try {
  // code
} catch (e, stackTrace) {
  ErrorLogger.logError('Context', e, stackTrace: stackTrace);
}
```

### Network Error
```dart
ErrorLogger.logNetworkError(
  '/api/endpoint',
  error,
  statusCode: 500,
);
```

### Validation Error
```dart
ErrorLogger.logValidationError('field', 'error message');
```

## Common Patterns

### Form with Loading and Error
```dart
LoadingButton(
  onPressed: () async {
    setState(() => _isLoading = true);
    try {
      await _submit();
      showSuccessSnackbar(context, 'Success!');
    } catch (e, s) {
      ErrorLogger.logError('Submit', e, stackTrace: s);
      showErrorSnackbar(context, 'Failed', onRetry: _submit);
    } finally {
      setState(() => _isLoading = false);
    }
  },
  label: 'Submit',
  isLoading: _isLoading,
)
```

### List with States
```dart
if (state is Loading)
  SkeletonListView()
else if (state is Error)
  ErrorStateWidget(message: state.message, onRetry: _retry)
else if (state.items.isEmpty)
  EmptyStateWidget(title: 'No Items', message: 'Create one')
else
  PullToRefreshWrapper(
    onRefresh: _refresh,
    child: ListView.builder(...),
  )
```

### BLoC Listener
```dart
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    if (state is Success) {
      showSuccessSnackbar(context, 'Success!');
    } else if (state is Error) {
      ErrorLogger.logFailure('MyBloc', state.failure);
      showErrorSnackbar(context, state.message, onRetry: _retry);
    }
  },
  child: ...,
)
```

## Cheat Sheet

| Scenario | Component | Auto-Dismiss |
|----------|-----------|--------------|
| Success | showSuccessSnackbar | ✅ 3s |
| Error | showErrorSnackbar | ❌ Manual |
| Network Error | showNetworkErrorSnackbar | ❌ Manual |
| Server Error | showServerErrorSnackbar | ❌ Manual |
| Validation | showValidationErrorSnackbar | ❌ Manual |
| Info | showInfoSnackbar | ✅ 3s |
| Warning | showWarningSnackbar | ✅ 4s |

| Loading Type | Component |
|--------------|-----------|
| Button | LoadingButton |
| List | SkeletonListView |
| General | PrimaryLoadingIndicator |
| Image | ImagePlaceholder |
| Upload | FileUploadProgress |
| Export | ExportProgress |
| Overlay | LoadingOverlay |
| Timeout | TimeoutWarning |

## Requirements Mapping

| Requirement | Component |
|-------------|-----------|
| 28.1 | PrimaryLoadingIndicator |
| 28.2 | LoadingButton |
| 28.3 | SkeletonListView |
| 28.4 | PullToRefreshWrapper |
| 28.5 | ImagePlaceholder |
| 28.6 | FileUploadProgress |
| 28.7 | ExportProgress |
| 28.8 | TimeoutWarning |
| 29.1 | showSuccessSnackbar |
| 29.2 | showErrorSnackbar |
| 29.3 | ValidatedTextField |
| 29.4 | showNetworkErrorSnackbar |
| 29.5 | showServerErrorSnackbar |
| 29.6 | Duration(seconds: 3) |
| 29.7 | Duration(days: 1) |
| 29.8 | ErrorLogger |
