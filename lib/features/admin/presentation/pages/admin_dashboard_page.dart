import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/error_display.dart';
import '../../../../core/widgets/role_based_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/watermark_background.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
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
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    
    // Initialize date range to last 30 days
    _selectedEndDate = DateTime.now();
    _selectedStartDate = _selectedEndDate!.subtract(const Duration(days: 30));
    
    // Only load data if admin flavor and user is admin
    if (FlavorConfig.instance.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if user is actually admin before loading data
        if (context.isAdmin) {
          _loadDashboardData();
        }
      });
    }
  }

  void _loadDashboardData() {
    context.read<AdminBloc>().add(const FetchDashboardStatsRequested());
    context.read<AdminBloc>().add(const FetchUserActivityRequested());
    context.read<AdminBloc>().add(const FetchExpenseSummariesRequested());
    if (_selectedStartDate != null && _selectedEndDate != null) {
      context.read<AdminBloc>().add(FetchAnalyticsRequested(
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
      ));
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _selectedEndDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      
      // Reload analytics with new date range
      context.read<AdminBloc>().add(FetchAnalyticsRequested(
        startDate: _selectedStartDate!,
        endDate: _selectedEndDate!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if admin flavor is enabled
    if (!FlavorConfig.instance.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('admin_dashboard')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.translate('unauthorized_access'),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is only available in the admin version of the app.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if user has admin role
    if (!context.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('admin_dashboard')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin privileges required to access this feature.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('admin_dashboard')),
        automaticallyImplyLeading: false, // Remove back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Group Management',
            onPressed: () {
              Navigator.of(context).pushNamed('/group-management');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: WatermarkBackground(
        child: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
          if (state is AdminLoading) {
            return _buildLoadingSkeleton(context);
          }
          
          if (state is AdminError) {
            // Handle 403 Forbidden errors specially
            if (state.isForbidden) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Denied',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.translate('go_back')),
                    ),
                  ],
                ),
              );
            }
            
            // Handle logout required errors
            if (state.requiresLogout) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                Navigator.of(context).pushReplacementNamed('/login');
              });
            }
            
            return ErrorStateWidget(
              title: l10n.translate('error_occurred'),
              message: state.message,
              icon: Icons.error_outline,
              onRetry: () {
                context.read<AdminBloc>().add(const FetchAdminStatisticsRequested());
                context.read<AdminBloc>().add(const FetchAllUserExpensesRequested());
              },
            );
          }
          
          // Handle new API-based states
          if (state is AdminDashboardStatsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Range Selector
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: 16),
                  
                  // Statistics Cards from API
                  _buildApiStatisticsSection(context, state, l10n),
                  const SizedBox(height: 24),
                  
                  // Info message
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dashboard data is filtered by your admin group. Only members of your group are included.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (state is AdminUserActivityLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: 16),
                  _buildUserActivityList(context, state, l10n),
                ],
              ),
            );
          }
          
          if (state is AdminExpenseSummariesLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: 16),
                  _buildExpenseSummaries(context, state, l10n),
                ],
              ),
            );
          }
          
          if (state is AdminAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: 16),
                  _buildAnalyticsSection(context, state, l10n),
                ],
              ),
            );
          }
          
          if (state is AdminLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Range Selector
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: 16),
                  
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
      ),
    );
  }

  /// Build skeleton loading state for dashboard
  Widget _buildLoadingSkeleton(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getResponsiveGridCrossAxisCount(context);

    return Semantics(
      label: 'Loading dashboard data',
      child: ListView(
        padding: ResponsiveUtils.getResponsivePadding(context),
        children: [
          // Date range selector skeleton
          const SkeletonCard(height: 72),
          const SizedBox(height: 16),

          // Statistics title skeleton
          SkeletonLoader(
            width: 120,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),

          // Statistics grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonCard(height: 100),
          ),
          const SizedBox(height: 24),

          // Recent expenses title skeleton
          SkeletonLoader(
            width: 180,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),

          // Expense list skeleton
          ...List.generate(3, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonListItem(height: 80),
          )),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: Text(l10n.translate('date_range')),
        subtitle: _selectedStartDate != null && _selectedEndDate != null
            ? Text(
                '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - '
                '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}',
              )
            : Text(l10n.translate('select_date_range')),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectDateRange,
      ),
    );
  }

  Widget _buildApiStatisticsSection(BuildContext context, AdminDashboardStatsLoaded state, AppLocalizations l10n) {
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
              icon: Icons.arrow_downward,
              title: l10n.translate('total_income'),
              value: state.totalIncome.toString(),
              color: Colors.orange,
            ),
            _buildStatCard(
              context,
              icon: Icons.swap_horiz,
              title: l10n.translate('total_transfers'),
              value: state.totalTransfers.toString(),
              color: Colors.purple,
            ),
            _buildStatCard(
              context,
              icon: Icons.attach_money,
              title: l10n.translate('expense_amount'),
              value: '\$${state.totalAmountExpenses.toStringAsFixed(2)}',
              color: Colors.red,
            ),
            _buildStatCard(
              context,
              icon: Icons.account_balance_wallet,
              title: l10n.translate('fund_box_balance'),
              value: '\$${state.fundBoxBalance.toStringAsFixed(2)}',
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserActivityList(BuildContext context, AdminUserActivityLoaded state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('user_activity'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (state.userActivity.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(l10n.translate('no_user_activity')),
              ),
            ),
          )
        else
          ...state.userActivity.map((user) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(user.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${user.role}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (user.lastLogin != null)
                    Text(
                      'Last login: ${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}',
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
              trailing: Chip(
                label: Text(user.role),
                backgroundColor: user.role == 'admin' 
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildExpenseSummaries(BuildContext context, AdminExpenseSummariesLoaded state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('expense_summaries'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // By Category
        if (state.summary.byCategory.isNotEmpty) ...[
          Text(
            l10n.translate('by_category'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.summary.byCategory.map((category) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.category),
              title: Text(category.category),
              subtitle: Text('${category.count} expenses'),
              trailing: Text(
                '\$${category.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),
        ],
        
        // By Payment Method
        if (state.summary.byPaymentMethod.isNotEmpty) ...[
          Text(
            l10n.translate('by_payment_method'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.summary.byPaymentMethod.map((method) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.payment),
              title: Text(method.paymentMethod),
              trailing: Text(
                '\$${method.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, AdminAnalyticsLoaded state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('analytics'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Period Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period: ${state.analytics.period.from} to ${state.analytics.period.to}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Expenses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('expenses'),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${state.analytics.expenses.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '${state.analytics.expenses.count} items',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.translate('income'),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${state.analytics.income.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${state.analytics.income.count} items',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Net Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('net_balance'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${state.analytics.netBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: state.analytics.netBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Monthly Trends
        if (state.analytics.trends.monthly.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.translate('monthly_trends'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.analytics.trends.monthly.map((trend) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(trend.month),
              subtitle: Row(
                children: [
                  Text(
                    'Expenses: \$${trend.expenses.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Income: \$${trend.income.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
        color: color.withValues(alpha: 0.2),
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
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
            );
          }),
      ],
    );
  }
}
