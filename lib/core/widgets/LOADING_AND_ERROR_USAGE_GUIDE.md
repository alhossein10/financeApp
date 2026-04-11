# Loading States and Error Handling Usage Guide

This guide explains how to use the comprehensive loading and error handling components implemented for the multi-flavor application.

## Overview

The implementation covers:
- **Loading Indicators**: Various loading states for different UI scenarios
- **Error Display**: Consistent error messaging and user feedback
- **Error Logging**: Comprehensive error tracking for debugging

## Loading State Components

### 1. Primary Loading Indicator

Use for general loading states:

```dart
import 'package:finance_app/core/widgets/loading_indicators.dart';

// Simple loading
PrimaryLoadingIndicator()

// With message
PrimaryLoadingIndicator(
  message: 'Loading your data...',
  size: 50,
)
```

### 2. Loading Button

Use in forms to show loading state on submit:

```dart
LoadingButton(
  onPressed: _handleSubmit,
  label: 'Submit',
  isLoading: state is LoadingState,
  icon: Icons.send,
)
```

### 3. Skeleton Loaders

Use while loading lists:

```dart
import 'package:finance_app/core/widgets/skeleton_loader.dart';

// For list views
if (state is LoadingState)
  SkeletonListView(
    itemCount: 5,
    itemHeight: 80,
  )

// For grid views
if (state is LoadingState)
  SkeletonGridView(
    itemCount: 6,
    crossAxisCount: 2,
  )

// Custom skeleton
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: BorderRadius.circular(8),
)
```

### 4. Image Placeholder

Use while loading images:

```dart
ImagePlaceholder(
  width: 100,
  height: 100,
  borderRadius: BorderRadius.circular(8),
)

// Or with Image.network
Image.network(
  imageUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return ImagePlaceholder(
      width: 100,
      height: 100,
    );
  },
)
```

### 5. File Upload Progress

Use for file uploads:

```dart
FileUploadProgress(
  fileName: 'invoice.jpg',
  progress: 0.65, // 0.0 to 1.0
  onCancel: () {
    // Cancel upload
  },
)
```

### 6. Export Progress

Use for PDF/Excel exports:

```dart
ExportProgress(
  exportType: 'PDF',
  status: 'Generating document...',
  progress: 0.5, // Optional
)
```

### 7. Pull-to-Refresh

Wrap scrollable widgets:

```dart
PullToRefreshWrapper(
  onRefresh: () async {
    await _refreshData();
  },
  child: ListView.builder(...),
)
```

### 8. Loading Overlay

Use for full-screen operations:

```dart
LoadingOverlay(
  isLoading: state is LoadingState,
  message: 'Processing...',
  child: YourContentWidget(),
)
```

### 9. Timeout Warning

Show after 30 seconds:

```dart
if (showTimeout)
  TimeoutWarning(
    message: 'This is taking longer than expected...',
    onCancel: () {
      // Cancel operation
    },
    onContinue: () {
      // Keep waiting
    },
  )
```

## Error Display Components

### 1. Success Snackbar

Auto-dismisses after 3 seconds:

```dart
import 'package:finance_app/core/widgets/error_display.dart';

showSuccessSnackbar(
  context,
  'Transfer created successfully!',
);
```

### 2. Error Snackbar

Requires manual dismiss:

```dart
showErrorSnackbar(
  context,
  'Failed to create transfer',
  onRetry: () {
    // Retry operation
  },
);
```

### 3. Network Error Snackbar

Specialized for network errors:

```dart
showNetworkErrorSnackbar(
  context,
  onRetry: () {
    // Retry operation
  },
);
```

### 4. Server Error Snackbar

With support contact:

```dart
showServerErrorSnackbar(
  context,
  supportEmail: 'support@example.com',
);
```

### 5. Validation Error Snackbar

For validation failures:

```dart
showValidationErrorSnackbar(
  context,
  'Please fill in all required fields',
);
```

### 6. Error Dialog

For critical errors:

```dart
ErrorDialog.show(
  context,
  title: 'Operation Failed',
  message: 'Unable to complete the operation',
  onRetry: () {
    // Retry operation
  },
);
```

### 7. Empty State Widget

For empty lists:

```dart
EmptyStateWidget(
  title: 'No Expenses Yet',
  message: 'Create your first expense to get started',
  icon: Icons.receipt,
  onAction: () {
    // Navigate to create expense
  },
  actionLabel: 'Create Expense',
)
```

### 8. Error State Widget

For failed data loads:

```dart
ErrorStateWidget(
  title: 'Failed to Load',
  message: 'Unable to fetch expenses',
  onRetry: () {
    // Retry loading
  },
)
```

### 9. Field Validation Error

For form field errors:

```dart
ValidatedTextField(
  controller: _nameController,
  label: 'Name',
  errorText: state.nameError,
  prefixIcon: Icons.person,
)
```

