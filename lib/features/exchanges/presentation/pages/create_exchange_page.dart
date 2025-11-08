import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transfers/domain/entities/transfer.dart';
import '../../../fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../fund_box/presentation/bloc/fund_box_event.dart';
import '../../../fund_box/presentation/bloc/fund_box_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/exchange_bloc.dart';
import '../bloc/exchange_event.dart';
import '../bloc/exchange_state.dart';

class CreateExchangePage extends StatefulWidget {
  final Transfer? transfer; // Optional - for balance-based exchanges

  const CreateExchangePage({Key? key, this.transfer}) : super(key: key);

  @override
  State<CreateExchangePage> createState() => _CreateExchangePageState();
}

class _CreateExchangePageState extends State<CreateExchangePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double? _remainingBalance;
  bool _isLoadingBalance = true;
  String _targetCurrency = 'SYP'; // 'SYP' or 'TRY'
  double? _fundBoxBalanceUsd; // For balance-based exchanges

  @override
  void initState() {
    super.initState();
    if (widget.transfer != null) {
      _loadBalance();
    } else {
      _loadFundBoxBalance();
      _isLoadingBalance = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadBalance() {
    if (widget.transfer != null) {
      context.read<ExchangeBloc>().add(
            LoadTransferBalanceEvent(widget.transfer!.id!),
          );
    }
  }

  void _loadFundBoxBalance() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      context.read<FundBoxBloc>().add(
            LoadFundBox(authState.user!.id),
          );
    }
  }

  double? get _calculatedAmount {
    final amount = double.tryParse(_amountController.text);
    final rate = double.tryParse(_exchangeRateController.text);
    if (amount != null && rate != null) {
      return amount * rate;
    }
    return null;
  }

  double? get _availableBalance {
    if (widget.transfer != null) {
      return _remainingBalance;
    } else {
      return _fundBoxBalanceUsd;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
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

  void _createExchange() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final rate = double.parse(_exchangeRateController.text);

    context.read<ExchangeBloc>().add(
          CreateExchangeEvent(
            transferId: widget.transfer?.id,
            targetCurrency: _targetCurrency,
            amountUsd: amount,
            exchangeRate: rate,
            exchangeDate: _selectedDate,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('create_exchange') ?? 'Create Exchange'),
      ),
      body: BlocConsumer<ExchangeBloc, ExchangeState>(
        listener: (context, state) {
          if (state is TransferBalanceLoaded) {
            setState(() {
              _remainingBalance = state.balance.remainingBalance;
              _isLoadingBalance = false;
            });
          } else if (state is ExchangeCreated) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('exchange_created_success') ?? 'Exchange created successfully!')),
            );
            Navigator.pop(context, state.exchange);
          } else if (state is ExchangeError) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.translate('error') ?? 'Error'}: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          // Listen to FundBoxBloc for balance-based exchanges
          return BlocListener<FundBoxBloc, FundBoxState>(
            listener: (context, fundBoxState) {
              if (fundBoxState is FundBoxLoaded) {
                setState(() {
                  _fundBoxBalanceUsd = fundBoxState.fundBox.balanceUsd;
                });
              }
            },
            child: _isLoadingBalance
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Currency Selection (only for balance-based exchanges)
                          if (widget.transfer == null) ...[
                            DropdownButtonFormField<String>(
                              value: _targetCurrency,
                              decoration: const InputDecoration(
                                labelText: 'Target Currency',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_exchange),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'SYP', child: Text('SYP (Syrian Pounds)')),
                                DropdownMenuItem(value: 'TRY', child: Text('TRY (Turkish Lira)')),
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
                          ],

                  // Amount USD
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (USD)',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount';
                      }
                      final available = _availableBalance;
                      if (available != null && amount > available) {
                        return 'Amount exceeds available balance';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Exchange Rate
                  TextFormField(
                    controller: _exchangeRateController,
                    decoration: InputDecoration(
                      labelText: 'Exchange Rate (1 USD = X $_targetCurrency)',
                      border: const OutlineInputBorder(),
                      helperText: 'Enter today\'s exchange rate',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter exchange rate';
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || rate <= 0) {
                        return 'Please enter valid rate';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),

                  // Calculated Amount Preview
                  if (_calculatedAmount != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context).translate('you_will_receive') ?? 'You will receive:'),
                            Text(
                              '${NumberFormat('#,###.##').format(_calculatedAmount)} $_targetCurrency',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Exchange Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context).translate('exchange_date') ?? 'Exchange Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is ExchangeLoading ? null : _createExchange,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state is ExchangeLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(AppLocalizations.of(context).translate('create_exchange') ?? 'Create Exchange'),
                    ),
                  ),
                ],
              ),
            ),
                  ),
          );
        },
      ),
    );
  }
}
