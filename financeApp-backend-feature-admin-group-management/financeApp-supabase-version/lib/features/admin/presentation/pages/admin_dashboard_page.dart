import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../../../../features/expenses/domain/entities/expense.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    
    // Only load data if admin flavor
    if (FlavorConfig.instance.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminBloc>().add(const FetchAdminStatisticsRequested());
        context.read<AdminBloc>().add(const FetchAllUserExpensesRequested());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Check if admin flavor
    if (!FlavorConfig.instance.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('admin_dashboard')),
        ),
        body: Center(
          child: Text(l10n.translate('unauthorized_access')),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('admin_dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminBloc>().add(const FetchAdminStatisticsRequested());
              context.read<AdminBloc>().add(const FetchAllUserExpensesRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AdminBloc>().add(const FetchAdminStatisticsRequested());
                      context.read<AdminBloc>().add(const FetchAllUserExpensesRequested());
                    },
                    child: Text(l10n.translate('retry')),
                  ),
                ],
              ),
            );
          }
          
          if (state is AdminLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const FetchAdminStatisticsRequested());
                context.read<AdminBloc>().add(const FetchAllUserExpensesRequested());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Statistics Cards
                  _buildStatisticsSection(context, state, l10n),
                  const SizedBox(height: 24),
                  
                  // Recent User Expenses
                  _buildRecentExpensesSection(context, state, l10n),
                  const SizedBox(height: 24),
                  
                  // User Activity Summary
                  _buildUserActivitySection(context, state, l10n),
                ],
              ),
            );
          }
          
          return Center(
            child: Text(l10n.translate('no_data_available')),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AdminLoaded state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('statistics'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              icon: Icons.people,
              title: l10n.translate('total_users'),
              value: state.totalUsers.toString(),
              color: Colors.blue,
            ),
            _buildStatCard(
              context,
              icon: Icons.receipt_long,
              title: l10n.translate('total_expenses'),
              value: state.totalExpenses.toString(),
              color: Colors.green,
            ),
            _buildStatCard(
              context,
              icon: Icons.pending,
              title: l10n.translate('pending_sync'),
              value: state.pendingSync.toString(),
              color: Colors.orange,
            ),
            _buildStatCard(
              context,
              icon: Icons.attach_money,
              title: l10n.translate('total_amount'),
              value: '\$${state.totalAmount.toStringAsFixed(2)}',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpensesSection(BuildContext context, AdminLoaded state, AppLocalizations l10n) {
    final recentExpenses = state.recentExpenses.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('recent_user_expenses'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (recentExpenses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(l10n.translate('no_expenses_yet')),
              ),
            ),
          )
        else
          ...recentExpenses.map((expense) => _buildExpenseCard(context, expense, l10n)),
      ],
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: expense.syncStatus == SyncStatus.synced 
              ? Colors.green 
              : Colors.orange,
          child: Icon(
            expense.invoiceStatus == InvoiceStatus.invoiceAvailable 
                ? Icons.receipt 
                : Icons.description,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.translate('created_by')}: ${expense.creatorUsername ?? expense.creatorEmail ?? l10n.translate('unknown_user')}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (expense.priceUsd != null) '${l10n.translate('usd')} ${expense.priceUsd!.toStringAsFixed(2)}',
                if (expense.priceSyp != null) '${l10n.translate('syp')} ${expense.priceSyp!.toStringAsFixed(0)}',
                if (expense.priceTry != null) '${l10n.translate('try')} ${expense.priceTry!.toStringAsFixed(2)}',
              ].join(' • '),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 4),
            _buildSyncStatusBadge(expense.syncStatus, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge(SyncStatus status, AppLocalizations l10n) {
    Color color;
    String text;
    
    switch (status) {
      case SyncStatus.pending:
        color = Colors.orange;
        text = l10n.translate('sync_pending');
        break;
      case SyncStatus.syncing:
        color = Colors.blue;
        text = l10n.translate('sync_syncing');
        break;
      case SyncStatus.synced:
        color = Colors.green;
        text = l10n.translate('sync_synced');
        break;
      case SyncStatus.failed:
        color = Colors.red;
        text = l10n.translate('sync_failed');
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserActivitySection(BuildContext context, AdminLoaded state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('user_activity_summary'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (state.userActivityMap.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(l10n.translate('no_user_activity')),
              ),
            ),
          )
        else
          ...state.userActivityMap.entries.map((entry) {
            final username = entry.key;
            final count = entry.value;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(username),
                trailing: Chip(
                  label: Text('$count ${l10n.translate('expenses')}'),
                  backgroundColor: Colors.blue.withOpacity(0.2),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
