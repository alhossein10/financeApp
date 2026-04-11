import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../fund_box/presentation/bloc/fund_box_event.dart';
import '../../../fund_box/presentation/bloc/fund_box_state.dart';
import '../bloc/exchange_bloc.dart';
import '../bloc/exchange_event.dart';
import '../bloc/exchange_state.dart';
import '../../../../core/widgets/watermark_background.dart';
import 'exchange_history_page.dart';
import '../widgets/exchange_form.dart';

/// User Exchange Page - Create exchanges based on total USD balance
/// Shows total USD balance and allows creating exchanges
class UserExchangePage extends StatefulWidget {
  const UserExchangePage({super.key});

  @override
  State<UserExchangePage> createState() => _UserExchangePageState();
}

class _UserExchangePageState extends State<UserExchangePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _convertedAmountController = TextEditingController(); // Changed from exchangeRateController
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _targetCurrency = 'SYP'; // Default to SYP
  bool _showBalanceCard = true;
  static const String _balanceCardVisibleKey = 'exchange_balance_card_visible';

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadBalanceCardPreference();
  }

  Future<void> _loadBalanceCardPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showBalanceCard = prefs.getBool(_balanceCardVisibleKey) ?? true;
    });
  }

  Future<void> _toggleBalanceCard() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_showBalanceCard;
    await prefs.setBool(_balanceCardVisibleKey, newValue);
    setState(() {
      _showBalanceCard = newValue;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _convertedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadBalance() {
    // Get current user ID from auth state
    // Use WidgetsBinding to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;
      
      if (userId != null && mounted) {
        context.read<FundBoxBloc>().add(LoadFundBox(userId));
      }
    });
  }

  void _createExchange() {
    if (_formKey.currentState?.validate() ?? false) {
      final amountUsd = double.tryParse(_amountController.text) ?? 0.0;
      final convertedAmount = double.tryParse(_convertedAmountController.text) ?? 0.0;

      // Validate amount
      if (amountUsd <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('invalid_amount'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get current fund box balance
      final fundBoxState = context.read<FundBoxBloc>().state;
      double maxUsdBalance = 0.0;
      if (fundBoxState is FundBoxLoaded) {
        maxUsdBalance = fundBoxState.fundBox.balanceUsd;
      }

      // Validate amount doesn't exceed fund box balance
      if (amountUsd > maxUsdBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.translate('amount_exceeds_balance')} \$${maxUsdBalance.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create exchange without transferId (balance-based)
      // Send converted_amount directly instead of exchange_rate (Backend v3.1+)
      context.read<ExchangeBloc>().add(
        CreateExchangeEvent(
          transferId: null, // No transfer - balance-based exchange
          targetCurrency: _targetCurrency,
          amountUsd: amountUsd,
          exchangeRate: null, // Not needed when convertedAmount is provided
          convertedAmount: convertedAmount, // Send converted amount directly
          exchangeDate: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('create_exchange')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.translate('exchange_history'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
                    child: BlocProvider.value(
                      value: context.read<ExchangeBloc>(),
                      child: const ExchangeHistoryPage(),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBalance();
            },
          ),
        ],
      ),
      body: WatermarkBackground(
        child: BlocListener<ExchangeBloc, ExchangeState>(
            listener: (context, state) {
              if (state is ExchangeCreated) {
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('exchange_created_success')),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Clear form
                _amountController.clear();
                _convertedAmountController.clear();
                _notesController.clear();
                _selectedDate = DateTime.now();
                
                // Reload balance to get updated fundbox balance after exchange
                _loadBalance();
                
                // Reset exchange state
                context.read<ExchangeBloc>().add(const ResetExchangeStateEvent());
              } else if (state is ExchangeError) {
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.translate('error')}: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Information Card (can be hidden)
              BlocBuilder<FundBoxBloc, FundBoxState>(
                builder: (context, fundBoxState) {
                  if (!_showBalanceCard) return const SizedBox.shrink();
                  
                  if (fundBoxState is FundBoxLoaded) {
                    final fundBox = fundBoxState.fundBox;
                    return Card(
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: _toggleBalanceCard,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.translate('available_balance'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: _toggleBalanceCard,
                                    tooltip: l10n.translate('hide'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'USD:',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '\$${fundBox.balanceUsd.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (fundBox.balanceSyp > 0 || fundBox.balanceTry > 0) ...[
                                const SizedBox(height: 4),
                                if (fundBox.balanceSyp > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'SYP:',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${NumberFormat('#,###.##').format(fundBox.balanceSyp)} SYP',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (fundBox.balanceTry > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TRY:',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${NumberFormat('#,###.##').format(fundBox.balanceTry)} TRY',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Exchange Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('exchange_details'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        // Target Currency Selection
                        DropdownButtonFormField<String>(
                          initialValue: _targetCurrency,
                          decoration: InputDecoration(
                            labelText: l10n.translate('target_currency'),
                            prefixIcon: const Icon(Icons.currency_exchange),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'SYP',
                              child: Text('SYP (Syrian Pounds)'),
                            ),
                            DropdownMenuItem(
                              value: 'TRY',
                              child: Text('TRY (Turkish Lira)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _targetCurrency = value;
                              });
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Amount USD
                        BlocBuilder<FundBoxBloc, FundBoxState>(
                          builder: (context, fundBoxState) {
                            double maxUsdBalance = 0.0;
                            // Use fundbox balance directly - do not recalculate from exchanges
                            if (fundBoxState is FundBoxLoaded) {
                              maxUsdBalance = fundBoxState.fundBox.balanceUsd;
                            }
                            return TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: l10n.translate('amount_usd'),
                                prefixIcon: const Icon(Icons.attach_money),
                                border: const OutlineInputBorder(),
                                helperText: maxUsdBalance > 0
                                    ? '${l10n.translate('max')}: \$${maxUsdBalance.toStringAsFixed(2)}'
                                    : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.translate('please_enter_amount');
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return l10n.translate('invalid_amount');
                                }
                                if (maxUsdBalance > 0 && amount > maxUsdBalance) {
                                  return '${l10n.translate('amount_exceeds_balance')} (\$${maxUsdBalance.toStringAsFixed(2)})';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Converted Amount (المبلغ المصرف)
                        TextFormField(
                          controller: _convertedAmountController,
                          decoration: InputDecoration(
                            labelText: _targetCurrency == 'SYP'
                                ? l10n.translate('amount_syp')
                                : l10n.translate('amount_try'),
                            prefixIcon: const Icon(Icons.currency_exchange),
                            border: const OutlineInputBorder(),
                            helperText: _targetCurrency == 'SYP' 
                                ? 'أدخل المبلغ بالليرة السورية'
                                : 'أدخل المبلغ بالليرة التركية',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _targetCurrency == 'SYP'
                                  ? 'يرجى إدخال المبلغ بالليرة السورية'
                                  : 'يرجى إدخال المبلغ بالليرة التركية';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'المبلغ غير صحيح';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Update UI to show calculated exchange rate
                            setState(() {});
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Calculated Exchange Rate (display only)
                        if (_amountController.text.isNotEmpty && 
                            _convertedAmountController.text.isNotEmpty &&
                            double.tryParse(_amountController.text) != null &&
                            double.tryParse(_amountController.text)! > 0 &&
                            double.tryParse(_convertedAmountController.text) != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.translate('exchange_rate'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '1 USD = ${NumberFormat('#,###.##').format(
                                    (double.tryParse(_convertedAmountController.text) ?? 0) /
                                    (double.tryParse(_amountController.text) ?? 1)
                                  )} $_targetCurrency',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        if (_amountController.text.isNotEmpty && 
                            _convertedAmountController.text.isNotEmpty)
                          const SizedBox(height: 16),
                        
                        // Exchange Date
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.translate('exchange_date'),
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: const OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: l10n.translate('notes'),
                            prefixIcon: const Icon(Icons.note),
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        BlocBuilder<ExchangeBloc, ExchangeState>(
                          builder: (context, state) {
                            final isLoading = state is ExchangeLoading;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _createExchange,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        l10n.translate('create_exchange'),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
