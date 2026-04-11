# Task 18: Integration Examples

## Complete Integration Examples

### Example 1: Transfer Form with Loading and Error Handling

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/utils/error_logger.dart';
import 'package:finance_app/features/transfers/presentation/bloc/transfer_bloc.dart';

class TransferFormPage extends StatefulWidget {
  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _amountError;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Clear previous errors
    setState(() {
      _amountError = null;
      _isLoading = true;
    });

    try {
      // Validate
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        setState(() {
          _amountError = 'Please enter a valid amount';
          _isLoading = false;
        });
        return;
      }

      // Submit transfer
      context.read<TransferBloc>().add(
            CreateTransfer(
              amount: amount,
              notes: _notesController.text,
            ),
          );

      // Wait for result
      await context.read<TransferBloc>().stream.firstWhere(
            (state) => state is! TransferLoading,
          );

      // Check result
      final state = context.read<TransferBloc>().state;
      if (state is TransferSuccess) {
        if (mounted) {
          showSuccessSnackbar(context, 'Transfer created successfully!');
          Navigator.pop(context);
        }
      } else if (state is TransferError) {
        throw Exception(state.message);
      }
    } catch (e, stackTrace) {
      // Log error
      ErrorLogger.logError(
        'Transfer Form Submit',
        e,
        stackTrace: stackTrace,
        additionalData: {
          'amount': _amountController.text,
          'notes': _notesController.text,
        },
      );

      // Show appropriate error
      if (mounted) {
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          showNetworkErrorSnackbar(
            context,
            onRetry: _handleSubmit,
          );
        } else if (e.toString().contains('500') ||
            e.toString().contains('server')) {
          showServerErrorSnackbar(
            context,
            supportEmail: 'support@financeapp.com',
          );
        } else {
          showErrorSnackbar(
            context,
            'Failed to create transfer: ${e.toString()}',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Transfer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValidatedTextField(
              controller: _amountController,
              label: 'Amount (USD)',
              errorText: _amountError,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            ValidatedTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hintText: 'Add notes about this transfer',
              prefixIcon: Icons.note,
              maxLines: 3,
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
        ),
      ),
    );
  }
}
```

### Example 2: Expense List with All States

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/widgets/skeleton_loader.dart';
import 'package:finance_app/features/expenses/presentation/bloc/expense_bloc.dart';

class ExpenseListPage extends StatefulWidget {
  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    context.read<ExpenseBloc>().add(LoadExpenses());
  }

  Future<void> _refreshExpenses() async {
    context.read<ExpenseBloc>().add(RefreshExpenses());
    await context.read<ExpenseBloc>().stream.firstWhere(
          (state) => state is! ExpenseLoading,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/create-expense');
            },
          ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ErrorLogger.logFailure('Expense List', state.failure);
            
            // Don't show snackbar if we're showing error state widget
            // Only show for operations like delete
            if (state is ExpenseDeleteError) {
              showErrorSnackbar(
                context,
                'Failed to delete expense',
                onRetry: () {
                  // Retry delete
                },
              );
            }
          }
        },
        builder: (context, state) {
          // Loading state - show skeleton
          if (state is ExpenseLoading) {
            return SkeletonListView(
              itemCount: 5,
              itemHeight: 100,
            );
          }

          // Error state - show error widget
          if (state is ExpenseLoadError) {
            return ErrorStateWidget(
              title: 'Failed to Load Expenses',
              message: state.message,
              onRetry: _loadExpenses,
            );
          }

          // Loaded state
          if (state is ExpenseLoaded) {
            // Empty state
            if (state.expenses.isEmpty) {
              return EmptyStateWidget(
                title: 'No Expenses Yet',
                message: 'Create your first expense to get started',
                icon: Icons.receipt,
                onAction: () {
                  Navigator.pushNamed(context, '/create-expense');
                },
                actionLabel: 'Create Expense',
              );
            }

            // List with pull-to-refresh
            return PullToRefreshWrapper(
              onRefresh: _refreshExpenses,
              child: ListView.builder(
                itemCount: state.expenses.length,
                itemBuilder: (context, index) {
                  final expense = state.expenses[index];
                  return ExpenseCard(
                    expense: expense,
                    onDelete: () {
                      context.read<ExpenseBloc>().add(
                            DeleteExpense(expense.id),
                          );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

### Example 3: File Upload with Progress

```dart
import 'package:flutter/material.dart';
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/utils/error_logger.dart';
import 'package:finance_app/core/services/file_upload_service.dart';

class InvoiceUploadWidget extends StatefulWidget {
  final Function(String photoUrl) onUploadComplete;

  const InvoiceUploadWidget({
    super.key,
    required this.onUploadComplete,
  });

  @override
  State<InvoiceUploadWidget> createState() => _InvoiceUploadWidgetState();
}

class _InvoiceUploadWidgetState extends State<InvoiceUploadWidget> {
  final _uploadService = FileUploadService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _fileName;

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick file
      final file = await _uploadService.pickImage();
      if (file == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _fileName = file.name;
      });

      // Upload with progress
      final photoUrl = await _uploadService.uploadFile(
        file,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      // Success
      if (mounted) {
        showSuccessSnackbar(context, 'Invoice uploaded successfully!');
        widget.onUploadComplete(photoUrl);
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Invoice Upload',
        e,
        stackTrace: stackTrace,
        additionalData: {'fileName': _fileName},
      );

      if (mounted) {
        showErrorSnackbar(
          context,
          'Failed to upload invoice',
          onRetry: _pickAndUploadFile,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _fileName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isUploading && _fileName != null)
          FileUploadProgress(
            fileName: _fileName!,
            progress: _uploadProgress,
            onCancel: () {
              // Cancel upload
              setState(() {
                _isUploading = false;
                _uploadProgress = 0.0;
                _fileName = null;
              });
            },
          )
        else
          ElevatedButton.icon(
            onPressed: _pickAndUploadFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Invoice'),
          ),
      ],
    );
  }
}
```

### Example 4: Export with Progress

```dart
import 'package:flutter/material.dart';
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/utils/error_logger.dart';
import 'package:finance_app/features/export/data/datasources/export_api_datasource.dart';

