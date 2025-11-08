import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../features/admin/presentation/bloc/super_admin_analytics_bloc.dart';
import '../features/admin/presentation/bloc/super_admin_analytics_event.dart';
import '../features/admin/presentation/bloc/super_admin_analytics_state.dart';
import '../features/admin/domain/entities/super_admin_analytics.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/watermark_background.dart';

/// SuperAdmin Expenses Page
/// Displays aggregated expense summaries grouped by admin group using analytics API
/// No expense creation - read-only view
class SuperAdminExpensesPage extends StatefulWidget {
  const SuperAdminExpensesPage({super.key});

  @override
  State<SuperAdminExpensesPage> createState() => _SuperAdminExpensesPageState();
}

class _SuperAdminExpensesPageState extends State<SuperAdminExpensesPage> {
  String _selectedPeriod = 'all'; // '15days', 'month', 'all'
  String? _selectedGroupFilter; // null means "All Groups"

  @override
  void initState() {
    super.initState();
    // Load analytics on page load
    context.read<SuperAdminAnalyticsBloc>().add(
      LoadSuperAdminAnalyticsEvent(_selectedPeriod),
    );
  }

  Future<void> _handleRefresh() async {
    context.read<SuperAdminAnalyticsBloc>().add(
      LoadSuperAdminAnalyticsEvent(_selectedPeriod),
    );
  }

  List<AdminGroupAnalytics> _getFilteredGroups(SuperAdminAnalytics analytics) {
    if (_selectedGroupFilter == null) {
      return analytics.adminGroups;
    } else {
      final groupId = int.tryParse(_selectedGroupFilter!);
      if (groupId == null) return analytics.adminGroups;
      return analytics.adminGroups
          .where((group) => group.adminGroup.id == groupId)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return WatermarkBackground(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildContent(context, l10n),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<SuperAdminAnalyticsBloc, SuperAdminAnalyticsState>(
      builder: (context, state) {
        if (state is SuperAdminAnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SuperAdminAnalyticsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isForbidden
                      ? Icons.lock_outline
                      : Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (state.isForbidden) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'SuperAdmin access required',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<SuperAdminAnalyticsBloc>().add(
                      LoadSuperAdminAnalyticsEvent(_selectedPeriod),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.translate('retry')),
                ),
              ],
            ),
          );
        }

        if (state is SuperAdminAnalyticsLoaded) {
          final analytics = state.analytics;
          final filteredGroups = _getFilteredGroups(analytics);

          if (analytics.adminGroups.isEmpty) {
            return Center(
              child: Text(l10n.translate('no_data_available')),
            );
          }

          // Calculate grand totals for expenses
          final grandTotalExpenseCount = analytics.adminGroups
              .fold<int>(0, (sum, group) => sum + group.expenses.count);
          final grandTotalUsd = analytics.adminGroups
              .fold<double>(0.0, (sum, group) => sum + group.expenses.totalUsd);
          final grandTotalSyp = analytics.adminGroups
              .fold<double>(0.0, (sum, group) => sum + group.expenses.totalSyp);
          final grandTotalTry = analytics.adminGroups
              .fold<double>(0.0, (sum, group) => sum + group.expenses.totalTry);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period Filter
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '15days', label: Text('15 Days')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                    ButtonSegment(value: 'all', label: Text('All Time')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPeriod = newSelection.first;
                    });
                    context.read<SuperAdminAnalyticsBloc>().add(
                      LoadSuperAdminAnalyticsEvent(_selectedPeriod),
                    );
                  },
                ),
              ),
              
              // Filter dropdown
              _buildFilterSection(context, l10n, analytics),
              const SizedBox(height: 16),
              
              // Grand total card (only show when "All Groups" is selected)
              if (_selectedGroupFilter == null) ...[
                _buildGrandTotalCard(
                  context,
                  l10n,
                  grandTotalExpenseCount,
                  grandTotalUsd,
                  grandTotalSyp,
                  grandTotalTry,
                ),
                const SizedBox(height: 16),
              ],
              
              // Group summary cards
              if (filteredGroups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.translate('no_expenses_found'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ...filteredGroups.map((groupAnalytics) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGroupSummaryCard(context, l10n, groupAnalytics),
                )),
            ],
          );
        }

        return Center(
          child: Text(l10n.translate('no_data_available')),
        );
      },
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    AppLocalizations l10n,
    SuperAdminAnalytics analytics,
  ) {
    if (analytics.adminGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Text(
          '${l10n.translate('filter_by_group')}:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String?>(
            value: _selectedGroupFilter,
            isExpanded: true,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.translate('all_groups')),
              ),
              ...analytics.adminGroups.map((groupAnalytics) {
                return DropdownMenuItem<String?>(
                  value: groupAnalytics.adminGroup.id.toString(),
                  child: Text(groupAnalytics.adminGroup.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGroupFilter = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrandTotalCard(
    BuildContext context,
    AppLocalizations l10n,
    int totalExpenseCount,
    double totalUsd,
    double totalSyp,
    double totalTry,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormat = NumberFormat('#,###');

    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('grand_total'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Total expense count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('total_expenses'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                Text(
                  '$totalExpenseCount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Currency totals
            if (totalUsd > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'USD:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      currencyFormat.format(totalUsd),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            if (totalSyp > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYP:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      numberFormat.format(totalSyp),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            if (totalTry > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRY:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      numberFormat.format(totalTry),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    AdminGroupAnalytics groupAnalytics,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormat = NumberFormat('#,###');
    final expenses = groupAnalytics.expenses;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group name and code
            Row(
              children: [
                const Icon(Icons.group, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupAnalytics.adminGroup.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${groupAnalytics.adminGroup.code}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Admin: ${groupAnalytics.adminGroup.adminUser.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Expense count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('expense_count'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${expenses.count}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Currency totals
            if (expenses.totalUsd > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'USD:',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    currencyFormat.format(expenses.totalUsd),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (expenses.totalSyp > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SYP:',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    numberFormat.format(expenses.totalSyp),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (expenses.totalTry > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRY:',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    numberFormat.format(expenses.totalTry),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
