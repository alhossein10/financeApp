import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../features/incoming/presentation/bloc/incoming_event.dart';
import '../features/incoming/presentation/bloc/incoming_state.dart';
import '../l10n/app_localizations.dart';
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
      // Load incoming income from admin using IncomingBloc
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }
  
  Future<void> _handleRefresh() async {
    if (_currentUserId != null) {
      // Refresh both fundbox (calculated balance) and incoming income
      context.read<FundBoxBloc>().add(const LoadCalculatedBalance());
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<IncomingBloc, IncomingState>(
          listener: (context, state) {
            if (state is IncomingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is IncomingLoaded) {
              // When incoming income is loaded/updated, refresh calculated balance
              print('[UserCashInboxPage] Incoming income loaded - refreshing calculated balance');
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
              
              // Incoming Income List (from admin via /incoming API)
              Expanded(
                child: BlocBuilder<IncomingBloc, IncomingState>(
                  builder: (context, state) {
                    if (state is IncomingLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (state is IncomingError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleRefresh,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n?.retry ?? 'Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (state is IncomingLoaded) {
                      final incomingList = state.incomingList;
                      
                      if (incomingList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                l10n?.incoming ?? 'No income from admin',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: incomingList.length,
                        itemBuilder: (context, index) {
                          final incoming = incomingList[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.call_received, color: Colors.green),
                              title: Text(
                                '${incoming.amountUsd.toStringAsFixed(2)} ${l10n?.usd ?? 'USD'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (incoming.description.isNotEmpty)
                                    Text(
                                      incoming.description,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n?.date ?? 'Date'}: ${incoming.transactionDate.day}/${incoming.transactionDate.month}/${incoming.transactionDate.year}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                    
                    return Center(
                      child: Text(l10n?.incoming ?? 'No income found'),
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