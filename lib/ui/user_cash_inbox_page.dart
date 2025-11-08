import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/db.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../features/transfers/presentation/bloc/transfer_event.dart';
import '../features/transfers/presentation/bloc/transfer_state.dart';
import '../l10n/app_localizations.dart';
import '../models/exchange_record.dart';
import '../models/transfer.dart';
import '../core/config/flavor_config.dart';
import '../core/widgets/watermark_background.dart';

/// User Cash Inbox Page - Shows fundbox balances and incoming transfers from admin
/// Rebuilt from admin cash_inbox_page.dart with same mechanisms but restricted features
/// Single view page (no tabs) showing only incoming transfers without filtering or exporting
class UserCashInboxPage extends StatefulWidget {
  const UserCashInboxPage({super.key});

  @override
  State<UserCashInboxPage> createState() => _UserCashInboxPageState();
}

class _UserCashInboxPageState extends State<UserCashInboxPage> {
  final AppDatabase _db = AppDatabase();
  
  int? _currentUserId;

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
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      // For user flavor, use calculated balance from API (real-time)
      context.read<FundBoxBloc>().add(const LoadCalculatedBalance());
      context.read<TransferBloc>().add(LoadTransfersEvent(_currentUserId!));
    }
  }
  
  Future<void> _handleRefresh() async {
    if (_currentUserId != null) {
      // Refresh both fundbox (calculated balance) and transfers
      context.read<FundBoxBloc>().add(const LoadCalculatedBalance());
      context.read<TransferBloc>().add(LoadTransfersEvent(_currentUserId!));
    }
  }


  /// Get incoming transfers - transfers TO this user from admin
  /// For users, incoming transfers are those where recipientUserId matches current user
  List<TransferRecord> _getIncomingTransfers(List<TransferRecord> transfers) {
    if (_currentUserId == null) {
      return [];
    }
    
    // Show transfers where recipientUserId matches current user (transfers TO this user from admin)
    return transfers.where((t) => t.recipientUserId == _currentUserId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<TransferBloc, TransferState>(
          listener: (context, state) {
            if (state is TransferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is TransferLoaded) {
              // When transfers are loaded/updated, refresh calculated balance
              print('[UserCashInboxPage] Transfers loaded - refreshing calculated balance');
              context.read<FundBoxBloc>().add(const LoadCalculatedBalance());
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              // Fund Box Cards - Use API calculated balance (real-time)
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  // Show for user flavor
                  if (!FlavorConfig.instance.isUser) {
                    return const SizedBox.shrink();
                  }
                  
                  return SizedBox(
                    height: 200,
                    child: BlocBuilder<FundBoxBloc, FundBoxState>(
                      builder: (context, fundBoxState) {
                        if (fundBoxState is FundBoxLoading) {
                          return const Card(
                            margin: EdgeInsets.all(16),
                            child: ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Loading fund box...'),
                            ),
                          );
                        }
                        
                        if (fundBoxState is FundBoxError) {
                          return Card(
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              leading: const Icon(Icons.error, color: Colors.red),
                              title: const Text('Error loading fund box'),
                              subtitle: Text(fundBoxState.message),
                              trailing: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _handleRefresh,
                              ),
                            ),
                          );
                        }
                        
                        if (fundBoxState is FundBoxLoaded) {
                          final fundBox = fundBoxState.fundBox;
                          print('[UserCashInboxPage] Displaying calculated balance: USD=${fundBox.balanceUsd}, SYP=${fundBox.balanceSyp}, TRY=${fundBox.balanceTry}');
                          
                          return PageView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // USD Card
                              _buildCurrencyCard(
                                context: context,
                                currency: 'USD',
                                icon: Icons.attach_money,
                                color: Colors.green,
                                balance: fundBox.balanceUsd,
                                symbol: '\$',
                              ),
                              // SYP Card
                              _buildCurrencyCard(
                                context: context,
                                currency: 'SYP',
                                icon: Icons.currency_pound,
                                color: Colors.orange,
                                balance: fundBox.balanceSyp,
                                symbol: '',
                              ),
                              // TRY Card
                              _buildCurrencyCard(
                                context: context,
                                currency: 'TRY',
                                icon: Icons.currency_lira,
                                color: Colors.blue,
                                balance: fundBox.balanceTry,
                                symbol: '',
                              ),
                            ],
                          );
                        }
                        
                        // Initial state or updating state - show loading
                        return const Card(
                          margin: EdgeInsets.all(16),
                          child: ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Loading fund box...'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              
              // Incoming Transfers List (single view, no tabs, no export button, no filtering)
              Expanded(
                child: BlocBuilder<TransferBloc, TransferState>(
                builder: (context, state) {
                  if (state is TransferLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is TransferLoaded) {
                    final transfers = state.transfers.map((t) => TransferRecord(
                      id: t.id,
                      recipientName: t.recipientName,
                      amountUsd: t.amountUsd,
                      convertedAmountUsd: t.convertedAmountUsd,
                      amountSypAtExchange: t.amountSypAtExchange,
                      manualUsdToSypRate: t.manualUsdToSypRate,
                      transactionDate: t.transactionDate,
                      createdAt: t.createdAt,
                      userId: t.userId,
                      recipientUserId: t.recipientUserId,
                    )).toList();
                    
                    // Get only incoming transfers from admin (no filtering, just get user's transfers)
                    final incomingTransfers = _getIncomingTransfers(transfers);
                    
                    if (incomingTransfers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              l10n.translate('no_transfers') ?? 'No incoming transfers',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: incomingTransfers.length,
                      itemBuilder: (context, index) {
                        final t = incomingTransfers[index];
                        
                        if (t.id == null) {
                          return const SizedBox.shrink();
                        }
                        
                        return FutureBuilder<List<ExchangeRecord>>(
                          future: _db.listExchangesByTransfer(t.id!),
                          builder: (context, exchangeSnapshot) {
                            // Calculate total exchanged amount (initial + all additional exchanges)
                            // Same mechanism as admin version
                            final initialConverted = t.convertedAmountUsd ?? 0.0;
                            final additionalExchanges = exchangeSnapshot.data ?? [];
                            final totalExchanged = initialConverted + 
                              additionalExchanges.fold(0.0, (sum, e) => sum + e.convertedAmountUsd);
                            
                            final actualUsdRemaining = t.amountUsd - totalExchanged;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.call_received, color: Colors.green),
                                title: Text(
                                  '${t.amountUsd.toStringAsFixed(2)} ${l10n.translate('usd')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${l10n.translate('date') ?? 'Date'}: ${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: Text(
                                  'Remaining: ${actualUsdRemaining.toStringAsFixed(2)} USD',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  
                  return Center(
                    child: Text(l10n.translate('no_transfers') ?? 'No transfers found'),
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard({
    required BuildContext context,
    required String currency,
    required IconData icon,
    required Color color,
    required double balance,
    required String symbol,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    currency,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$symbol${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (symbol.isEmpty)
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}