import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/multi_currency_balance_card.dart';
import '../../../../core/widgets/watermark_background.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../../../../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../../../../features/incoming/presentation/bloc/incoming_event.dart';
import '../../../../features/incoming/presentation/bloc/incoming_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';

/// Superadmin Financial Box Page
/// 
/// Displays multi-currency balance card and allows manually adding incoming amounts
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5
class SuperadminFinancialBoxPage extends StatefulWidget {
  const SuperadminFinancialBoxPage({super.key});

  @override
  State<SuperadminFinancialBoxPage> createState() => _SuperadminFinancialBoxPageState();
}

class _SuperadminFinancialBoxPageState extends State<SuperadminFinancialBoxPage> {
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
      
      // Load fund box for Superadmin
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      
      // Load incoming records
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      // Reload all data
      context.read<FundBoxBloc>().add(RefreshFundBox(_currentUserId!));
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }

  Future<void> _addIncomingAmount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.translate('add_incoming') ?? 'Add Incoming'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('description') ?? 'Description',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.translate('amount_usd') ?? 'Amount (USD)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.translate('transaction_date') ?? 'Transaction Date'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('cancel') ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.translate('add') ?? 'Add'),
            ),
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
            SnackBar(
              content: Text(l10n.translate('please_fill_all_fields') ?? 'Please fill all fields'),
            ),
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
                label: Text(l10n.translate('retry') ?? 'Retry'),
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
                  l10n.translate('no_incoming') ?? 'No incoming records',
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
        BlocListener<IncomingBloc, IncomingState>(
          listener: (context, state) {
            if (state is IncomingOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              _reload();
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
      ],
      child: WatermarkBackground(
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('cash') ?? 'Cash'),
            actions: [
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
              
              // Add Incoming Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addIncomingAmount(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.translate('add_incoming') ?? 'Add Incoming'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              
              // Incoming List
              BlocBuilder<IncomingBloc, IncomingState>(
                builder: (context, state) => _buildIncomingList(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
