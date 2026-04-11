import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../exchanges/presentation/widgets/exchange_form.dart';
import '../../../exchanges/presentation/bloc/exchange_bloc.dart';
import '../../../exchanges/presentation/bloc/exchange_event.dart';
import '../../../exchanges/presentation/bloc/exchange_state.dart';
import '../../../fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../fund_box/presentation/bloc/fund_box_event.dart';
import '../../../fund_box/presentation/bloc/fund_box_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../exchanges/presentation/pages/exchange_history_page.dart';
import '../../../../core/widgets/watermark_background.dart';

/// Admin Exchange Page
/// 
/// Features:
/// - Display ExchangeForm for creating exchanges
/// - "Exchange Log" button to view exchange history
/// - Implement exchange creation with balance update
/// - Balance verification before submission
class AdminExchangePage extends StatefulWidget {
  const AdminExchangePage({super.key});

  @override
  State<AdminExchangePage> createState() => _AdminExchangePageState();
}

class _AdminExchangePageState extends State<AdminExchangePage> {
  double _currentUsdBalance = 0.0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadFundBoxBalance();
  }

  void _loadFundBoxBalance() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      context.read<FundBoxBloc>().add(
            LoadFundBox(authState.user!.id),
          );
    }
  }

  void _handleExchangeSubmit(ExchangeFormData formData) {
    context.read<ExchangeBloc>().add(
          CreateExchangeEvent(
            targetCurrency: formData.targetCurrency,
            amountUsd: formData.amountUsd,
            exchangeRate: formData.exchangeRate,
            convertedAmount: formData.convertedAmount,
            exchangeDate: formData.exchangeDate,
            notes: formData.notes,
          ),
        );
  }

  void _navigateToExchangeLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExchangeHistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('currency_exchange')),
        actions: [
          // Exchange Log Button
          TextButton.icon(
            onPressed: _navigateToExchangeLog,
            icon: const Icon(Icons.history, color: Colors.white),
            label: Text(
              l10n.translate('exchange_log'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: WatermarkBackground(
        child: BlocListener<FundBoxBloc, FundBoxState>(
          listener: (context, fundBoxState) {
            if (fundBoxState is FundBoxLoaded) {
              setState(() {
                _currentUsdBalance = fundBoxState.fundBox.balanceUsd;
                _isLoadingBalance = false;
              });
            } else if (fundBoxState is FundBoxError) {
              setState(() {
                _isLoadingBalance = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l10n.translate('error_loading_balance')}: ${fundBoxState.message}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocConsumer<ExchangeBloc, ExchangeState>(
            listener: (context, exchangeState) {
              if (exchangeState is ExchangeCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.translate('exchange_created_success'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Reload fund box balance after successful exchange
                _loadFundBoxBalance();
                
                // Navigate to exchange log to see the new exchange
                _navigateToExchangeLog();
              } else if (exchangeState is ExchangeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.translate('error')}: ${exchangeState.message}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, exchangeState) {
              if (_isLoadingBalance) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title and Description
                    Text(
                      l10n.translate('create_exchange'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('exchange_description'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Exchange Form
                    ExchangeForm(
                      currentUsdBalance: _currentUsdBalance,
                      onSubmit: _handleExchangeSubmit,
                      isLoading: exchangeState is ExchangeLoading,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
