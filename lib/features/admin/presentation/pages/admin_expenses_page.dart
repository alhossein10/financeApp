import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/services/filter_persistence_service.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/expenses/domain/entities/expense.dart';
import '../../../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../../../features/expenses/presentation/bloc/expense_event.dart';
import '../../../../features/expenses/presentation/bloc/expense_state.dart';
import '../../../../features/expenses/presentation/widgets/expense_form.dart';
import '../../../../features/expenses/presentation/widgets/invoice_preview_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// Admin Expenses Page
/// Displays Admin's own expenses and all Users' expenses in the group
/// Supports filtering by date, currency, and user
/// Includes inline invoice preview and expense creation
/// 
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.9, 11.10
class AdminExpensesPage extends StatefulWidget {
  const AdminExpensesPage({super.key});

  @override
  State<AdminExpensesPage> createState() => _AdminExpensesPageState();
}

class _AdminExpensesPageState extends State<AdminExpensesPage> {
  // Filter state
  DateTimeRange? _dateRange;
  String? _currencyFilter; // 'USD', 'SYP', 'TRY', or null for all
  int? _userFilter; // User ID or null for all
  
  final ScrollController _scrollController = ScrollController();
  final FilterPersistenceService _filterService = FilterPersistenceService();

  @override
  void initState() {
    super.initState();
    // Restore filters from persistence service
    _restoreFilters();
    _loadExpenses();
    _loadGroupMembers();
  }

