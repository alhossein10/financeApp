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
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';

/// User Financial Box Page (Home)
/// 
/// Displays multi-currency balance card and incoming transfers from Admin
/// Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6
class UserFinancialBoxPage extends StatefulWidget {
  const UserFinancialBoxPage({super.key});

  @override
  State<UserFinancialBoxPage> createState() => _UserFinancialBoxPageState();
}

class _UserFinancialBoxPageState extends State<UserFinancialBoxPage> {
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
      
      // Load fund box for User
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      
      // Load incoming transfers (from Admin)
      context.read<TransferBloc>().add(
        LoadTransfersEvent(_currentUserId!, type: TransferType.incoming),
      );
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

  Widget _buildIncomingTransfersList(BuildContext context, TransferState state) {
    final l10n = AppLocalizations.of(context)!;
    
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
                  l10n.translate('no_transfers_received'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('transfers_from_admin_appear_here'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.translate('incoming_transfers'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
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
                        title: Text(
                          l10n.translate('from_admin'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.toApiDate(transfer.transactionDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (transfer.recipientName.isNotEmpty)
                              Text(
                                transfer.recipientName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${transfer.amountUsd.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'USD',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const Expanded(child: SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
            title: Text(l10n.translate('home')),
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
              
              // Incoming Transfers List
              BlocBuilder<TransferBloc, TransferState>(
                builder: (context, state) => _buildIncomingTransfersList(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
