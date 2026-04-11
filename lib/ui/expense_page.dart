import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/expenses/presentation/bloc/expense_bloc.dart';
import '../features/expenses/presentation/bloc/expense_event.dart';
import '../features/expenses/presentation/bloc/expense_state.dart';
import '../features/expenses/domain/entities/expense.dart' as domain;
import '../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../state/filters.dart';
import '../utils/camera_helper.dart';
import '../core/config/flavor_config.dart';
import '../core/config/api_config.dart' as core;
import '../core/services/token_manager.dart' as core;
import '../core/widgets/watermark_background.dart';
import '../injection_container.dart' as di;
import 'widgets/sync_status_indicator.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Get current user and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
      
      // Load group members for admin flavor (to include all users in filter, including admin owner)
      if (FlavorConfig.instance.isAdmin) {
        context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
      }
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      // Always reload to get fresh data, but previous expenses will be preserved during loading
      context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
    }
  }

  Future<void> _addExpense(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final descCtrl = TextEditingController();
    final usdCtrl = TextEditingController();
    final sypCtrl = TextEditingController();
    final tryCtrl = TextEditingController();
    InvoiceStatus status = InvoiceStatus.noInvoice;
    String? invoicePath;
    DateTime selectedDate = DateTime.now();
    bool isUploading = false;
    double uploadProgress = 0.0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.newExpense ?? 'New Expense'),
          content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: l10n?.itemDescription),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n?.expenseDate ?? 'Expense Date'),
                    subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setLocal(() => selectedDate = date);
                      }
                    },
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usdCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceUsd),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sypCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceSyp),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tryCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceTry),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: status,
                  items: [
                    DropdownMenuItem(value: InvoiceStatus.invoiceAvailable, child: Text(l10n?.invoiceAvailable ?? 'Invoice available')),
                    DropdownMenuItem(value: InvoiceStatus.noInvoice, child: Text(l10n?.noInvoiceAvailable ?? 'No invoice available')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? InvoiceStatus.noInvoice),
                  decoration: InputDecoration(labelText: l10n?.invoiceStatus),
                ),
                if (status == InvoiceStatus.invoiceAvailable) ...[
                  const SizedBox(height: 8),
                  // Show invoice thumbnail if available
                  if (invoicePath != null && invoicePath!.isNotEmpty) ...[
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(invoicePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoicePath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Text(l10n?.noFileSelected ?? 'No file selected', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  // Show upload progress if uploading
                  if (isUploading) ...[
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 4),
                    Text(
                      '${(uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final path = await CameraHelper.takePicture(ctx);
                          if (path != null) {
                            setLocal(() => invoicePath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(l10n?.takePhoto ?? 'Take Photo'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          if (res != null && res.files.single.path != null) {
                            setLocal(() => invoicePath = res.files.single.path);
                          }
                        },
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(l10n?.fromGallery ?? 'From Gallery'),
                      ),
                      if (invoicePath != null && invoicePath!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : () {
                            setLocal(() => invoicePath = null);
                          },
                          icon: const Icon(Icons.delete, size: 20),
                          label: Text(l10n?.remove ?? 'Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx, false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx, true),
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && _currentUserId != null && context.mounted) {
      if (descCtrl.text.trim().isEmpty) return;
      
      // Convert local InvoiceStatus to domain InvoiceStatus
      final domainInvoiceStatus = status == InvoiceStatus.invoiceAvailable 
          ? domain.InvoiceStatus.invoiceAvailable 
          : domain.InvoiceStatus.noInvoice;
      
      context.read<ExpenseBloc>().add(CreateExpenseRequested(
        userId: _currentUserId!,
        description: descCtrl.text.trim(),
        priceUsd: double.tryParse(usdCtrl.text.trim()),
        priceSyp: double.tryParse(sypCtrl.text.trim()),
        priceTry: double.tryParse(tryCtrl.text.trim()),
        invoiceStatus: domainInvoiceStatus,
        invoiceFilePath: invoicePath != null && invoicePath!.isNotEmpty ? File(invoicePath!).path : null,
        expenseDate: selectedDate,
      ));
    }
  }

  Future<void> _editExpense(BuildContext context, ExpenseRecord expense) async {
    final l10n = AppLocalizations.of(context);
    final descCtrl = TextEditingController(text: expense.description);
    final usdCtrl = TextEditingController(text: expense.priceUsd?.toString() ?? '');
    final sypCtrl = TextEditingController(text: expense.priceSyp?.toString() ?? '');
    final tryCtrl = TextEditingController(text: expense.priceTry?.toString() ?? '');
    InvoiceStatus status = expense.invoiceStatus;
    String? invoicePath = expense.invoiceFilePath;
    DateTime selectedDate = expense.expenseDate;
    bool isUploading = false;
    double uploadProgress = 0.0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.editExpense ?? 'Edit Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: l10n?.itemDescription),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n?.expenseDate ?? 'Expense Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setLocal(() => selectedDate = date);
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usdCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceUsd),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sypCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceSyp),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tryCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n?.priceTry),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: status,
                  items: [
                    DropdownMenuItem(value: InvoiceStatus.invoiceAvailable, child: Text(l10n?.invoiceAvailable ?? 'Invoice available')),
                    DropdownMenuItem(value: InvoiceStatus.noInvoice, child: Text(l10n?.noInvoiceAvailable ?? 'No invoice available')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? InvoiceStatus.noInvoice),
                  decoration: InputDecoration(labelText: l10n?.invoiceStatus),
                ),
                if (status == InvoiceStatus.invoiceAvailable) ...[
                  const SizedBox(height: 8),
                  // Show invoice thumbnail if available
                  if (invoicePath != null && invoicePath!.isNotEmpty) ...[
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(invoicePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoicePath!.split('/').last,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Text(l10n?.noFileSelected ?? 'No file selected', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  // Show upload progress if uploading
                  if (isUploading) ...[
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 4),
                    Text(
                      '${(uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final path = await CameraHelper.takePicture(ctx);
                          if (path != null) {
                            setLocal(() => invoicePath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(l10n?.takePhoto ?? 'Take Photo'),
                      ),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          if (res != null && res.files.single.path != null) {
                            setLocal(() => invoicePath = res.files.single.path);
                          }
                        },
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(l10n?.fromGallery ?? 'From Gallery'),
                      ),
                      if (invoicePath != null && invoicePath!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : () {
                            setLocal(() => invoicePath = null);
                          },
                          icon: const Icon(Icons.delete, size: 20),
                          label: Text(l10n?.remove ?? 'Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx, false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx, true),
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && _currentUserId != null && context.mounted) {
      if (descCtrl.text.trim().isEmpty) return;
      
      final updated = expense.copyWith(
        description: descCtrl.text.trim(),
        priceUsd: double.tryParse(usdCtrl.text.trim()),
        priceSyp: double.tryParse(sypCtrl.text.trim()),
        priceTry: double.tryParse(tryCtrl.text.trim()),
        invoiceStatus: status,
        invoiceFilePath: invoicePath != null && invoicePath!.isNotEmpty ? File(invoicePath!).path : null,
        expenseDate: selectedDate,
        updatedAt: DateTime.now(),
      );
      
      // Convert ExpenseRecord to domain Expense entity
      final domainExpense = domain.Expense(
        id: updated.id,
        userId: _currentUserId!,
        description: updated.description,
        priceUsd: updated.priceUsd,
        priceSyp: updated.priceSyp,
        priceTry: updated.priceTry,
        invoiceStatus: domain.InvoiceStatus.values[updated.invoiceStatus.index],
        invoiceFilePath: updated.invoiceFilePath,
        expenseDate: updated.expenseDate,
        createdAt: updated.createdAt,
        updatedAt: updated.updatedAt,
      );
      
      context.read<ExpenseBloc>().add(UpdateExpenseRequested(
        expense: domainExpense,
        currentUserId: _currentUserId!,
      ));
    }
  }

  Future<void> _showInvoiceImage(BuildContext context, domain.Expense expense) async {
    if (expense.invoiceStatus != domain.InvoiceStatus.invoiceAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.noInvoiceImage ?? 'No invoice image available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: FutureBuilder<String?>(
          future: _getImageUrl(expense),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)?.failedToLoadImage ?? 'Failed to load image'),
                  ],
                ),
              );
            }

            final imageUrl = snapshot.data!;
            print('[ExpenseUI] 📸 Loading image from: $imageUrl');
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(AppLocalizations.of(context)?.invoiceImage ?? 'Invoice Image'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: FutureBuilder<String?>(
                        future: _getAuthToken(),
                        builder: (context, tokenSnapshot) {
                          if (!tokenSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          return Image.network(
                            imageUrl,
                                fit: BoxFit.contain,
                                headers: {
                                  'Authorization': 'Bearer ${tokenSnapshot.data}',
                                  'Accept': 'application/json',
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('[ExpenseUI] ❌ Image load error: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error, size: 48, color: Colors.red),
                                        const SizedBox(height: 16),
                                        Text('Failed to load image: ${error.toString()}'),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    try {
      final tokenManager = di.sl<core.TokenManager>();
      final token = await tokenManager.getToken();
      if (token != null) {
        print('[ExpenseUI] 🔑 Token retrieved: ${token.substring(0, 20)}...');
      } else {
        print('[ExpenseUI] ⚠️ No token found');
      }
      return token;
    } catch (e) {
      print('[ExpenseUI] ⚠️ Failed to get auth token: $e');
      return null;
    }
  }

  Future<String?> _getImageUrl(domain.Expense expense) async {
    // Use the authenticated API endpoint to download invoice
    if (expense.id != null) {
      final imageUrl = '${core.ApiConfig.apiUrl}/expenses/${expense.id}/invoice';
      print('[ExpenseUI] 📸 Using API endpoint: $imageUrl');
      return imageUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.expenseCreated ?? 'Expense created successfully')),
          );
          // Reload to get the updated list from server
          if (_currentUserId != null) {
            context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
            // Reload FundBox to get updated balance
            context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
          }
        } else if (state is ExpenseUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.expenseUpdated ?? 'Expense updated successfully')),
          );
          // Reload to get the updated list from server
          if (_currentUserId != null) {
            context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
            // Reload FundBox to get updated balance
            context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
          }
        } else if (state is ExpenseDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.expenseDeleted ?? 'Expense deleted successfully')),
          );
          // Reload to get the updated list from server
          if (_currentUserId != null) {
            context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
            // Reload FundBox to get updated balance
            context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
          }
        } else if (state is ExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ExpenseSyncing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n?.syncing ?? 'Syncing...'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is ExpenseSynced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.syncCompleted ?? 'Sync completed successfully')),
          );
          // Reload to get the updated list from server
          if (_currentUserId != null) {
            context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
          }
        } else if (state is ExpenseSyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n?.syncFailed}: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: WatermarkBackground(
        child: _buildExpenseList(context, l10n!),
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, AppLocalizations l10n) {
    final listView = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ValueListenableBuilder<ExpenseCurrencyFilter>(
          valueListenable: ExpenseFilterNotifier.instance,
          builder: (context, currencyFilter, _) {
            return ValueListenableBuilder<DateFilter>(
              valueListenable: DateFilterNotifier.instance,
              builder: (context, dateFilter, _) {
                return Column(
                  children: [
                    // First row: Currency filter and Add button
                    Row(
                      children: [
                        Text('${l10n?.currency}:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<ExpenseCurrencyFilter>(
                            value: currencyFilter,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: ExpenseCurrencyFilter.all, child: Text(l10n?.all ?? 'All')),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.usd, child: Text(l10n?.usd ?? 'USD')),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.syp, child: Text(l10n?.syp ?? 'SYP')),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.tr, child: Text(l10n?.currencyTry ?? 'TRY')),
                            ],
                            onChanged: (v) {
                              if (v != null) ExpenseFilterNotifier.instance.value = v;
                              setState(_reload);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => _addExpense(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n?.addExpense ?? 'Add expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Date filter
                    Row(
                      children: [
                        Text('${l10n?.date}:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<DateFilterType>(
                            value: dateFilter.type,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: DateFilterType.all, child: Text(l10n?.all ?? 'All')),
                              DropdownMenuItem(value: DateFilterType.today, child: Text(l10n?.today ?? 'Today')),
                              DropdownMenuItem(value: DateFilterType.thisWeek, child: Text(l10n?.thisWeek ?? 'This Week')),
                              DropdownMenuItem(value: DateFilterType.thisMonth, child: Text(l10n?.thisMonth ?? 'This Month')),
                              DropdownMenuItem(value: DateFilterType.custom, child: Text(l10n?.custom ?? 'Custom')),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              
                              if (v == DateFilterType.custom) {
                                final startDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (startDate != null) {
                                  final endDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: startDate,
                                    lastDate: DateTime.now(),
                                  );
                                  if (endDate != null) {
                                    DateFilterNotifier.instance.value = DateFilter(
                                      type: DateFilterType.custom,
                                      startDate: startDate,
                                      endDate: endDate,
                                    );
                                  }
                                }
                              } else {
                                DateFilterNotifier.instance.value = DateFilter(type: v);
                              }
                              setState(_reload);
                            },
                          ),
                        ),
                      ],
                    ),
                    // User filter - only show in admin flavor
                    if (FlavorConfig.instance.isAdmin) ...[
                      const SizedBox(height: 8),
                      ValueListenableBuilder<String?>(
                        valueListenable: UserFilterNotifier.instance,
                        builder: (context, userFilter, _) {
                          // Get unique users from expenses
                          final expenseState = context.read<ExpenseBloc>().state;
                          final allExpenses = <domain.Expense>[];
                          if (expenseState is ExpenseLoaded) {
                            allExpenses.addAll(expenseState.expenses);
                          } else if (expenseState is ExpenseLoading && expenseState.previousExpenses != null) {
                            allExpenses.addAll(expenseState.previousExpenses!);
                          }
                          
                          // Extract unique users with their display names
                          final userMap = <int, String>{};
                          for (final expense in allExpenses) {
                            if (!userMap.containsKey(expense.userId)) {
                              userMap[expense.userId] = expense.creatorUsername ?? 
                                                       expense.creatorEmail ?? 
                                                       'User ${expense.userId}';
                            }
                          }
                          
                          // For admin flavor, also include all group members (including admin owner)
                          return BlocBuilder<AdminGroupBloc, AdminGroupState>(
                            builder: (context, adminGroupState) {
                              // Add group members to user map (this includes all users in the group)
                              if (adminGroupState is GroupMembersLoaded) {
                                for (final member in adminGroupState.members) {
                                  // Always add/update member name from group members list
                                  // This ensures all group members appear in the filter, even if they haven't created expenses yet
                                  userMap[member.id] = member.name;
                                }
                              }
                              
                              // Also add the admin owner if available from adminGroup
                              if (adminGroupState.adminGroup != null) {
                                final adminUserId = adminGroupState.adminGroup!.adminUserId;
                                // Try to get admin name from current auth user or use default
                                final authState = context.read<AuthBloc>().state;
                                String adminName = 'Admin';
                                if (authState is AuthAuthenticated && authState.user?.id == adminUserId) {
                                  adminName = authState.user?.username ?? authState.user?.email ?? 'Admin';
                                }
                                // Add admin to the list if not already present
                                if (!userMap.containsKey(adminUserId)) {
                                  userMap[adminUserId] = adminName;
                                }
                              }
                              
                              final sortedUsers = userMap.entries.toList()
                                ..sort((a, b) => a.value.compareTo(b.value));
                              
                              return Row(
                                children: [
                                  Text('${l10n?.user}:'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<String?>(
                                      value: userFilter,
                                      isExpanded: true,
                                      hint: Text(l10n?.allUsers ?? 'All Users'),
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(l10n?.allUsers ?? 'All Users'),
                                        ),
                                        ...sortedUsers.map((entry) {
                                          return DropdownMenuItem<String?>(
                                            value: entry.key.toString(),
                                            child: Text(entry.value),
                                          );
                                        }),
                                      ],
                                      onChanged: (v) {
                                        UserFilterNotifier.instance.value = v;
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                    if (dateFilter.type == DateFilterType.custom && dateFilter.startDate != null && dateFilter.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${dateFilter.startDate!.day}/${dateFilter.startDate!.month}/${dateFilter.startDate!.year} - ${dateFilter.endDate!.day}/${dateFilter.endDate!.month}/${dateFilter.endDate!.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String?>(
          valueListenable: UserFilterNotifier.instance,
          builder: (context, userFilter, _) {
            return BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                // Use previous expenses if loading, otherwise use loaded expenses
                var domainExpenses = <domain.Expense>[];
                if (state is ExpenseLoaded) {
                  domainExpenses = state.expenses;
                } else if (state is ExpenseLoading && state.previousExpenses != null) {
                  // Show previous expenses while loading to prevent UI clearing
                  domainExpenses = state.previousExpenses!;
                }
                
                final syncStatusMap = state.syncStatusMap;
                final currencyFilter = ExpenseFilterNotifier.instance.value;
                final dateFilter = DateFilterNotifier.instance.value;
                
                // Apply currency filter
                if (currencyFilter != ExpenseCurrencyFilter.all) {
                  domainExpenses = domainExpenses.where((e) {
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
                  domainExpenses = domainExpenses.where((e) {
                    final expenseDate = e.expenseDate;
                    switch (dateFilter.type) {
                      case DateFilterType.today:
                        return expenseDate.year == now.year && 
                               expenseDate.month == now.month && 
                               expenseDate.day == now.day;
                      case DateFilterType.thisWeek:
                        final weekStart = now.subtract(Duration(days: now.weekday - 1));
                        final weekEnd = weekStart.add(const Duration(days: 6));
                        return expenseDate.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                               expenseDate.isBefore(weekEnd.add(const Duration(days: 1)));
                      case DateFilterType.thisMonth:
                        return expenseDate.year == now.year && expenseDate.month == now.month;
                      case DateFilterType.custom:
                        if (dateFilter.startDate != null && dateFilter.endDate != null) {
                          return expenseDate.isAfter(dateFilter.startDate!.subtract(const Duration(days: 1))) && 
                                 expenseDate.isBefore(dateFilter.endDate!.add(const Duration(days: 1)));
                        }
                        return true;
                      case DateFilterType.all:
                        return true;
                    }
                  }).toList();
                }
                
                // Apply user filter (for admin flavor)
                if (userFilter != null && userFilter.isNotEmpty) {
                  final filteredUserId = int.tryParse(userFilter);
                  if (filteredUserId != null) {
                    domainExpenses = domainExpenses.where((e) {
                      return e.userId == filteredUserId;
                    }).toList();
                  }
                }
                
                return Column(
                  children: domainExpenses
                      .map((e) {
                    // Get sync status from map or use the expense's own sync status
                    final syncStatus = e.id != null 
                        ? (syncStatusMap[e.id!] ?? e.syncStatus)
                        : e.syncStatus;
                    
                    // Convert to ExpenseRecord for editing
                    final expenseRecord = ExpenseRecord(
                      id: e.id,
                      description: e.description,
                      priceUsd: e.priceUsd,
                      priceSyp: e.priceSyp,
                      priceTry: e.priceTry,
                      invoiceStatus: InvoiceStatus.values[e.invoiceStatus.index],
                      invoiceFilePath: e.invoiceFilePath,
                      expenseDate: e.expenseDate,
                      createdAt: e.createdAt,
                      updatedAt: e.updatedAt,
                    );
                    
                    return Card(
                      child: ListTile(
                        leading: e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable && 
                                 e.invoiceFilePath != null
                            ? Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(e.invoiceFilePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                        size: 30,
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Icon(
                                e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable 
                                    ? Icons.verified 
                                    : Icons.info_outline,
                                color: e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable 
                                    ? Colors.green 
                                    : null,
                              ),
                        title: Row(
                          children: [
                            Expanded(child: Text(e.description)),
                            const SizedBox(width: 8),
                            SyncStatusIndicator(
                              status: syncStatus,
                              compact: true,
                              onRetry: e.id != null && syncStatus == domain.SyncStatus.failed
                                  ? () {
                                      context.read<ExpenseBloc>().add(SyncExpenseRequested(e));
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text([
                              if (e.priceUsd != null) '${l10n?.usd} ${e.priceUsd!.toStringAsFixed(2)}',
                              if (e.priceSyp != null) '${l10n?.syp} ${e.priceSyp!.toStringAsFixed(0)}',
                              if (e.priceTry != null) '${l10n?.currencyTry} ${e.priceTry!.toStringAsFixed(2)}',
                            ].join(' • ')),
                            // Show creator info for admin
                            if (FlavorConfig.instance.isAdmin && (e.creatorUsername != null || e.creatorEmail != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${l10n?.createdBy}: ${e.creatorUsername ?? e.creatorEmail ?? l10n?.unknownUser}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            // Show invoice image button for admin if available
                            if (FlavorConfig.instance.isAdmin && 
                                e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable &&
                                (e.invoiceCloudFileId != null || e.invoiceFilePath != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: TextButton.icon(
                                  onPressed: () => _showInvoiceImage(context, e),
                                  icon: const Icon(Icons.image, size: 16),
                                  label: Text(
                                    l10n?.viewInvoice ?? 'View Invoice',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _editExpense(context, expenseRecord);
                            } else if (v == 'delete' && _currentUserId != null) {
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n?.confirmDelete ?? 'Confirm Delete'),
                                  content: Text(l10n?.deleteExpenseConfirmation ?? 'Are you sure you want to delete this expense?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n?.cancel ?? 'Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text(l10n?.delete ?? 'Delete'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true && context.mounted) {
                                context.read<ExpenseBloc>().add(DeleteExpenseRequested(
                                  expenseId: e.id!,
                                  userId: _currentUserId!,
                                ));
                              }
                            } else if (v == 'retry' && e.id != null) {
                              context.read<ExpenseBloc>().add(SyncExpenseRequested(e));
                            } else if (v == 'view_image') {
                              _showInvoiceImage(context, e);
                            } else if (v == 'delete_invoice' && e.id != null) {
                              // Show confirmation dialog for invoice deletion
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n?.confirmDelete ?? 'Confirm Delete'),
                                  content: Text(l10n?.deleteInvoiceConfirmation ?? 'Are you sure you want to delete this invoice?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n?.cancel ?? 'Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text(l10n?.delete ?? 'Delete'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true && context.mounted) {
                                // Update expense to remove invoice
                                final updatedExpense = domain.Expense(
                                  id: e.id,
                                  userId: e.userId,
                                  description: e.description,
                                  priceUsd: e.priceUsd,
                                  priceSyp: e.priceSyp,
                                  priceTry: e.priceTry,
                                  invoiceStatus: domain.InvoiceStatus.noInvoice,
                                  invoiceFilePath: null,
                                  expenseDate: e.expenseDate,
                                  createdAt: e.createdAt,
                                  updatedAt: DateTime.now(),
                                );
                                
                                context.read<ExpenseBloc>().add(UpdateExpenseRequested(
                                  expense: updatedExpense,
                                  currentUserId: _currentUserId!,
                                ));
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'edit', child: Text(l10n?.edit ?? 'Edit')),
                            PopupMenuItem(value: 'delete', child: Text(l10n?.delete ?? 'Delete')),
                            if (syncStatus == domain.SyncStatus.failed)
                              PopupMenuItem(value: 'retry', child: Text(l10n?.retrySync ?? 'Retry')),
                            if (e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable &&
                                (e.invoiceCloudFileId != null || e.invoiceFilePath != null)) ...[
                              PopupMenuItem(value: 'view_image', child: Text(l10n?.viewInvoice ?? 'View Invoice')),
                              PopupMenuItem(
                                value: 'delete_invoice',
                                child: Text(
                                  l10n?.deleteInvoice ?? 'Delete Invoice',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                      })
                      .toList(),
                );
              },
            );
          },
        ),
      ], // Close children
    ); // Close ListView

    // Return ListView directly without RefreshIndicator
    return listView;
  }
}


