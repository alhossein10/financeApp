import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../features/transfers/presentation/bloc/transfer_event.dart';
import '../features/transfers/presentation/bloc/transfer_state.dart';
import '../features/transfers/domain/entities/transfer_type.dart';
import '../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/watermark_background.dart';
import '../core/utils/date_formatter.dart';

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

class _SuperAdminCashPageState extends State<SuperAdminCashPage> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Load user and data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      
      // Load outgoing transfers only (filtered by TransferType.outgoing)
      // Note: SuperAdmin does not have fund-box functionality
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.outgoing),
      );
      
      // Load group members for recipient selection
      context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      // Reload transfers only (no fund-box for SuperAdmin)
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.outgoing),
      );
    }
  }

  Future<void> _createOutgoingTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    // Get admin members from the group
    final adminGroupState = context.read<AdminGroupBloc>().state;
    final adminMembers = adminGroupState.members.where((m) => m.isAdmin).toList();
    
    if (adminMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('no_admin_members_available'))),
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
          title: Text(l10n.translate('create_outgoing_transfer')),
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
                      labelText: l10n.translate('recipient_name'),
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
                      labelText: l10n.translate('amount_usd'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(l10n.translate('transaction_date')),
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
              child: Text(l10n.translate('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('create')),
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
          SnackBar(content: Text(l10n.translate('please_fill_all_fields'))),
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
                label: Text(l10n.translate('retry')),
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
                  l10n.translate('no_outgoing_transfers'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
      
      return Expanded(
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
                SnackBar(content: Text(l10n.translate('transfer_created'))),
              );
              _reload();
            } else if (state is TransferError && !state.isOffline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<AdminGroupBloc, AdminGroupState>(
          listener: (context, state) {
            // Group members are loaded when needed for transfer creation
            // No need to store them in state
          },
        ),
      ],
      child: WatermarkBackground(
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('cash')),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
                tooltip: l10n.translate('refresh'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Create Outgoing Transfer Button
              // Note: SuperAdmin can create transfers without fund-box balance restrictions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SuperAdmin can create transfers without balance restrictions',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Create Outgoing Transfer Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _createOutgoingTransfer(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.translate('create_outgoing_transfer')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              
              // Outgoing Transfers List Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('outgoing_transfers'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              
              BlocBuilder<TransferBloc, TransferState>(
                builder: (context, state) => _buildTransfersList(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
