import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/services/balance_verification_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin_group/data/models/group_member_dto.dart';
import '../../../superadmin/data/models/admin_member_dto.dart';
import '../../data/models/transfer_dto.dart';

/// Form widget for creating transfers
/// 
/// Supports two modes:
/// - SuperAdmin: Transfer to Admins (USD only)
/// - Admin: Transfer to Users (USD only)
/// 
/// Features:
/// - Recipient selector (filtered by role)
/// - Amount input (USD only)
/// - Transfer date picker
/// - Notes field (optional)
/// - Balance verification before submit
class TransferForm extends StatefulWidget {
  final AppFlavor flavor;
  final List<dynamic> recipients; // List of AdminMemberDto or GroupMemberDto
  final double currentUsdBalance;
  final Function(TransferDto) onSubmit;
  final VoidCallback? onCancel;

  const TransferForm({
    Key? key,
    required this.flavor,
    required this.recipients,
    required this.currentUsdBalance,
    required this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  dynamic _selectedRecipient; // AdminMemberDto or GroupMemberDto
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _balanceError;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getRecipientName(dynamic recipient) {
    if (recipient is AdminMemberDto) {
      return recipient.name;
    } else if (recipient is GroupMemberDto) {
      return recipient.name;
    }
    return '';
  }

  int _getRecipientId(dynamic recipient) {
    if (recipient is AdminMemberDto) {
      return recipient.id;
    } else if (recipient is GroupMemberDto) {
      return recipient.id;
    }
    return 0;
  }

  String _getRecipientEmail(dynamic recipient) {
    if (recipient is AdminMemberDto) {
      return recipient.email;
    } else if (recipient is GroupMemberDto) {
      return recipient.email;
    }
    return '';
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.recipientName ?? 'Please select a recipient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _balanceError = null;
    });

    try {
      // Note: Balance verification is handled by the backend
      // Client-side verification would require injecting FundBoxApiDataSource
      // For now, we rely on backend validation

      // Create transfer DTO
      final transfer = TransferDto(
        recipientUserId: _getRecipientId(_selectedRecipient),
        recipientName: _getRecipientName(_selectedRecipient),
        amountUsd: amount,
        transferDate: DateFormatter.toApiDate(_selectedDate),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Call onSubmit callback
      widget.onSubmit(transfer);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recipient Selector
          DropdownButtonFormField<dynamic>(
            value: _selectedRecipient,
            decoration: InputDecoration(
              labelText: widget.flavor.isSuperAdmin
                  ? (l10n?.adminUser ?? 'Select Admin')
                  : (l10n?.user ?? 'Select User'),
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            items: widget.recipients.map((recipient) {
              return DropdownMenuItem<dynamic>(
                value: recipient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getRecipientName(recipient),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      _getRecipientEmail(recipient),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRecipient = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return l10n?.recipientName ?? 'Recipient is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Amount Input (USD only)
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: l10n?.amountUsd,
              prefixIcon: const Icon(Icons.attach_money),
              suffixText: 'USD',
              border: const OutlineInputBorder(),
              errorText: _balanceError,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.amountUsd ?? 'Amount is required';
              }
              
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return l10n?.invalidAmount ?? 'Invalid amount';
              }
              
              if (amount > widget.currentUsdBalance) {
                return l10n?.amountExceedsBalance ?? 'Amount exceeds balance';
              }
              
              return null;
            },
            onChanged: (value) {
              // Clear balance error when user types
              if (_balanceError != null) {
                setState(() {
                  _balanceError = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Transfer Date Picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n?.transactionDate ?? 'Transfer Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                DateFormatter.toApiDate(_selectedDate),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Field (Optional)
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: '${l10n?.notes} (${l10n?.optional})',
              prefixIcon: const Icon(Icons.note_outlined),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 24),

          // Current Balance Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n?.fundBoxBalance ?? 'Current Balance'}: ',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '\$${widget.currentUsdBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onCancel,
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n?.newTransfer ?? 'Create Transfer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