  /// Restore filters from persistence service
  /// Requirements: 26.3
  void _restoreFilters() {
    final dateRange = _filterService.adminDateRange;
    final currencyFilter = _filterService.adminCurrencyFilter;
    final userFilter = _filterService.adminUserFilter;
    
    if (mounted) {
      setState(() {
        _dateRange = dateRange;
        _currencyFilter = currencyFilter;
        _userFilter = userFilter;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadExpenses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ExpenseBloc>().add(LoadExpensesRequested(authState.user.id));
    }
  }

  void _loadGroupMembers() {
    context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent(page: 1));
  }

  Future<void> _selectDateRange() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      helpText: l10n.selectDateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _persistFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _currencyFilter = null;
      _userFilter = null;
    });
    _filterService.clearAdminFilters();
  }

  /// Persist current filters to service
  /// Requirements: 26.1, 26.4
  void _persistFilters() {
    _filterService.setAdminFilters(
      dateRange: _dateRange,
      currencyFilter: _currencyFilter,
      userFilter: _userFilter,
    );
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    var filtered = expenses;

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((expense) {
        return expense.expenseDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               expense.expenseDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Currency filter
    if (_currencyFilter != null) {
      filtered = filtered.where((expense) {
        switch (_currencyFilter) {
          case 'USD':
            return expense.priceUsd != null && expense.priceUsd! > 0;
          case 'SYP':
            return expense.priceSyp != null && expense.priceSyp! > 0;
          case 'TRY':
            return expense.priceTry != null && expense.priceTry! > 0;
          default:
            return true;
        }
      }).toList();
    }

    // User filter
    if (_userFilter != null) {
      filtered = filtered.where((expense) => expense.userId == _userFilter).toList();
    }

    return filtered;
  }

  void _showCreateExpenseDialog() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: ExpenseForm(
            userId: authState.user.id,
            onSubmit: (formData) {
              // Create expense
              final currencyAmounts = formData.currencyAmounts;
              context.read<ExpenseBloc>().add(
                CreateExpenseRequested(
                  userId: authState.user.id,
                  description: formData.description,
                  priceUsd: currencyAmounts['priceUsd'],
                  priceSyp: currencyAmounts['priceSyp'],
                  priceTry: currencyAmounts['priceTry'],
                  invoiceStatus: formData.invoiceFile != null 
                      ? InvoiceStatus.invoiceAvailable 
                      : InvoiceStatus.noInvoice,
                  invoiceFilePath: formData.invoiceFile?.path,
                  expenseDate: formData.expenseDate,
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            onCancel: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenses),
        centerTitle: true,
        actions: [
          // Filter indicator
          if (_dateRange != null || _currencyFilter != null || _userFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getActiveFilterCount().toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.expenseCreatedSuccessfully),
                backgroundColor: Colors.green,
              ),
            );
            _loadExpenses();
          } else if (state is ExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, expenseState) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadExpenses();
              _loadGroupMembers();
            },
            child: Column(
              children: [
                // Filters section
                _buildFiltersSection(context, l10n, theme),
                
                // Expenses list
                Expanded(
                  child: _buildExpensesList(context, expenseState, l10n, theme),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateExpenseDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.createExpense),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.filters,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_dateRange != null || _currencyFilter != null || _userFilter != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(l10n.clearAll),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Date range filter
              FilterChip(
                label: Text(
                  _dateRange != null
                      ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                      : l10n.dateRange,
                ),
                selected: _dateRange != null,
                onSelected: (_) => _selectDateRange(),
                avatar: const Icon(Icons.calendar_today, size: 18),
              ),
              
              // Currency filter
              DropdownButton<String?>(
                value: _currencyFilter,
                hint: Text(l10n.currency),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allCurrencies)),
                  const DropdownMenuItem(value: 'USD', child: Text('USD')),
                  const DropdownMenuItem(value: 'SYP', child: Text('SYP')),
                  const DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                ],
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      _currencyFilter = value;
                    });
                    _persistFilters();
                  }
                },
              ),
              
              // User filter
              BlocBuilder<AdminGroupBloc, AdminGroupState>(
                builder: (context, groupState) {
                  final members = groupState.members;
                  final authState = context.read<AuthBloc>().state;
                  
                  // Build list of unique user IDs to avoid duplicates
                  final userIds = <int>{};
                  final userItems = <DropdownMenuItem<int?>>[];
                  
                  // Add "All Users" option
                  userItems.add(DropdownMenuItem(value: null, child: Text(l10n.allUsers)));
                  
                  // Add admin (current user)
                  if (authState is Authenticated) {
                    userIds.add(authState.user.id);
                    userItems.add(DropdownMenuItem(
                      value: authState.user.id,
                      child: Text('${l10n.me} (Admin)'),
                    ));
                  }
                  
                  // Add group members (only if not already added)
                  for (final member in members) {
                    if (!userIds.contains(member.id)) {
                      userIds.add(member.id);
                      userItems.add(DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ));
                    }
                  }
                  
                  return DropdownButton<int?>(
                    value: _userFilter,
                    hint: Text(l10n.user),
                    underline: const SizedBox(),
                    items: userItems,
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {
                          _userFilter = value;
                        });
                        _persistFilters();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    ExpenseState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (state is ExpenseLoading && state.previousExpenses == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ExpenseError && state is! ExpenseLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingExpenses,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExpenses,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final expenses = state is ExpenseLoaded ? state.expenses : <Expense>[];
    final filteredExpenses = _applyFilters(expenses);

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.noExpensesFound,
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstExpense,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = filteredExpenses[index];
        // Get fresh l10n and theme for each card to avoid stale context issues
        final cardL10n = AppLocalizations.of(context);
        final cardTheme = Theme.of(context);
        return _buildExpenseCard(context, expense, cardL10n, cardTheme);
      },
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final authState = context.read<AuthBloc>().state;
    final isOwnExpense = authState is Authenticated && expense.userId == authState.user.id;
    
    // Determine currency and amount
    String currency;
    double amount;
    if (expense.priceUsd != null && expense.priceUsd! > 0) {
      currency = 'USD';
      amount = expense.priceUsd!;
    } else if (expense.priceSyp != null && expense.priceSyp! > 0) {
      currency = 'SYP';
      amount = expense.priceSyp!;
    } else if (expense.priceTry != null && expense.priceTry! > 0) {
      currency = 'TRY';
      amount = expense.priceTry!;
    } else {
      currency = 'N/A';
      amount = 0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: expense.invoiceStatus == InvoiceStatus.invoiceAvailable && expense.id != null
            ? () => showInvoicePreview(
                  context: context,
                  expenseId: expense.id!,
                  localFilePath: expense.invoiceFilePath,
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Currency badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCurrencyColor(currency).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        color: _getCurrencyColor(currency),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // User indicator - show username if available, otherwise show user ID
                  if (!isOwnExpense)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.creatorUsername != null && expense.creatorUsername!.isNotEmpty
                            ? expense.creatorUsername!
                            : 'User #${expense.userId}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Amount
                  Text(
                    _formatAmount(amount, currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                expense.description,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              
              // Date and invoice indicator
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(expense.expenseDate),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  if (expense.invoiceStatus == InvoiceStatus.invoiceAvailable)
                    Row(
                      children: [
                        Icon(Icons.receipt, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          l10n.hasInvoice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Invoice preview button
              if (expense.invoiceStatus == InvoiceStatus.invoiceAvailable && expense.id != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => showInvoicePreview(
                      context: context,
                      expenseId: expense.id!,
                      localFilePath: expense.invoiceFilePath,
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(l10n.viewInvoice),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USD':
        return Colors.green;
      case 'SYP':
        return Colors.blue;
      case 'TRY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: currency == 'SYP' ? 0 : 2,
    );
    return '${formatter.format(amount)} $currency';
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_dateRange != null) count++;
    if (_currencyFilter != null) count++;
    if (_userFilter != null) count++;
    return count;
  }
}