class ExportButton extends StatefulWidget {
  final String exportType; // 'PDF' or 'Excel'
  final Map<String, dynamic> filters;

  const ExportButton({
    super.key,
    required this.exportType,
    required this.filters,
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  final _exportService = ExportApiDataSource();
  bool _isExporting = false;
  String _exportStatus = 'Preparing...';
  double? _exportProgress;

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Preparing export...';
      _exportProgress = null;
    });

    try {
      // Start export
      final exportId = await _exportService.startExport(
        type: widget.exportType,
        filters: widget.filters,
      );

      // Poll for progress
      while (true) {
        await Future.delayed(const Duration(seconds: 2));

        final status = await _exportService.getExportStatus(exportId);

        setState(() {
          _exportStatus = status.message;
          _exportProgress = status.progress;
        });

        if (status.isComplete) {
          // Download file
          await _exportService.downloadExport(exportId);

          if (mounted) {
            showSuccessSnackbar(
              context,
              '${widget.exportType} exported successfully!',
            );
          }
          break;
        }

        if (status.isFailed) {
          throw Exception(status.errorMessage ?? 'Export failed');
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Export ${widget.exportType}',
        e,
        stackTrace: stackTrace,
        additionalData: {
          'exportType': widget.exportType,
          'filters': widget.filters,
        },
      );

      if (mounted) {
        showErrorSnackbar(
          context,
          'Failed to export ${widget.exportType}',
          onRetry: _handleExport,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = 'Preparing...';
          _exportProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExporting) {
      return ExportProgress(
        exportType: widget.exportType,
        status: _exportStatus,
        progress: _exportProgress,
      );
    }

    return ElevatedButton.icon(
      onPressed: _handleExport,
      icon: Icon(
        widget.exportType == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
      ),
      label: Text('Export to ${widget.exportType}'),
    );
  }
}
```

### Example 5: Long Operation with Timeout Warning

```dart
import 'package:flutter/material.dart';
import 'package:finance_app/core/widgets/loading_indicators.dart';
import 'package:finance_app/core/widgets/error_display.dart';
import 'package:finance_app/core/utils/error_logger.dart';

class LongOperationPage extends StatefulWidget {
  @override
  State<LongOperationPage> createState() => _LongOperationPageState();
}

class _LongOperationPageState extends State<LongOperationPage> {
  bool _isProcessing = false;
  bool _showTimeout = false;
  Timer? _timeoutTimer;

  Future<void> _startLongOperation() async {
    setState(() {
      _isProcessing = true;
      _showTimeout = false;
    });

    // Start timeout timer (30 seconds)
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isProcessing) {
        setState(() => _showTimeout = true);
      }
    });

    try {
      // Perform long operation
      await _performOperation();

      if (mounted) {
        showSuccessSnackbar(context, 'Operation completed successfully!');
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Long Operation',
        e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        showErrorSnackbar(
          context,
          'Operation failed',
          onRetry: _startLongOperation,
        );
      }
    } finally {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showTimeout = false;
        });
      }
    }
  }

  Future<void> _performOperation() async {
    // Simulate long operation
    await Future.delayed(const Duration(seconds: 35));
  }

  void _cancelOperation() {
    _timeoutTimer?.cancel();
    setState(() {
      _isProcessing = false;
      _showTimeout = false;
    });
    showInfoSnackbar(context, 'Operation cancelled');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Long Operation')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  PrimaryLoadingIndicator(
                    message: 'Processing...',
                  )
                else
                  ElevatedButton(
                    onPressed: _startLongOperation,
                    child: const Text('Start Operation'),
                  ),
              ],
            ),
          ),
          if (_showTimeout)
            TimeoutWarning(
              message: 'This operation is taking longer than expected...',
              onCancel: _cancelOperation,
              onContinue: () {
                setState(() => _showTimeout = false);
              },
            ),
        ],
      ),
    );
  }
}
```

## Key Patterns

### 1. Always Log Errors
```dart
try {
  // operation
} catch (e, stackTrace) {
  ErrorLogger.logError('Context', e, stackTrace: stackTrace);
  showErrorSnackbar(context, 'Error message');
}
```

### 2. Provide Retry for Network Errors
```dart
showNetworkErrorSnackbar(context, onRetry: _retryOperation);
```

### 3. Use Appropriate Loading Indicators
- Forms: `LoadingButton`
- Lists: `SkeletonListView`
- General: `PrimaryLoadingIndicator`
- Uploads: `FileUploadProgress`
- Exports: `ExportProgress`

### 4. Handle All States
- Loading → Skeleton/Indicator
- Error → ErrorStateWidget
- Empty → EmptyStateWidget
- Success → Data + PullToRefresh

### 5. Auto-dismiss Success, Manual Dismiss Errors
```dart
showSuccessSnackbar(context, 'Success!'); // Auto-dismisses
showErrorSnackbar(context, 'Error'); // Requires action
```

These examples demonstrate complete integration of all loading and error handling components in real-world scenarios.
