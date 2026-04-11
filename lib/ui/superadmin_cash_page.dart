import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../features/transfers/presentation/bloc/transfer_event.dart';
import '../features/transfers/presentation/bloc/transfer_state.dart';
import '../features/transfers/domain/entities/transfer_type.dart';
import '../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../features/incoming/presentation/bloc/incoming_event.dart';
import '../features/incoming/presentation/bloc/incoming_state.dart';
import '../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/watermark_background.dart';
import '../core/widgets/multi_currency_balance_card.dart';
import '../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';

/// SuperAdmin Cash Page
/// 
/// Displays outgoing transfers for SuperAdmin.
/// Allows creating outgoing transfers to admin users in the SuperAdmin's group.
/// SuperAdmin can create transfers without fund-box balance restrictions.
/// 
/// Requirements: 2.2, 2.3, 2.4, 2.6
class SuperAdminCashPage extends StatefulWidget {
  const SuperAdminCashPage({super.key});

  @override
  State<SuperAdminCashPage> createState() => _SuperAdminCashPageState();
}

class _SuperAdminCashPageState extends State<SuperAdminCashPage> with SingleTickerProviderStateMixin {
  int? _currentUserId;
  late TabController _tabController;

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
      
      // Load fund box for SuperAdmin
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      
      // Load outgoing transfers
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.outgoing),
      );
      
      // Load incoming records
      context.read<IncomingBloc>().add(const LoadIncoming());
      
      // Load group members for recipient selection
      context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      // Reload all data
      context.read<FundBoxBloc>().add(RefreshFundBox(_currentUserId!));
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.outgoing),
      );
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }

  Future<void> _createOutgoingTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    // Get admin members from the group
    final adminGroupState = context.read<AdminGroupBloc>().state;
    final adminMembers = adminGroupState.members.where((m) => m.isAdmin).toList();
    
    if (adminMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.noAdminMembersAvailable ?? 'No admin members available')),
      );
      return;
    }
    
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedRecipientName;
    int? selectedRecipientId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.createOutgoingTransfer ?? 'Create Outgoing Transfer'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recipient dropdown (admins only)
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: l10n?.recipientName ?? 'Recipient name',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    initialValue: selectedRecipientId,
                    items: adminMembers.map((member) {
                      return DropdownMenuItem<int>(
                        value: member.id,
                        child: Text(
                          '${member.name} (${member.email})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      // Show only the name (not email) in the selected display to save space
                      return adminMembers.map<Widget>((member) {
                        return Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );
                      }).toList();
                    },
                    onChanged: (value) {
                      setLocal(() {
                        selectedRecipientId = value;
                        selectedRecipientName = adminMembers
                            .firstWhere((m) => m.id == value)
                            .name;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n?.amountUsd ?? 'Amount USD',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(l10n?.transactionDate ?? 'Transaction Date'),
                    subtitle: Text(DateFormatter.toApiDate(selectedDate)),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n?.create ?? 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && _currentUserId != null) {
      final name = selectedRecipientName;
      final amount = double.tryParse(amountController.text.trim());
      
      if (name == null || name.isEmpty || amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.pleaseFillAllFields ?? 'Please fill all fields')),
        );
        return;
      }

      if (context.mounted) {
        context.read<TransferBloc>().add(CreateTransferEvent(
          userId: _currentUserId!,
          recipientName: name,
          recipientUserId: selectedRecipientId, // Pass recipient user ID (required for SuperAdmin transfers)
          adminGroupId: null, // Backend should set this automatically from recipient's admin_group_id
          amountUsd: amount,
          convertedAmountUsd: 0.0,
          amountSypAtExchange: null,
          manualUsdToSypRate: null,
          transactionDate: selectedDate,
        ));
      }
    }
  }

  Future<void> _createIncoming(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.newIncoming ?? 'New Incoming'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n?.description ?? 'Description'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n?.amountUsd ?? 'Amount (USD)'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n?.transactionDate ?? 'Transaction Date'),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n?.create ?? 'Create')),
          ],
        ),
      ),
    );

    if (result == true) {
      final desc = descController.text.trim();
      final amount = double.tryParse(amountController.text.trim());
      if (desc.isEmpty || amount == null || amount <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.pleaseFillAllFields ?? 'Please fill all fields')),
          );
        }
        return;
      }

      if (context.mounted) {
        context.read<IncomingBloc>().add(CreateIncoming(
          description: desc,
          amountUsd: amount,
          transactionDate: selectedDate,
        ));
      }
    }
  }

  Widget _buildTransfersList(BuildContext context, TransferState state) {
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
                label: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (state is TransferLoaded) {
      // Transfers are already filtered to outgoing only by TransferType.outgoing
      final transfers = state.transfers;
      
      if (transfers.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n?.noOutgoingTransfers ?? 'No outgoing transfers',
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
                    child: const Icon(Icons.arrow_upward, color: Colors.green),
                  ),
                  title: Text(transfer.recipientName),
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

  Widget _buildBalanceChip(String currency, String balance, MaterialColor color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.shade100,
        child: Text(
          currency[0],
          style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold),
        ),
      ),
      label: Text(
        balance,
        style: TextStyle(fontWeight: FontWeight.bold, color: color.shade700),
      ),
      backgroundColor: color.shade50,
    );
  }

  Widget _buildIncomingList(BuildContext context, IncomingState state) {
    final l10n = AppLocalizations.of(context);
    
    if (state is IncomingLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (state is IncomingError) {
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
                label: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (state is IncomingLoaded) {
      final incomingList = state.incomingList;
      
      if (incomingList.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n?.incoming ?? 'No incoming records',
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
            itemCount: incomingList.length,
            itemBuilder: (context, index) {
              final incoming = incomingList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.arrow_downward, color: Colors.blue),
                  ),
                  title: Text(incoming.description),
                  subtitle: Text(
                    DateFormatter.toApiDate(incoming.transactionDate),
                  ),
                  trailing: Text(
                    '\$${incoming.amountUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<TransferBloc, TransferState>(
          listener: (context, state) {
            if (state is TransferCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n?.transferCreated ?? 'Transfer created')),
              );
              _reload();
            } else if (state is TransferError && !state.isOffline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<IncomingBloc, IncomingState>(
          listener: (context, state) {
            if (state is IncomingOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              // Reload will be triggered automatically by the bloc
            } else if (state is IncomingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<FundBoxBloc, FundBoxState>(
          listener: (context, state) {
            if (state is FundBoxError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<AdminGroupBloc, AdminGroupState>(
          listener: (context, state) {
            // Group members are loaded when needed for transfer creation
          },
        ),
      ],
      child: WatermarkBackground(
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n?.cash ?? 'Cash'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
                tooltip: l10n?.refresh ?? 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              // Fund Box Display
              BlocBuilder<FundBoxBloc, FundBoxState>(
                builder: (context, state) {
                  if (state is FundBoxLoaded) {
                    final fundBox = state.fundBox;
                    return Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.fundBoxBalance ?? 'Fund Box Balance',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBalanceChip('USD', '\$${fundBox.balanceUsd.toStringAsFixed(2)}', Colors.green),
                                _buildBalanceChip('SYP', NumberFormat('#,###').format(fundBox.balanceSyp), Colors.orange),
                                _buildBalanceChip('TRY', NumberFormat('#,###').format(fundBox.balanceTry), Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Tabs for Outgoing and Incoming
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n?.outgoing ?? 'Outgoing'),
                  Tab(text: l10n?.incoming ?? 'Incoming'),
                ],
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Outgoing Tab
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _createOutgoingTransfer(context),
                              icon: const Icon(Icons.add),
                              label: Text(l10n?.createOutgoingTransfer ?? 'Create Outgoing Transfer'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                        BlocBuilder<TransferBloc, TransferState>(
                          builder: (context, state) => _buildTransfersList(context, state),
                        ),
                      ],
                    ),
                    // Incoming Tab
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _createIncoming(context),
                              icon: const Icon(Icons.add),
                              label: Text(l10n?.addIncoming ?? 'Add Incoming'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                        BlocBuilder<IncomingBloc, IncomingState>(
                          builder: (context, state) => _buildIncomingList(context, state),
                        ),
                      ],
                    ),
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
