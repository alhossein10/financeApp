import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/balance_verification_service.dart';

/// Reusable Exchange Form Widget
/// 
/// Features:
/// - Target currency selector (SYP or TRY)
/// - USD amount input
/// - Exchange rate OR converted amount input (auto-calculates the other)
/// - Exchange date picker
/// - Notes field
/// - Balance verification before submission
class ExchangeForm extends StatefulWidget {
  final double currentUsdBalance;
  final Function(ExchangeFormData) onSubmit;
  final bool isLoading;

  const ExchangeForm({
    super.key,
    required this.currentUsdBalance,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends State<ExchangeForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _convertedAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _targetCurrency = 'SYP';
  DateTime _selectedDate = DateTime.now();
  bool _isCalculatingFromRate = true; // true = user enters rate, false = user enters converted amount

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _convertedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateConvertedAmount() {
    final amount = double.tryParse(_amountController.text);
    final rate = double.tryParse(_exchangeRateController.text);
    
    if (amount != null && rate != null && rate > 0) {
      final converted = amount * rate;
      _convertedAmountController.text = converted.toStringAsFixed(2);
    } else {
      _convertedAmountController.text = '';
    }
  }

  void _calculateExchangeRate() {
    final amount = double.tryParse(_amountController.text);
    final converted = double.tryParse(_convertedAmountController.text);
    
    if (amount != null && amount > 0 && converted != null && converted > 0) {
      final rate = converted / amount;
      _exchangeRateController.text = rate.toStringAsFixed(4);
    } else {
      _exchangeRateController.text = '';
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final rate = double.tryParse(_exchangeRateController.text);
    final converted = double.tryParse(_convertedAmountController.text);

    // Validate that at least one of rate or converted amount is provided
    if (rate == null && converted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('enter_rate_or_amount'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verify balance
    try {
      final hasBalance = await BalanceVerificationService.verifyBalance(
        currency: 'USD',
        amount: amount,
        currentBalance: widget.currentUsdBalance,
      );

      if (!hasBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('insufficient_usd_balance'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Submit the form
      widget.onSubmit(ExchangeFormData(
        targetCurrency: _targetCurrency,
        amountUsd: amount,
        exchangeRate: rate,
        convertedAmount: converted,
        exchangeDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Balance Display
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('available_balance'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${NumberFormat('#,###.##').format(widget.currentUsdBalance)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Currency Selector
          DropdownButtonFormField<String>(
            value: _targetCurrency,
            decoration: InputDecoration(
              labelText: l10n.translate('target_currency'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_exchange),
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

          // Amount USD Input
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: l10n.translate('amount_usd'),
              border: const OutlineInputBorder(),
              prefixText: '\$ ',
              helperText: l10n.translate('enter_usd_amount'),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.translate('amount_required');
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return l10n.translate('invalid_amount');
              }
              if (amount > widget.currentUsdBalance) {
                return l10n.translate('exceeds_balance');
              }
              return null;
            },
            onChanged: (value) {
              if (_isCalculatingFromRate) {
                _calculateConvertedAmount();
              } else {
                _calculateExchangeRate();
              }
            },
          ),
          const SizedBox(height: 16),

          // Exchange Rate OR Converted Amount Toggle
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(l10n.translate('enter_rate')),
                  value: true,
                  groupValue: _isCalculatingFromRate,
                  onChanged: (value) {
                    setState(() {
                      _isCalculatingFromRate = value!;
                      if (_isCalculatingFromRate) {
                        _convertedAmountController.clear();
                        _calculateConvertedAmount();
                      } else {
                        _exchangeRateController.clear();
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(l10n.translate('enter_amount')),
                  value: false,
                  groupValue: _isCalculatingFromRate,
                  onChanged: (value) {
                    setState(() {
                      _isCalculatingFromRate = value!;
                      if (_isCalculatingFromRate) {
                        _convertedAmountController.clear();
                        _calculateConvertedAmount();
                      } else {
                        _exchangeRateController.clear();
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Exchange Rate Input (when calculating from rate)
          if (_isCalculatingFromRate) ...[
            TextFormField(
              controller: _exchangeRateController,
              decoration: InputDecoration(
                labelText: l10n.translate('exchange_rate'),
                border: const OutlineInputBorder(),
                helperText: '1 USD = X $_targetCurrency',
                suffixText: _targetCurrency,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
              ],
              validator: (value) {
                if (_isCalculatingFromRate && (value == null || value.isEmpty)) {
                  return l10n.translate('rate_required');
                }
                if (value != null && value.isNotEmpty) {
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return l10n.translate('invalid_rate');
                  }
                }
                return null;
              },
              onChanged: (value) => _calculateConvertedAmount(),
            ),
            const SizedBox(height: 8),
            
            // Calculated Converted Amount Display
            if (_convertedAmountController.text.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.translate('you_will_receive')),
                      Text(
                        '${NumberFormat('#,###.##').format(double.tryParse(_convertedAmountController.text) ?? 0)} $_targetCurrency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          // Converted Amount Input (when calculating from amount)
          if (!_isCalculatingFromRate) ...[
            TextFormField(
              controller: _convertedAmountController,
              decoration: InputDecoration(
                labelText: l10n.translate('converted_amount'),
                border: const OutlineInputBorder(),
                helperText: l10n.translate('enter_target_amount'),
                suffixText: _targetCurrency,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (!_isCalculatingFromRate && (value == null || value.isEmpty)) {
                  return l10n.translate('amount_required');
                }
                if (value != null && value.isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return l10n.translate('invalid_amount');
                  }
                }
                return null;
              },
              onChanged: (value) => _calculateExchangeRate(),
            ),
            const SizedBox(height: 8),
            
            // Calculated Exchange Rate Display
            if (_exchangeRateController.text.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.translate('calculated_rate')),
                      Text(
                        '1 USD = ${NumberFormat('#,###.####').format(double.tryParse(_exchangeRateController.text) ?? 0)} $_targetCurrency',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),

          // Exchange Date Picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.translate('exchange_date')),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Input
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.translate('notes_optional'),
              border: const OutlineInputBorder(),
              hintText: l10n.translate('add_notes'),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.translate('create_exchange'),
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for exchange form submission
class ExchangeFormData {
  final String targetCurrency;
  final double amountUsd;
  final double? exchangeRate;
  final double? convertedAmount;
  final DateTime exchangeDate;
  final String? notes;

  ExchangeFormData({
    required this.targetCurrency,
    required this.amountUsd,
    this.exchangeRate,
    this.convertedAmount,
    required this.exchangeDate,
    this.notes,
  });
}
