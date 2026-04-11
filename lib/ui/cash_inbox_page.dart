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
import '../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../features/incoming/presentation/bloc/incoming_event.dart';
import '../features/incoming/presentation/bloc/incoming_state.dart';
import '../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../features/admin_group/presentation/bloc/admin_group_event.dart';
import '../features/admin_group/presentation/bloc/admin_group_state.dart';
import '../features/admin_group/domain/entities/group_member.dart';
import '../injection_container.dart' as di;
import '../l10n/app_localizations.dart';
import '../models/exchange_record.dart';
import '../models/incoming.dart';
import '../models/transfer.dart';
import '../utils/pdf_export_helper.dart';
import '../core/config/flavor_config.dart';
import '../core/widgets/watermark_background.dart';
import '../state/filters.dart';

class CashInboxPage extends StatefulWidget {
  const CashInboxPage({super.key});

  @override
  State<CashInboxPage> createState() => _CashInboxPageState();
}

class _CashInboxPageState extends State<CashInboxPage> with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  late TabController _tabController;
  
  int? _currentUserId;
  
  // Filters for admin flavor
  DateFilterType _outgoingDateFilterType = DateFilterType.all;
  DateTime? _outgoingStartDate;
  DateTime? _outgoingEndDate;
  String? _selectedUserFilter; // User ID as string for outgoing transfers
  
  DateFilterType _incomingDateFilterType = DateFilterType.all;
  DateTime? _incomingStartDate;
  DateTime? _incomingEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Get current user and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      _currentUserId = authState.user!.id;
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      context.read<TransferBloc>().add(LoadTransfersEvent(_currentUserId!));
      context.read<IncomingBloc>().add(const LoadIncoming());
      
      // Load group members for admin flavor (for user filter)
      if (FlavorConfig.instance.isAdmin) {
        context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
      }
    }
  }

  void _reload() {
    if (_currentUserId != null) {
      context.read<FundBoxBloc>().add(RefreshFundBox(_currentUserId!));
      context.read<TransferBloc>().add(LoadTransfersEvent(_currentUserId!));
      context.read<IncomingBloc>().add(const LoadIncoming());
    }
  }

  List<TransferRecord> _filterTransfers(List<TransferRecord> transfers) {
    if (!FlavorConfig.instance.isAdmin) {
      return transfers;
    }
    
    var filtered = transfers;
    
    // Apply user filter
    // For outgoing transfers, we filter by recipientUserId (who receives the transfer)
    // because the userId is always the admin (who sends it)
    if (_selectedUserFilter != null && _selectedUserFilter!.isNotEmpty) {
      final filteredUserId = int.tryParse(_selectedUserFilter!);
      if (filteredUserId != null) {
        filtered = filtered.where((t) {
          // Check if the transfer's recipientUserId matches the selected user
          // If recipientUserId is null, skip this transfer (shouldn't happen for admin transfers)
          return t.recipientUserId == filteredUserId;
        }).toList();
      }
    }
    
    // Apply date filter
    if (_outgoingDateFilterType != DateFilterType.all) {
      final now = DateTime.now();
      filtered = filtered.where((t) {
        final transferDate = t.transactionDate;
        switch (_outgoingDateFilterType) {
          case DateFilterType.today:
            return transferDate.year == now.year &&
                transferDate.month == now.month &&
                transferDate.day == now.day;
          case DateFilterType.thisWeek:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            return transferDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                transferDate.isBefore(weekEnd.add(const Duration(days: 1)));
          case DateFilterType.thisMonth:
            return transferDate.year == now.year &&
                transferDate.month == now.month;
          case DateFilterType.custom:
            if (_outgoingStartDate != null && _outgoingEndDate != null) {
              return transferDate.isAfter(_outgoingStartDate!.subtract(const Duration(days: 1))) &&
                  transferDate.isBefore(_outgoingEndDate!.add(const Duration(days: 1)));
            }
            return true;
          case DateFilterType.all:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  List<IncomingRecord> _filterIncoming(List<IncomingRecord> incoming) {
    if (!FlavorConfig.instance.isAdmin) {
      return incoming;
    }
    
    var filtered = incoming;
    
    // Apply date filter
    if (_incomingDateFilterType != DateFilterType.all) {
      final now = DateTime.now();
      filtered = filtered.where((i) {
        final incomingDate = i.transactionDate;
        switch (_incomingDateFilterType) {
          case DateFilterType.today:
            return incomingDate.year == now.year &&
                incomingDate.month == now.month &&
                incomingDate.day == now.day;
          case DateFilterType.thisWeek:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            return incomingDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                incomingDate.isBefore(weekEnd.add(const Duration(days: 1)));
          case DateFilterType.thisMonth:
            return incomingDate.year == now.year &&
                incomingDate.month == now.month;
          case DateFilterType.custom:
            if (_incomingStartDate != null && _incomingEndDate != null) {
              return incomingDate.isAfter(_incomingStartDate!.subtract(const Duration(days: 1))) &&
                  incomingDate.isBefore(_incomingEndDate!.add(const Duration(days: 1)));
            }
            return true;
          case DateFilterType.all:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _setFundBalance(BuildContext context) async {
    if (_currentUserId == null) return;
    
    final l10n = AppLocalizations.of(context);
    final fundBoxState = context.read<FundBoxBloc>().state;
    final currentUsd = fundBoxState is FundBoxLoaded ? fundBoxState.fundBox.balanceUsd : 0.0;
    final currentSyp = fundBoxState is FundBoxLoaded ? fundBoxState.fundBox.balanceSyp : 0.0;
    final currentTry = fundBoxState is FundBoxLoaded ? fundBoxState.fundBox.balanceTry : 0.0;
    
    final usdController = TextEditingController(text: currentUsd.toStringAsFixed(2));
    final sypController = TextEditingController(text: currentSyp.toStringAsFixed(2));
    final tryController = TextEditingController(text: currentTry.toStringAsFixed(2));
    
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Fund Box Balances'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'USD Balance',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                  hintText: 'e.g. 1000.00',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sypController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'SYP Balance',
                  prefixIcon: Icon(Icons.currency_pound, color: Colors.orange),
                  hintText: 'e.g. 50000.00',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'TRY Balance',
                  prefixIcon: Icon(Icons.currency_lira, color: Colors.blue),
                  hintText: 'e.g. 30000.00',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final usd = double.tryParse(usdController.text.trim());
              final syp = double.tryParse(sypController.text.trim());
              final tryValue = double.tryParse(tryController.text.trim());
              
              Navigator.pop(ctx, {
                'usd': usd,
                'syp': syp,
                'try': tryValue,
              });
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
    
    if (result != null && context.mounted) {
      context.read<FundBoxBloc>().add(UpdateFundBalance(
        userId: _currentUserId!,
        balanceUsd: result['usd'],
        balanceSyp: result['syp'],
        balanceTry: result['try'],
      ));
    }
  }

  Future<void> _createTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final flavorConfig = FlavorConfig.instance;
    
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final nameController = TextEditingController(); // For non-admin or manual entry

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        if (flavorConfig.isAdmin) {
          // For admin flavor: Always create a BlocProvider to ensure bloc is available
          // The dialog will automatically load admin group and members if needed
          return BlocProvider(
            create: (context) {
              final bloc = di.sl<AdminGroupBloc>();
              // Load admin group immediately when bloc is created
              // This ensures admin_group_id is available when creating transfers
              bloc.add(LoadAdminGroupEvent());
              // Also load group members
              bloc.add(const LoadGroupMembersEvent());
              return bloc;
            },
            child: _AdminTransferDialog(
              l10n: l10n,
              amountController: amountController,
              selectedDate: selectedDate,
              onDateChanged: (date) => selectedDate = date,
              onResult: (name, id) {
                // Result is handled via dialog return value
              },
            ),
          );
        } else {
          // For user flavor: Simple text field for recipient name
          return _UserTransferDialog(
            l10n: l10n,
            amountController: amountController,
            nameController: nameController,
            selectedDate: selectedDate,
            onDateChanged: (date) => selectedDate = date,
          );
        }
      },
    );

    if (result != null && result['create'] == true && _currentUserId != null) {
      final name = result['name'] as String? ?? '';
      final recipientId = result['recipientId'] as int?;
      final adminGroupId = result['adminGroupId'] as int?; // Get from dialog result
      final amount = double.tryParse(amountController.text.trim());
      
      if (name.isEmpty || amount == null || amount <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.pleaseFillAllFields ?? 'Please fill all fields')),
          );
        }
        return;
      }

      if (context.mounted) {
        // If admin_group_id was not provided by dialog, try to get it from AdminGroupBloc
        int? finalAdminGroupId = adminGroupId;
        if (finalAdminGroupId == null) {
          try {
            final adminGroupState = context.read<AdminGroupBloc>().state;
            if (adminGroupState.adminGroup != null) {
              finalAdminGroupId = adminGroupState.adminGroup!.id;
              print('[CashInboxPage] ✅ Found admin_group_id from AdminGroupBloc: $finalAdminGroupId');
            }
          } catch (e) {
            print('[CashInboxPage] ⚠️ Could not get admin_group_id from AdminGroupBloc: $e');
          }
        }
        
        if (finalAdminGroupId == null) {
          print('[CashInboxPage] ⚠️ WARNING: admin_group_id is NULL - backend MUST set it from recipient_user_id');
        }
        
        print('[CashInboxPage] 📤 Creating transfer:');
        print('[CashInboxPage]    User ID: $_currentUserId');
        print('[CashInboxPage]    Recipient Name: $name');
        print('[CashInboxPage]    Recipient User ID: $recipientId');
        print('[CashInboxPage]    Admin Group ID: $finalAdminGroupId');
        print('[CashInboxPage]    Amount USD: $amount');
        
        context.read<TransferBloc>().add(CreateTransferEvent(
          userId: _currentUserId!,
          recipientName: name,
          recipientUserId: recipientId, // Pass recipient ID for admin transfers
          adminGroupId: finalAdminGroupId, // Pass admin_group_id if available (backend should also set it)
          amountUsd: amount,
          convertedAmountUsd: 0.0,
          amountSypAtExchange: null,
          manualUsdToSypRate: null,
          transactionDate: selectedDate,
        ));
      }
    }
  }

  Future<void> _createIncoming(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final descController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n?.newIncoming ?? 'New Incoming'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n?.description ?? 'Description'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n?.amountUsd ?? 'Amount USD'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n?.transactionDate ?? 'Transaction Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setLocal(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n?.create ?? 'Create')),
          ],
        ),
      ),
    );

    if (result == true) {
      final desc = descController.text.trim();
      final amount = double.tryParse(amountController.text.trim());
      if (desc.isEmpty || amount == null) return;

      if (context.mounted) {
        context.read<IncomingBloc>().add(CreateIncoming(
          description: desc,
          amountUsd: amount,
          transactionDate: selectedDate,
        ));
      }
    }
  }

  Future<void> _exportCash() async {
    final l10n = AppLocalizations.of(context);
    try {
      final transferState = context.read<TransferBloc>().state;
      final incomingState = context.read<IncomingBloc>().state;
      
      if (transferState is TransferLoaded && incomingState is IncomingLoaded) {
        // Map transfers and include recipientUserId for filtering
        final transfers = transferState.transfers.map((t) => TransferRecord(
          id: t.id,
          recipientName: t.recipientName,
          amountUsd: t.amountUsd,
          convertedAmountUsd: t.convertedAmountUsd,
          amountSypAtExchange: t.amountSypAtExchange,
          manualUsdToSypRate: t.manualUsdToSypRate,
          transactionDate: t.transactionDate,
          createdAt: t.createdAt,
          userId: t.userId,
          recipientUserId: t.recipientUserId, // Include recipientUserId for filtering
        )).toList();
        
        final incoming = incomingState.incomingList.map((i) => IncomingRecord(
          id: i.id,
          description: i.description,
          amountUsd: i.amountUsd,
          transactionDate: i.transactionDate,
          createdAt: i.createdAt,
          userId: i.userId,
        )).toList();
        
        // Apply filters (including user filter for admin and date filters) before exporting
        final filteredTransfers = _filterTransfers(transfers);
        final filteredIncoming = _filterIncoming(incoming);
        
        await PdfExportHelper.exportCashTransactions(
          transfers: filteredTransfers,
          incoming: filteredIncoming,
          title: l10n?.cashTransactions ?? 'معاملات الصندوق',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.success ?? 'Export completed successfully'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.exportError ?? 'Export error'}: $e')),
        );
      }
    }
  }

  Future<void> _addExchange(BuildContext context, TransferRecord transfer) async {
    final l10n = AppLocalizations.of(context);
    final convertedUsdCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final convertedTotalSypCtrl = TextEditingController();
    
    void recompute() {
      final rate = double.tryParse(rateCtrl.text.trim());
      final convertedUsd = double.tryParse(convertedUsdCtrl.text.trim());
      if (rate != null && convertedUsd != null) {
        convertedTotalSypCtrl.text = (rate * convertedUsd).toStringAsFixed(0);
      } else {
        convertedTotalSypCtrl.text = '';
      }
    }
    
    rateCtrl.addListener(recompute);
    convertedUsdCtrl.addListener(recompute);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.addExchange ?? 'Add Exchange'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: convertedUsdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n?.convertedAmount ?? 'Converted Amount'),
              ),
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n?.exchangeRate ?? 'Exchange Rate'),
              ),
              TextField(
                controller: convertedTotalSypCtrl,
                readOnly: true,
                decoration: InputDecoration(labelText: l10n?.convertedTotalSyp ?? 'Converted Total SYP'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.cancel ?? 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n?.save ?? 'Save')),
        ],
      ),
    );
    
    if (result == true) {
      final convertedAmount = double.tryParse(convertedUsdCtrl.text.trim());
      final rate = double.tryParse(rateCtrl.text.trim());
      final sypAmount = double.tryParse(convertedTotalSypCtrl.text.trim());
      
      if (convertedAmount != null && convertedAmount > 0) {
        final exchange = ExchangeRecord(
          transferId: transfer.id!,
          convertedAmountUsd: convertedAmount,
          amountSypAtExchange: sypAmount,
          manualUsdToSypRate: rate,
          createdAt: DateTime.now(),
        );
        
        await _db.createExchangeRecord(exchange);
        setState(_reload);
      }
    }
  }

  Future<void> _showExchangeHistory(BuildContext context, TransferRecord transfer) async {
    final l10n = AppLocalizations.of(context);
    final exchanges = await _db.listExchangesByTransfer(transfer.id!);
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.exchangeHistory ?? 'Exchange History'),
        content: exchanges.isEmpty
            ? Text(l10n?.noExchanges ?? 'No Exchanges')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: exchanges.map((e) => Card(
                    child: ListTile(
                      title: Text('${e.convertedAmountUsd.toStringAsFixed(2)} ${l10n?.usd ?? 'USD'}'),
                      subtitle: Text(
                        '${l10n?.exchangeRate ?? 'Exchange Rate'}: ${e.manualUsdToSypRate?.toStringAsFixed(0) ?? '-'} → ${e.amountSypAtExchange?.toStringAsFixed(0) ?? '-'} ${l10n?.syp ?? 'SYP'}',
                      ),
                      trailing: Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}'),
                    ),
                  )).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return MultiBlocListener(
      listeners: [
        BlocListener<TransferBloc, TransferState>(
          listener: (context, state) {
            if (state is TransferCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n?.transferCreated ?? 'Transfer Created')),
              );
              _reload();
            } else if (state is TransferDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n?.transferDeleted ?? 'Transfer Deleted')),
              );
              _reload();
            } else if (state is TransferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
        BlocListener<IncomingBloc, IncomingState>(
          listener: (context, state) {
            if (state is IncomingOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              _reload();
            } else if (state is IncomingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
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
        child: Column(
          children: [
            // Fund Box Cards - Scrollable per currency (Admin and User)
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isAdmin = authState is AuthAuthenticated && authState.user?.isAdmin == true;
                
                // Show for admin and user flavors (where fund box is visible)
                if (!isAdmin && !FlavorConfig.instance.isUser) {
                  return const SizedBox.shrink();
                }
                
                return SizedBox(
                  height: 200,
                  child: BlocBuilder<FundBoxBloc, FundBoxState>(
                    builder: (context, state) {
                      print('[CashInboxPage] FundBoxState: ${state.runtimeType}');
                      
                      if (state is FundBoxLoaded) {
                        final fundBox = state.fundBox;
                        print('[CashInboxPage] Displaying fundbox: USD=${fundBox.balanceUsd}, SYP=${fundBox.balanceSyp}, TRY=${fundBox.balanceTry}');
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
                              onEdit: null,
                            ),
                            // SYP Card
                            _buildCurrencyCard(
                              context: context,
                              currency: 'SYP',
                              icon: Icons.currency_pound,
                              color: Colors.orange,
                              balance: fundBox.balanceSyp,
                              symbol: '',
                              onEdit: null,
                            ),
                            // TRY Card
                            _buildCurrencyCard(
                              context: context,
                              currency: 'TRY',
                              icon: Icons.currency_lira,
                              color: Colors.blue,
                              balance: fundBox.balanceTry,
                              symbol: '',
                              onEdit: null,
                            ),
                          ],
                        );
                      } else if (state is FundBoxUpdating) {
                        // Show current data while updating
                        final fundBox = state.currentFundBox;
                        return Stack(
                          children: [
                            PageView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildCurrencyCard(
                                  context: context,
                                  currency: 'USD',
                                  icon: Icons.attach_money,
                                  color: Colors.green,
                                  balance: fundBox.balanceUsd,
                                  symbol: '\$',
                                  onEdit: null,
                                ),
                                _buildCurrencyCard(
                                  context: context,
                                  currency: 'SYP',
                                  icon: Icons.currency_pound,
                                  color: Colors.orange,
                                  balance: fundBox.balanceSyp,
                                  symbol: '',
                                  onEdit: null,
                                ),
                                _buildCurrencyCard(
                                  context: context,
                                  currency: 'TRY',
                                  icon: Icons.currency_lira,
                                  color: Colors.blue,
                                  balance: fundBox.balanceTry,
                                  symbol: '',
                                  onEdit: null,
                                ),
                              ],
                            ),
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        );
                      } else if (state is FundBoxError) {
                        print('[CashInboxPage] FundBoxError: ${state.message}');
                        return Card(
                          margin: const EdgeInsets.all(16),
                          child: ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: const Text('Error loading fund box'),
                            subtitle: Text(state.message),
                            trailing: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                if (_currentUserId != null) {
                                  context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
                                }
                              },
                            ),
                          ),
                        );
                      } else {
                        // FundBoxLoading or FundBoxInitial
                        print('[CashInboxPage] Showing loading spinner. State: ${state.runtimeType}');
                        return const Card(
                          margin: EdgeInsets.all(16),
                          child: ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Loading fund box...'),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
            
            // Export Row with Filters (for admin flavor)
            if (FlavorConfig.instance.isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Date filter dropdown
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isOutgoing = _tabController.index == 0;
                          return DropdownButtonFormField<DateFilterType>(
                            value: isOutgoing 
                                ? _outgoingDateFilterType 
                                : _incomingDateFilterType,
                            decoration: InputDecoration(
                              labelText: l10n?.date ?? 'Date',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: DateFilterType.all, child: Text(l10n?.all ?? 'All')),
                              DropdownMenuItem(value: DateFilterType.today, child: Text(l10n?.today ?? 'Today')),
                              DropdownMenuItem(value: DateFilterType.thisWeek, child: Text(l10n?.thisWeek ?? 'This Week')),
                              DropdownMenuItem(value: DateFilterType.thisMonth, child: Text(l10n?.thisMonth ?? 'This Month')),
                              DropdownMenuItem(value: DateFilterType.custom, child: Text(l10n?.custom ?? 'Custom')),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              
                              if (v == DateFilterType.custom) {
                                final startDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (startDate != null) {
                                  final endDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: startDate,
                                    lastDate: DateTime.now(),
                                  );
                                  if (endDate != null) {
                                    setState(() {
                                      if (isOutgoing) {
                                        _outgoingDateFilterType = v;
                                        _outgoingStartDate = startDate;
                                        _outgoingEndDate = endDate;
                                      } else {
                                        _incomingDateFilterType = v;
                                        _incomingStartDate = startDate;
                                        _incomingEndDate = endDate;
                                      }
                                    });
                                  }
                                }
                              } else {
                                setState(() {
                                  if (isOutgoing) {
                                    _outgoingDateFilterType = v;
                                    _outgoingStartDate = null;
                                    _outgoingEndDate = null;
                                  } else {
                                    _incomingDateFilterType = v;
                                    _incomingStartDate = null;
                                    _incomingEndDate = null;
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // User filter dropdown (only for outgoing tab)
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        if (_tabController.index != 0) {
                          return const SizedBox.shrink();
                        }
                        return Expanded(
                          child: BlocBuilder<AdminGroupBloc, AdminGroupState>(
                            builder: (context, state) {
                              // Get all group members from state
                              final members = state.members;
                              final allUserIds = <int, String>{};
                              
                              // Add current admin user (admin owner)
                              final authState = context.read<AuthBloc>().state;
                              if (authState is AuthAuthenticated && authState.user != null) {
                                allUserIds[authState.user!.id] = authState.user!.username;
                              }
                              
                              // Add all group members
                              for (final member in members) {
                                if (!allUserIds.containsKey(member.id)) {
                                  allUserIds[member.id] = member.name;
                                }
                              }
                              
                              // Sort users by name
                              final sortedUsers = allUserIds.entries.toList()
                                ..sort((a, b) => a.value.compareTo(b.value));
                              
                              return DropdownButtonFormField<String?>(
                                value: _selectedUserFilter,
                                decoration: InputDecoration(
                                  labelText: l10n?.user ?? 'User',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                                hint: Text(l10n?.allUsers ?? 'All Users'),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(l10n?.allUsers ?? 'All Users'),
                                  ),
                                  ...sortedUsers.map((entry) {
                                    return DropdownMenuItem<String?>(
                                      value: entry.key.toString(),
                                      child: Text(entry.value),
                                    );
                                  }),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedUserFilter = v;
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Export button
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: _exportCash,
                      tooltip: l10n?.exportCash ?? 'Export Cash',
                    ),
                  ],
                ),
              )
            else
              // Export button only (for non-admin flavors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: _exportCash,
                      tooltip: l10n?.exportCash ?? 'Export Cash',
                    ),
                  ],
                ),
              ),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n?.outgoing ?? 'Outgoing'),
                Tab(text: l10n?.incoming ?? 'Incoming'),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOutgoingTab(l10n),
                  _buildIncomingTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingTab(AppLocalizations? l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () => _createTransfer(context),
                icon: const Icon(Icons.call_made),
                label: Text(l10n?.transfer ?? 'Transfer'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
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
                  
                  // Apply filters
                  final items = _filterTransfers(transfers);
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(l10n?.noSypRecorded ?? 'No transfers found'),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final t = items[index];
                      
                      return FutureBuilder<List<ExchangeRecord>>(
                        future: _db.listExchangesByTransfer(t.id!),
                        builder: (context, exchangeSnapshot) {
                          // Calculate total exchanged amount (initial + all additional exchanges)
                          final initialConverted = t.convertedAmountUsd ?? 0.0;
                          final additionalExchanges = exchangeSnapshot.data ?? [];
                          final totalExchanged = initialConverted + 
                            additionalExchanges.fold(0.0, (sum, e) => sum + e.convertedAmountUsd);
                          
                          final actualUsdRemaining = t.amountUsd - totalExchanged;
                          
                          return Card(
                            child: ListTile(
                              title: Text(
                                '${t.recipientName} • ${actualUsdRemaining.toStringAsFixed(2)} ${l10n?.usd ?? 'USD'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'refund_delete') {
                                    if (_currentUserId != null) {
                                      context.read<TransferBloc>().add(DeleteTransferEvent(
                                        transferId: t.id!,
                                        userId: _currentUserId!,
                                        refund: true,
                                      ));
                                    }
                                  } else if (value == 'delete') {
                                    if (_currentUserId != null) {
                                      context.read<TransferBloc>().add(DeleteTransferEvent(
                                        transferId: t.id!,
                                        userId: _currentUserId!,
                                        refund: false,
                                      ));
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(value: 'refund_delete', child: Text(l10n?.refundDelete ?? 'Refund and Delete')),
                                  PopupMenuItem(value: 'delete', child: Text(l10n?.delete ?? 'Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                
                return ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(child: Text(l10n?.noSypRecorded ?? 'No transfers found')),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingTab(AppLocalizations? l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Hide income adding button in admin flavor
              if (!FlavorConfig.instance.isAdmin)
                FilledButton.icon(
                  onPressed: () => _createIncoming(context),
                  icon: const Icon(Icons.call_received),
                  label: Text(l10n?.addIncoming ?? 'Add Incoming'),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: BlocBuilder<IncomingBloc, IncomingState>(
              builder: (context, state) {
                if (state is IncomingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is IncomingLoaded) {
                  final incoming = state.incomingList.map((i) => IncomingRecord(
                    id: i.id,
                    description: i.description,
                    amountUsd: i.amountUsd,
                    transactionDate: i.transactionDate,
                    createdAt: i.createdAt,
                    userId: i.userId,
                  )).toList();
                  
                  // Apply filters
                  final items = _filterIncoming(incoming);
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(l10n?.noSypRecorded ?? 'No incoming found'),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final i = items[index];
                      // Note: Transfers from SuperAdmin will appear in this list
                      // They are automatically non-deletable for admins (admin flavor can't delete incoming)
                      // Regular users can delete their own incoming records, but transfers appear in transfers tab, not incoming
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.add_circle, color: Colors.green),
                          title: Text(
                            '${i.description} • ${i.amountUsd.toStringAsFixed(2)} ${l10n?.usd ?? 'USD'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${i.transactionDate.day}/${i.transactionDate.month}/${i.transactionDate.year}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Remove popup menu in admin flavor (admins can't delete incoming, including transfers from SuperAdmin)
                          trailing: FlavorConfig.instance.isAdmin
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'refund_delete') {
                                      context.read<IncomingBloc>().add(DeleteIncoming(
                                        id: i.id!,
                                        refund: true,
                                      ));
                                    } else if (value == 'delete') {
                                      context.read<IncomingBloc>().add(DeleteIncoming(
                                        id: i.id!,
                                        refund: false,
                                      ));
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(value: 'refund_delete', child: Text(l10n?.refundDelete ?? 'Refund and Delete')),
                                    PopupMenuItem(value: 'delete', child: Text(l10n?.delete ?? 'Delete')),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                }
                return ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(child: Text(l10n?.noSypRecorded ?? 'No incoming found')),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard({
    required BuildContext context,
    required String currency,
    required IconData icon,
    required Color color,
    required double balance,
    required String symbol,
    VoidCallback? onEdit,
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

/// Admin Transfer Dialog with dropdown for group members (users only)
class _AdminTransferDialog extends StatefulWidget {
  final AppLocalizations? l10n;
  final TextEditingController amountController;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final Function(String, int?) onResult;

  const _AdminTransferDialog({
    required this.l10n,
    required this.amountController,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onResult,
  });

  @override
  State<_AdminTransferDialog> createState() => _AdminTransferDialogState();
}

class _AdminTransferDialogState extends State<_AdminTransferDialog> {
  int? selectedRecipientId;
  String? selectedRecipientName;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    
    // Load admin group and members when dialog opens if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AdminGroupBloc>();
      final currentState = bloc.state;
      
      // Load admin group if not loaded
      if (currentState.adminGroup == null && !currentState.isLoading) {
        print('[AdminTransferDialog] Loading admin group on dialog open...');
        bloc.add(LoadAdminGroupEvent());
      }
      
      // Check if members are not loaded or empty, and not currently loading
      if (!currentState.isLoadingMembers && 
          currentState.members.isEmpty &&
          currentState is! AdminGroupError) {
        print('[AdminTransferDialog] Loading group members on dialog open...');
        bloc.add(const LoadGroupMembersEvent());
      } else if (currentState.members.isNotEmpty) {
        print('[AdminTransferDialog] Group members already loaded: ${currentState.members.length} members');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n?.newTransfer ?? 'New Transfer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recipient dropdown - shows only regular users (not admins) from the group
            BlocBuilder<AdminGroupBloc, AdminGroupState>(
              builder: (context, state) {
                // Filter to show only regular users (not admins)
                final users = state.members.where((member) => !member.isAdmin).toList();
                
                // If loading, show loading indicator
                if (state.isLoadingMembers) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                // If error, show error message with retry button
                if (state is AdminGroupError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(widget.l10n?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                // If no users, show message
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.l10n?.noGroupFound ?? 'No users in group',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(widget.l10n?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: widget.l10n?.recipientName ?? 'Recipient Name',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  value: selectedRecipientId,
                  hint: Text(widget.l10n?.selectRecipient ?? 'Select recipient'),
                  items: users.map((member) {
                    return DropdownMenuItem<int>(
                      value: member.id,
                      child: Text(
                        '${member.name} (${member.email})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                    return users.map<Widget>((member) {
                      return Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedRecipientId = value;
                      if (value != null) {
                        selectedRecipientName = users.firstWhere((m) => m.id == value).name;
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: widget.l10n?.amountUsd ?? 'Amount USD',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(widget.l10n?.transactionDate ?? 'Transaction Date'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  widget.onDateChanged(date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'create': false}),
          child: Text(widget.l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: selectedRecipientId == null
              ? null
              : () {
                  if (selectedRecipientName != null && selectedRecipientId != null) {
                    widget.onResult(selectedRecipientName!, selectedRecipientId);
                    
                    // Get admin_group_id from AdminGroupBloc state
                    int? adminGroupId;
                    try {
                      final adminGroupState = context.read<AdminGroupBloc>().state;
                      if (adminGroupState.adminGroup != null) {
                        adminGroupId = adminGroupState.adminGroup!.id;
                        print('[AdminTransferDialog] ✅ Found admin_group_id: $adminGroupId');
                      } else {
                        print('[AdminTransferDialog] ⚠️ AdminGroup not loaded in dialog');
                      }
                    } catch (e) {
                      print('[AdminTransferDialog] ⚠️ Could not get admin_group_id: $e');
                    }
                    
                    Navigator.pop(context, {
                      'create': true,
                      'name': selectedRecipientName,
                      'recipientId': selectedRecipientId,
                      'adminGroupId': adminGroupId,
                    });
                  }
                },
          child: Text(widget.l10n?.create ?? 'Create'),
        ),
      ],
    );
  }
}

/// User Transfer Dialog with text field for recipient name
class _UserTransferDialog extends StatefulWidget {
  final AppLocalizations? l10n;
  final TextEditingController amountController;
  final TextEditingController nameController;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _UserTransferDialog({
    required this.l10n,
    required this.amountController,
    required this.nameController,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<_UserTransferDialog> createState() => _UserTransferDialogState();
}

class _UserTransferDialogState extends State<_UserTransferDialog> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n?.newTransfer ?? 'New Transfer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: widget.l10n?.recipientName ?? 'Recipient Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: widget.l10n?.amountUsd ?? 'Amount USD',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(widget.l10n?.transactionDate ?? 'Transaction Date'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  widget.onDateChanged(date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'create': false}),
          child: Text(widget.l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'create': true,
              'name': widget.nameController.text.trim(),
              'recipientId': null,
            });
          },
          child: Text(widget.l10n?.create ?? 'Create'),
        ),
      ],
    );
  }
}
