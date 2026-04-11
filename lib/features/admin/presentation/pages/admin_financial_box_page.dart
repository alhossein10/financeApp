import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/multi_currency_balance_card.dart';
import '../../../../core/widgets/watermark_background.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../../../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../../../features/transfers/presentation/bloc/transfer_event.dart';
import '../../../../features/transfers/presentation/bloc/transfer_state.dart';
import '../../../../features/transfers/domain/entities/transfer_type.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../../../../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';

/// Admin Financial Box Page
/// 
/// Displays multi-currency balance card, incoming transfers from Superadmin,
/// and outgoing transfers to Users with filters and export functionality
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7
class AdminFinancialBoxPage extends StatefulWidget {
  const AdminFinancialBoxPage({super.key});

  @override
  State<AdminFinancialBoxPage> createState() => _AdminFinancialBoxPageState();
}

class _AdminFinancialBoxPageState extends State<AdminFinancialBoxPage> with SingleTickerProviderStateMixin {
  int? _currentUserId;
  late TabController _tabController;
  
  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedUserId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load user and data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      
      // Load fund box for Admin
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      
      // Load incoming transfers (from Superadmin)
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.incoming),
      );
      
      // Load group members for filters
      context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      // Reload all data
      context.read<FundBoxBloc>().add(RefreshFundBox(_currentUserId!));
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.incoming),
      );
    }
  }

  Future<void> _showFilters(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final adminGroupState = context.read<AdminGroupBloc>().state;
    final groupMembers = adminGroupState.members;
    
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    int? tempSelectedUserId = _selectedUserId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.translate('filters') ?? 'Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date range filter
                ListTile(
                  title: Text(l10n.translate('start_date') ?? 'Start Date'),
                  subtitle: Text(
                    tempStartDate != null
                        ? DateFormatter.toApiDate(tempStartDate!)
                        : l10n.translate('not_set') ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setLocal(() => tempStartDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(l10n.translate('end_date') ?? 'End Date'),
                  subtitle: Text(
                    tempEndDate != null
                        ? DateFormatter.toApiDate(tempEndDate!)
                        : l10n.translate('not_set') ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: tempStartDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setLocal(() => tempEndDate = date);
                    }
                  },
                ),
                const Divider(),
                // User filter (for outgoing transfers)
                if (_tabController.index == 1) // Only show for outgoing tab
                  DropdownButtonFormField<int?>(
                    decoration: InputDecoration(
                      labelText: l10n.translate('filter_by_user') ?? 'Filter by User',
                      border: const OutlineInputBorder(),
                    ),
                    value: tempSelectedUserId,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n.translate('all_users') ?? 'All Users'),
                      ),
                      ...groupMembers.map((member) {
                        return DropdownMenuItem<int?>(
                          value: member.id,
                          child: Text(member.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setLocal(() => tempSelectedUserId = value);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear filters
                setLocal(() {
                  tempStartDate = null;
                  tempEndDate = null;
                  tempSelectedUserId = null;
                });
              },
              child: Text(l10n.translate('clear') ?? 'Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('cancel') ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('apply') ?? 'Apply'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _startDate = tempStartDate;
        _endDate = tempEndDate;
        _selectedUserId = tempSelectedUserId;
        if (tempSelectedUserId != null) {
          final member = adminGroupState.members.firstWhere(
            (m) => m.id == tempSelectedUserId,
            orElse: () => adminGroupState.members.first,
          );
          _selectedUserName = member.name;
        } else {
          _selectedUserName = null;
        }
      });
      // Apply filters by reloading data
      // TODO: Implement filtered loading in the bloc
      _reload();
    }
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // TODO: Implement PDF export with filters
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('export_pdf_coming_soon') ?? 'PDF export coming soon'),
      ),
    );
  }

  Widget _buildIncomingTransfersList(BuildContext context, TransferState state) {
    final l10n = AppLocalizations.of(context);
    
    if (state is TransferLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (state is TransferError) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.translate('retry') ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (state is TransferLoaded) {
      var transfers = state.transfers;
      
      // Apply date filters
      if (_startDate != null) {
        transfers = transfers.where((t) => 
          t.transactionDate.isAfter(_startDate!) || 
          t.transactionDate.isAtSameMomentAs(_startDate!)
        ).toList();
      }
      if (_endDate != null) {
        transfers = transfers.where((t) => 
          t.transactionDate.isBefore(_endDate!.add(const Duration(days: 1)))
        ).toList();
      }
      
      if (transfers.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('no_incoming_transfers') ?? 'No incoming transfers',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
      
      return Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final transfer = transfers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.arrow_downward, color: Colors.green),
                  ),
                  title: Text(l10n.translate('from_superadmin') ?? 'From Superadmin'),
                  subtitle: Text(
                    DateFormatter.toApiDate(transfer.transactionDate),
                  ),
                  trailing: Text(
                    '\$${transfer.amountUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return const Expanded(child: SizedBox.shrink());
  }

  Widget _buildOutgoingTransfersList(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // TODO: Load outgoing transfers to users
    // For now, show placeholder
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.translate('outgoing_transfers_coming_soon') ?? 'Outgoing transfers coming soon',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasActiveFilters = _startDate != null || _endDate != null || _selectedUserId != null;
    
    return MultiBlocListener(
      listeners: [
        BlocListener<FundBoxBloc, FundBoxState>(
          listener: (context, state) {
            if (state is FundBoxError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<TransferBloc, TransferState>(
          listener: (context, state) {
            if (state is TransferError && !state.isOffline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
      ],
      child: WatermarkBackground(
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('cash') ?? 'Cash'),
            actions: [
              // Filter button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilters(context),
                    tooltip: l10n.translate('filters') ?? 'Filters',
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _exportToPdf(context),
                tooltip: l10n.translate('export_pdf') ?? 'Export PDF',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
                tooltip: l10n.translate('refresh') ?? 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              // Multi-Currency Balance Card
              BlocBuilder<FundBoxBloc, FundBoxState>(
                builder: (context, state) {
                  if (state is FundBoxLoading) {
                    return const MultiCurrencyBalanceCard(
                      isLoading: true,
                    );
                  }
                  
                  if (state is FundBoxError) {
                    return MultiCurrencyBalanceCard(
                      errorMessage: state.message,
                      onRefresh: _reload,
                    );
                  }
                  
                  if (state is FundBoxLoaded) {
                    final fundBox = state.fundBox;
                    return MultiCurrencyBalanceCard(
                      balanceUsd: fundBox.balanceUsd,
                      balanceSyp: fundBox.balanceSyp,
                      balanceTry: fundBox.balanceTry,
                      lastUpdated: fundBox.updatedAt,
                      onRefresh: _reload,
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
              
              // Tabs for Incoming and Outgoing
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.translate('incoming') ?? 'Incoming'),
                  Tab(text: l10n.translate('outgoing') ?? 'Outgoing'),
                ],
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Incoming Tab (from Superadmin)
                    BlocBuilder<TransferBloc, TransferState>(
                      builder: (context, state) => _buildIncomingTransfersList(context, state),
                    ),
                    // Outgoing Tab (to Users)
                    _buildOutgoingTransfersList(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
