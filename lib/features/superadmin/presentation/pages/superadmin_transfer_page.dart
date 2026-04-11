import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/fund_box/data/datasources/fund_box_api_datasource.dart';
import '../../../../features/fund_box/data/models/fund_box_dto.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_event.dart';
import '../../../../features/fund_box/presentation/bloc/fund_box_state.dart';
import '../../../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../../../features/transfers/presentation/bloc/transfer_event.dart';
import '../../../../features/transfers/presentation/bloc/transfer_state.dart';
import '../../../../features/transfers/presentation/widgets/transfer_form.dart';
import '../../../../features/transfers/data/models/transfer_dto.dart';
import '../../../../injection_container.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../superadmin/data/datasources/superadmin_group_api_datasource.dart';
import '../../../superadmin/data/models/admin_member_dto.dart';

/// SuperAdmin Transfer Page
/// 
/// Features:
/// - Display outgoing transfers to Admins
/// - Create new transfer button
/// - Filter by recipient Admin
/// - Filter by date range
/// - Export to PDF button
/// - Apply filters to export
class SuperAdminTransferPage extends StatefulWidget {
  const SuperAdminTransferPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminTransferPage> createState() => _SuperAdminTransferPageState();
}

class _SuperAdminTransferPageState extends State<SuperAdminTransferPage> {
  List<AdminMemberDto> _adminMembers = [];
  bool _isLoadingMembers = true;
  String? _errorMessage;
  
  // Form state
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  AdminMemberDto? _selectedAdmin;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingBalance = false;
  double? _currentBalance;
  
  // Filters
  int? _selectedRecipientId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAdminMembers();
    _loadTransfers();
    _loadFundBox();
  }

  Future<void> _loadFundBox() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null && mounted) {
      final userId = authState.user!.id;
      context.read<FundBoxBloc>().add(LoadFundBox(userId));
    }
  }

  Future<void> _loadTransfers() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null && mounted) {
      final userId = authState.user!.id;
      context.read<TransferBloc>().add(
        LoadTransfersEvent(userId),
      );
    }
  }

  void _refreshTransfers() {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    _loadTransfers();
  }

  Future<void> _loadAdminMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _errorMessage = null;
    });

    try {
      final datasource = sl<SuperAdminGroupApiDatasource>();
      final response = await datasource.getMembers(perPage: 100);
      
      setState(() {
        _adminMembers = response.data;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admin members: ${e.toString()}';
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadAdminBalance(int adminId) async {
    setState(() {
      _isLoadingBalance = true;
      _currentBalance = null;
    });

    try {
      final datasource = sl<FundBoxApiDataSource>();
      final fundBox = await datasource.getFundBoxByUserId(adminId);
      
      setState(() {
        _currentBalance = fundBox.balanceUsd;
        _isLoadingBalance = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBalance = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load admin balance: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
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

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an admin recipient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${_selectedAdmin!.name}'),
            Text('Email: ${_selectedAdmin!.email}'),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${amount.toStringAsFixed(2)} USD',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: ${DateFormatter.toApiDate(_selectedDate)}'),
            if (_notesController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${_notesController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitTransfer();
    }
  }

  Future<void> _submitTransfer() async {
    final amount = double.parse(_amountController.text);
    final authState = context.read<AuthBloc>().state;
    
    if (authState is! AuthAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authState.user!.id;

    context.read<TransferBloc>().add(
      CreateTransferEvent(
        userId: userId,
        recipientName: _selectedAdmin!.name,
        recipientUserId: _selectedAdmin!.id,
        adminGroupId: _selectedAdmin!.adminGroupId,
        amountUsd: amount,
        transactionDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer to Admin'),
        elevation: 0,
      ),
      body: BlocListener<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isPending
                      ? 'Transfer queued (offline)'
                      : 'Transfer created successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is TransferError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: BlocBuilder<TransferBloc, TransferState>(
          builder: (context, state) {
            final isLoading = state is TransferLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Admin selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Admin Recipient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoadingMembers)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_adminMembers.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No admin members found in your group',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              DropdownButtonFormField<AdminMemberDto>(
                                value: _selectedAdmin,
                                decoration: const InputDecoration(
                                  labelText: 'Admin',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: _adminMembers.map((admin) {
                                  return DropdownMenuItem(
                                    value: admin,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          admin.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          admin.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedAdmin = value;
                                        });
                                        if (value != null) {
                                          _loadAdminBalance(value.id);
                                        }
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an admin';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Admin current balance
                    if (_selectedAdmin != null)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Balance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_isLoadingBalance)
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    else if (_currentBalance != null)
                                      Text(
                                        '\$${_currentBalance!.toStringAsFixed(2)} USD',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Unable to load balance',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Amount input
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transfer Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount (USD)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                suffixText: 'USD',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              enabled: !isLoading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transfer Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: isLoading ? null : _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormatter.toApiDate(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                                hintText: 'Add any notes about this transfer',
                              ),
                              maxLines: 3,
                              enabled: !isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: isLoading ? null : _showConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Transfer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