### 10. Info and Warning Snackbars

```dart
showInfoSnackbar(context, 'Your data has been saved locally');
showWarningSnackbar(context, 'You are currently offline');
```

## Error Logging

### Basic Error Logging

```dart
import 'package:finance_app/core/utils/error_logger.dart';

try {
  // Your code
} catch (e, stackTrace) {
  ErrorLogger.logError(
    'Transfer Creation',
    e,
    stackTrace: stackTrace,
    additionalData: {
      'userId': userId,
      'amount': amount,
    },
  );
}
```

### Specialized Logging

```dart
// Network errors
ErrorLogger.logNetworkError(
  '/api/v1/transfers',
  error,
  statusCode: 500,
  requestData: {'amount': 100},
);

// Validation errors
ErrorLogger.logValidationError(
  'amount',
  'Amount must be positive',
  value: -100,
);

// Authentication errors
ErrorLogger.logAuthError(
  'login',
  error,
  userId: 'user123',
);

// Database errors
ErrorLogger.logDatabaseError(
  'insert',
  error,
  table: 'expenses',
  data: expenseData,
);
```

## Complete Example: Form with Loading and Error Handling

```dart
class TransferForm extends StatefulWidget {
  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _amountError;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _amountError = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      // Validate
      if (amount <= 0) {
        setState(() {
          _amountError = 'Amount must be positive';
          _isLoading = false;
        });
        return;
      }

      // Submit
      await _submitTransfer(amount);

      // Success
      if (mounted) {
        showSuccessSnackbar(context, 'Transfer created successfully!');
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      // Log error
      ErrorLogger.logError(
        'Transfer Form Submit',
        e,
        stackTrace: stackTrace,
        additionalData: {'amount': _amountController.text},
      );

      // Show error
      if (mounted) {
        if (e.toString().contains('network')) {
          showNetworkErrorSnackbar(
            context,
            onRetry: _handleSubmit,
          );
        } else {
          showErrorSnackbar(
            context,
            'Failed to create transfer',
            onRetry: _handleSubmit,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValidatedTextField(
          controller: _amountController,
          label: 'Amount',
          errorText: _amountError,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        LoadingButton(
          onPressed: _handleSubmit,
          label: 'Create Transfer',
          isLoading: _isLoading,
          icon: Icons.send,
        ),
      ],
    );
  }
}
```

## Complete Example: List with Loading and Error States

```dart
class ExpenseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoading) {
          return SkeletonListView(itemCount: 5);
        }

        if (state is ExpenseError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () {
              context.read<ExpenseBloc>().add(LoadExpenses());
            },
          );
        }

        if (state is ExpenseLoaded) {
          if (state.expenses.isEmpty) {
            return EmptyStateWidget(
              title: 'No Expenses',
              message: 'Create your first expense',
              icon: Icons.receipt,
              onAction: () {
                Navigator.pushNamed(context, '/create-expense');
              },
              actionLabel: 'Create Expense',
            );
          }

          return PullToRefreshWrapper(
            onRefresh: () async {
              context.read<ExpenseBloc>().add(RefreshExpenses());
              await context.read<ExpenseBloc>().stream.first;
            },
            child: ListView.builder(
              itemCount: state.expenses.length,
              itemBuilder: (context, index) {
                return ExpenseCard(expense: state.expenses[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
```

## Best Practices

1. **Always log errors** - Use ErrorLogger for all caught exceptions
2. **Provide retry options** - For network and server errors
3. **Use appropriate indicators** - Match loading indicator to context
4. **Auto-dismiss success** - Success messages dismiss after 3 seconds
5. **Manual dismiss errors** - Error messages require user action
6. **Show validation inline** - Use ValidatedTextField for form fields
7. **Handle timeouts** - Show TimeoutWarning after 30 seconds
8. **Provide empty states** - Use EmptyStateWidget for empty lists
9. **Use skeleton loaders** - Better UX than spinners for lists
10. **Test error scenarios** - Ensure all error paths are handled

## Requirements Coverage

This implementation covers:
- ✅ 28.1: Loading indicators for data fetching
- ✅ 28.2: Disabled buttons with loading state
- ✅ 28.3: Skeleton loaders for lists
- ✅ 28.4: Pull-to-refresh indicators
- ✅ 28.5: Image placeholders
- ✅ 28.6: File upload progress
- ✅ 28.7: Export progress indicators
- ✅ 28.8: Timeout warnings (30 seconds)
- ✅ 29.1: Success messages with green indicator
- ✅ 29.2: Error messages with red indicator
- ✅ 29.3: Field validation errors
- ✅ 29.4: Network errors with retry
- ✅ 29.5: Server errors with support contact
- ✅ 29.6: Auto-dismiss success (3 seconds)
- ✅ 29.7: Manual dismiss errors
- ✅ 29.8: Error logging for debugging
