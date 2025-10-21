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
import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../state/filters.dart';
import '../data/db.dart';
import '../utils/camera_helper.dart';
import '../core/config/flavor_config.dart';
import '../core/services/storage_service.dart';
import '../injection_container.dart' as di;
import 'widgets/sync_status_indicator.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  int? _currentUserId;
  String? _selectedUserFilter;
  domain.SyncStatus? _selectedSyncStatusFilter;

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
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
      context.read<ExpenseBloc>().add(LoadExpensesRequested(_currentUserId!));
    }
  }

  void _reload() {
    if (_currentUserId != null) {
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.translate('new_expense')),
          content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: l10n.translate('item_description')),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(l10n.translate('expense_date')),
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
                        decoration: InputDecoration(labelText: l10n.translate('price_usd')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sypCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.translate('price_syp')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tryCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.translate('price_try')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: status,
                  items: [
                    DropdownMenuItem(value: InvoiceStatus.invoiceAvailable, child: Text(l10n.translate('invoice_available'))),
                    DropdownMenuItem(value: InvoiceStatus.noInvoice, child: Text(l10n.translate('no_invoice_available'))),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? InvoiceStatus.noInvoice),
                  decoration: InputDecoration(labelText: l10n.translate('invoice_status')),
                ),
                if (status == InvoiceStatus.invoiceAvailable) ...[
                  const SizedBox(height: 8),
                  Text(invoicePath ?? l10n.translate('no_file_selected'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final path = await CameraHelper.takePicture(ctx);
                          if (path != null) {
                            setLocal(() => invoicePath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(l10n.translate('take_photo')),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
                          if (res != null && res.files.single.path != null) {
                            setLocal(() => invoicePath = res.files.single.path);
                          }
                        },
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(l10n.translate('from_gallery')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.translate('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.translate('save'))),
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.translate('edit_expense')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: l10n.translate('item_description')),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n.translate('expense_date')),
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
                        decoration: InputDecoration(labelText: l10n.translate('price_usd')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sypCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.translate('price_syp')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tryCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.translate('price_try')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<InvoiceStatus>(
                  initialValue: status,
                  items: [
                    DropdownMenuItem(value: InvoiceStatus.invoiceAvailable, child: Text(l10n.translate('invoice_available'))),
                    DropdownMenuItem(value: InvoiceStatus.noInvoice, child: Text(l10n.translate('no_invoice_available'))),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? InvoiceStatus.noInvoice),
                  decoration: InputDecoration(labelText: l10n.translate('invoice_status')),
                ),
                if (status == InvoiceStatus.invoiceAvailable) ...[
                  const SizedBox(height: 8),
                  Text(invoicePath ?? l10n.translate('no_file_selected'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final path = await CameraHelper.takePicture(ctx);
                          if (path != null) {
                            setLocal(() => invoicePath = path);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(l10n.translate('take_photo')),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
                          if (res != null && res.files.single.path != null) {
                            setLocal(() => invoicePath = res.files.single.path);
                          }
                        },
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(l10n.translate('from_gallery')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.translate('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.translate('save'))),
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

  Future<void> _handleRefresh() async {
    // Trigger sync of all pending expenses
    context.read<ExpenseBloc>().add(const SyncAllPendingRequested());
    
    // Wait a bit for sync to start
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Reload expenses
    _reload();
  }

  List<String> _getUniqueUsers(List<domain.Expense> expenses) {
    final users = <String>{};
    for (final expense in expenses) {
      final user = expense.creatorUsername ?? expense.creatorEmail ?? 'Unknown';
      users.add(user);
    }
    return users.toList()..sort();
  }

  Future<void> _showInvoiceImage(BuildContext context, String? cloudFileId, String? localPath) async {
    if (cloudFileId == null && localPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('no_invoice_image'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: FutureBuilder<String?>(
          future: _getImagePath(cloudFileId, localPath),
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
                    Text(AppLocalizations.of(context).translate('failed_to_load_image')),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(AppLocalizations.of(context).translate('invoice_image')),
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
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.contain,
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

  Future<String?> _getImagePath(String? cloudFileId, String? localPath) async {
    // If we have a local path and it exists, use it
    if (localPath != null && await File(localPath).exists()) {
      return localPath;
    }

    // Otherwise, try to download from cloud
    if (cloudFileId != null) {
      final storageService = di.sl<StorageService>();
      final result = await storageService.downloadInvoiceImage(cloudFileId);
      return result.fold(
        (failure) => null,
        (file) => file.path,
      );
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
            SnackBar(content: Text(l10n.translate('expense_created'))),
          );
          _reload();
        } else if (state is ExpenseUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('expense_updated'))),
          );
          _reload();
        } else if (state is ExpenseDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('expense_deleted'))),
          );
          _reload();
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
                  Text(l10n.translate('syncing')),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is ExpenseSynced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('sync_completed'))),
          );
          _reload();
        } else if (state is ExpenseSyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.translate('sync_failed')}: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
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
                        Text('${l10n.translate('currency')}:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<ExpenseCurrencyFilter>(
                            value: currencyFilter,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: ExpenseCurrencyFilter.all, child: Text(l10n.translate('all'))),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.usd, child: Text(l10n.translate('usd'))),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.syp, child: Text(l10n.translate('syp'))),
                              DropdownMenuItem(value: ExpenseCurrencyFilter.tr, child: Text(l10n.translate('try'))),
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
                          label: Text(l10n.translate('add_expense')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Date filter
                    Row(
                      children: [
                        Text('${l10n.translate('date')}:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<DateFilterType>(
                            value: dateFilter.type,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: DateFilterType.all, child: Text(l10n.translate('all'))),
                              DropdownMenuItem(value: DateFilterType.today, child: Text(l10n.translate('today'))),
                              DropdownMenuItem(value: DateFilterType.thisWeek, child: Text(l10n.translate('this_week'))),
                              DropdownMenuItem(value: DateFilterType.thisMonth, child: Text(l10n.translate('this_month'))),
                              DropdownMenuItem(value: DateFilterType.custom, child: Text(l10n.translate('custom'))),
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
                    // Admin-only filters
                    if (FlavorConfig.instance.isAdmin) ...[
                      const SizedBox(height: 8),
                      // User filter
                      BlocBuilder<ExpenseBloc, ExpenseState>(
                        builder: (context, expenseState) {
                          return Row(
                            children: [
                              Text('${l10n.translate('user')}:'),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String?>(
                                  value: _selectedUserFilter,
                                  isExpanded: true,
                                  hint: Text(l10n.translate('all_users')),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(l10n.translate('all_users')),
                                    ),
                                    ..._getUniqueUsers(expenseState is ExpenseLoaded ? expenseState.expenses : [])
                                        .map((user) => DropdownMenuItem<String>(
                                              value: user,
                                              child: Text(user),
                                            )),
                                  ],
                                  onChanged: (v) {
                                    setState(() => _selectedUserFilter = v);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Sync status filter
                      Row(
                        children: [
                          Text('${l10n.translate('sync_status')}:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<domain.SyncStatus?>(
                              value: _selectedSyncStatusFilter,
                              isExpanded: true,
                              hint: Text(l10n.translate('all_statuses')),
                              items: [
                                DropdownMenuItem<domain.SyncStatus?>(
                                  value: null,
                                  child: Text(l10n.translate('all_statuses')),
                                ),
                                DropdownMenuItem(
                                  value: domain.SyncStatus.pending,
                                  child: Text(l10n.translate('sync_pending')),
                                ),
                                DropdownMenuItem(
                                  value: domain.SyncStatus.syncing,
                                  child: Text(l10n.translate('sync_syncing')),
                                ),
                                DropdownMenuItem(
                                  value: domain.SyncStatus.synced,
                                  child: Text(l10n.translate('sync_synced')),
                                ),
                                DropdownMenuItem(
                                  value: domain.SyncStatus.failed,
                                  child: Text(l10n.translate('sync_failed')),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedSyncStatusFilter = v);
                              },
                            ),
                          ),
                        ],
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
        BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            var domainExpenses = state is ExpenseLoaded 
                ? state.expenses
                : const <domain.Expense>[];
            
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
            
            // Apply admin-only filters
            if (FlavorConfig.instance.isAdmin) {
              // Filter by user
              if (_selectedUserFilter != null) {
                domainExpenses = domainExpenses.where((e) {
                  final user = e.creatorUsername ?? e.creatorEmail ?? 'Unknown';
                  return user == _selectedUserFilter;
                }).toList();
              }
              
              // Filter by sync status
              if (_selectedSyncStatusFilter != null) {
                domainExpenses = domainExpenses.where((e) {
                  return e.syncStatus == _selectedSyncStatusFilter;
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
                        leading: Icon(
                          e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable ? Icons.verified : Icons.info_outline,
                          color: e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable ? Colors.green : null,
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
                              if (e.priceUsd != null) '${l10n.translate('usd')} ${e.priceUsd!.toStringAsFixed(2)}',
                              if (e.priceSyp != null) '${l10n.translate('syp')} ${e.priceSyp!.toStringAsFixed(0)}',
                              if (e.priceTry != null) '${l10n.translate('try')} ${e.priceTry!.toStringAsFixed(2)}',
                            ].join(' • ')),
                            // Show creator info for admin
                            if (FlavorConfig.instance.isAdmin && (e.creatorUsername != null || e.creatorEmail != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${l10n.translate('created_by')}: ${e.creatorUsername ?? e.creatorEmail ?? l10n.translate('unknown_user')}',
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
                                  onPressed: () => _showInvoiceImage(context, e.invoiceCloudFileId, e.invoiceFilePath),
                                  icon: const Icon(Icons.image, size: 16),
                                  label: Text(
                                    l10n.translate('view_invoice'),
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
                              context.read<ExpenseBloc>().add(DeleteExpenseRequested(
                                expenseId: e.id!,
                                userId: _currentUserId!,
                              ));
                            } else if (v == 'retry' && e.id != null) {
                              context.read<ExpenseBloc>().add(SyncExpenseRequested(e));
                            } else if (v == 'view_image') {
                              _showInvoiceImage(context, e.invoiceCloudFileId, e.invoiceFilePath);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'edit', child: Text(l10n.translate('edit'))),
                            PopupMenuItem(value: 'delete', child: Text(l10n.translate('delete'))),
                            if (syncStatus == domain.SyncStatus.failed)
                              PopupMenuItem(value: 'retry', child: Text(l10n.translate('retry_sync'))),
                            if (FlavorConfig.instance.isAdmin && 
                                e.invoiceStatus == domain.InvoiceStatus.invoiceAvailable &&
                                (e.invoiceCloudFileId != null || e.invoiceFilePath != null))
                              PopupMenuItem(value: 'view_image', child: Text(l10n.translate('view_invoice'))),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            );
          },
        ),
      ],
        ),
      ),
    );
  }
}


