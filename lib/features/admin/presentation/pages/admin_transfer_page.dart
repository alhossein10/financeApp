import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/admin_group/data/datasources/admin_group_api_datasource.dart';
import '../../../../features/admin_group/data/models/group_member_dto.dart';
import '../../../../features/fund_box/data/datasources/fund_box_api_datasource.dart';
import '../../../../features/fund_box/data/models/fund_box_dto.dart';
import '../../../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../../../features/transfers/presentation/bloc/transfer_event.dart';
import '../../../../features/transfers/presentation/bloc/transfer_state.dart';
import '../../../../injection_container.dart';

/// Admin Transfer Page
/// Allows Admin to transfer funds to users in their group
class AdminTransferPage extends StatefulWidget {
  const AdminTransferPage({Key? key}) : super(key: key);

  @override
  State<AdminTransferPage> createState() => _AdminTransferPageState();
}

class _AdminTransferPageState extends State<AdminTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  GroupMemberDto? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  List<GroupMemberDto> _groupMembers = [];
  bool _isLoadingMembers = true;
  bool _isLoadingBalance = false;
  bool _isLoadingAdminBalance = false;
  double? _userBalance;
  double? _adminBalance;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _loadAdminBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _errorMessage = null;
    });

    try {
      final datasource = sl<AdminGroupApiDataSource>();
      final response = await datasource.getGroupMembers(perPage: 100);
      
      // Filter to only show regular users (not admins)
      final users = response.data.where((member) => member.role == 'user').toList();
      
      setState(() {
        _groupMembers = users;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load group members: ${e.toString()}';
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadAdminBalance() async {
    setState(() {
      _isLoadingAdminBalance = true;
    });

    try {
      final datasource = sl<FundBoxApiDataSource>();
      final fundBox = await datasource.getFundBox();
      
      setState(() {
        _adminBalance = fundBox.balanceUsd;
        _isLoadingAdminBalance = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAdminBalance = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load your balance: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadUserBalance(int userId) async {
    setState(() {
      _isLoadingBalance = true;
      _userBalance = null;
    });

    try {
      final datasource = sl<FundBoxApiDataSource>();
      final fundBox = await datasource.getFundBoxByUserId(userId);
      
      setState(() {
        _userBalance = fundBox.balanceUsd;
        _isLoadingBalance = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBalance = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user balance: ${e.toString()}'),
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

    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user recipient'),
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

    // Check sufficient balance
    if (_adminBalance != null && amount > _adminBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient funds. Your balance: \$${_adminBalance!.toStringAsFixed(2)} USD'),
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
            Text('Recipient: ${_selectedUser!.name}'),
            Text('Email: ${_selectedUser!.email}'),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${amount.toStringAsFixed(2)} USD',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('Date: ${DateFormatter.formatDate(_selectedDate)}'),
            if (_notesController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${_notesController.text}'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your balance after transfer:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '\$${(_adminBalance! - amount).toStringAsFixed(2)} USD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
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
    final tokenManager = sl<TokenManager>();
    final userId = await tokenManager.getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TransferBloc>().add(
      CreateTransferEvent(
        userId: userId,
        recipientName: _selectedUser!.name,
        recipientUserId: _selectedUser!.id,
        amountUsd: amount,
        transactionDate: _selectedDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer to User'),
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

                    // Admin balance
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_isLoadingAdminBalance)
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else if (_adminBalance != null)
                                    Text(
                                      '\$${_adminBalance!.toStringAsFixed(2)} USD',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
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

                    // User selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select User Recipient',
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
                            else if (_groupMembers.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No users found in your group',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              DropdownButtonFormField<GroupMemberDto>(
                                value: _selectedUser,
                                decoration: const InputDecoration(
                                  labelText: 'User',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: _groupMembers.map((user) {
                                  return DropdownMenuItem(
                                    value: user,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user.email,
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
                                          _selectedUser = value;
                                        });
                                        if (value != null) {
                                          _loadUserBalance(value.id);
                                        }
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a user';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User current balance
                    if (_selectedUser != null)
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
                                      'User Current Balance',
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
                                    else if (_userBalance != null)
                                      Text(
                                        '\$${_userBalance!.toStringAsFixed(2)} USD',
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
                                if (_adminBalance != null && amount > _adminBalance!) {
                                  return 'Insufficient funds';
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
                                  DateFormatter.formatDate(_selectedDate),
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
