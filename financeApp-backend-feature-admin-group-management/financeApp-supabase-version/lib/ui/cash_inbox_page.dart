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
import '../l10n/app_localizations.dart';
import '../models/exchange_record.dart';
import '../models/fund_box.dart';
import '../models/incoming.dart';
import '../models/transfer.dart';
import '../utils/pdf_export_helper.dart';

enum CashDateFilter { all, thisMonth, thisYear, custom }

class CashInboxPage extends StatefulWidget {
  const CashInboxPage({super.key});

  @override
  State<CashInboxPage> createState() => _CashInboxPageState();
}

class _CashInboxPageState extends State<CashInboxPage> with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  late TabController _tabController;
  
  final TextEditingController _searchController = TextEditingController();
  CashDateFilter _dateFilter = CashDateFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
    
    // Get current user and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserAndData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
      context.read<FundBoxBloc>().add(LoadFundBox(_currentUserId!));
      context.read<TransferBloc>().add(LoadTransfersEvent(_currentUserId!));
      context.read<IncomingBloc>().add(const LoadIncoming());
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
    var filtered = transfers;
    
    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.recipientName.toLowerCase().contains(query)
      ).toList();
    }
    
    // Date filter
    final now = DateTime.now();
    filtered = filtered.where((t) {
      switch (_dateFilter) {
        case CashDateFilter.thisMonth:
          return t.transactionDate.year == now.year && 
                 t.transactionDate.month == now.month;
        case CashDateFilter.thisYear:
          return t.transactionDate.year == now.year;
        case CashDateFilter.custom:
          if (_customStartDate != null && _customEndDate != null) {
            return t.transactionDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                   t.transactionDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
          }
          return true;
        case CashDateFilter.all:
        default:
          return true;
      }
    }).toList();
    
    return filtered;
  }

  List<IncomingRecord> _filterIncoming(List<IncomingRecord> incoming) {
    var filtered = incoming;
    
    // Date filter
    final now = DateTime.now();
    filtered = filtered.where((i) {
      switch (_dateFilter) {
        case CashDateFilter.thisMonth:
          return i.transactionDate.year == now.year && 
                 i.transactionDate.month == now.month;
        case CashDateFilter.thisYear:
          return i.transactionDate.year == now.year;
        case CashDateFilter.custom:
          if (_customStartDate != null && _customEndDate != null) {
            return i.transactionDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                   i.transactionDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
          }
          return true;
        case CashDateFilter.all:
        default:
          return true;
      }
    }).toList();
    
    return filtered;
  }

  Future<void> _setFundBalance(BuildContext context) async {
    if (_currentUserId == null) return;
    
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final newValue = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('set_fund_balance')),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 1000.00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.translate('cancel'))),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, v);
            },
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );
    if (newValue != null && context.mounted) {
      context.read<FundBoxBloc>().add(UpdateFundBalance(
        userId: _currentUserId!,
        newBalance: newValue,
      ));
    }
  }

  Future<void> _createTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final convertedUsdController = TextEditingController();
    final rateController = TextEditingController();
    final convertedTotalSypController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    void recompute() {
      final rate = double.tryParse(rateController.text.trim());
      final convertedUsd = double.tryParse(convertedUsdController.text.trim());
      if (rate != null && convertedUsd != null) {
        convertedTotalSypController.text = (rate * convertedUsd).toStringAsFixed(0);
      } else {
        convertedTotalSypController.text = '';
      }
    }

    rateController.addListener(recompute);
    convertedUsdController.addListener(recompute);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.translate('new_transfer')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.translate('recipient_name')),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.translate('amount_usd')),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n.translate('transaction_date')),
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
                const SizedBox(height: 8),
                TextField(
                  controller: convertedUsdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.translate('converted_amount')),
                ),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.translate('exchange_rate')),
                ),
                TextField(
                  controller: convertedTotalSypController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: l10n.translate('converted_total_syp')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.translate('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.translate('create'))),
          ],
        ),
      ),
    );

    if (result == true && _currentUserId != null) {
      final name = nameController.text.trim();
      final amount = double.tryParse(amountController.text.trim());
      final convertedAmount = double.tryParse(convertedUsdController.text.trim()) ?? 0.0;
      final rate = double.tryParse(rateController.text.trim());
      final sypAmount = double.tryParse(convertedTotalSypController.text.trim());
      if (name.isEmpty || amount == null) return;

      if (convertedAmount > amount) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('converted_amount_error'))),
          );
        }
        return;
      }

      if (context.mounted) {
        context.read<TransferBloc>().add(CreateTransferEvent(
          userId: _currentUserId!,
          recipientName: name,
          amountUsd: amount,
          convertedAmountUsd: convertedAmount,
          amountSypAtExchange: sypAmount,
          manualUsdToSypRate: rate,
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
          title: Text(l10n.translate('new_incoming')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.translate('description')),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.translate('amount_usd')),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(l10n.translate('transaction_date')),
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.translate('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.translate('create'))),
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
    try {
      final transferState = context.read<TransferBloc>().state;
      final incomingState = context.read<IncomingBloc>().state;
      
      if (transferState is TransferLoaded && incomingState is IncomingLoaded) {
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
        )).toList();
        
        final incoming = incomingState.incomingList.map((i) => IncomingRecord(
          id: i.id,
          description: i.description,
          amountUsd: i.amountUsd,
          transactionDate: i.transactionDate,
          createdAt: i.createdAt,
          userId: i.userId,
        )).toList();
        
        final filteredTransfers = _filterTransfers(transfers);
        final filteredIncoming = _filterIncoming(incoming);
        
        await PdfExportHelper.exportCashTransactions(
          transfers: filteredTransfers,
          incoming: filteredIncoming,
          title: 'معاملات النقد',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: Text(l10n.translate('add_exchange')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: convertedUsdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.translate('converted_amount')),
              ),
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.translate('exchange_rate')),
              ),
              TextField(
                controller: convertedTotalSypCtrl,
                readOnly: true,
                decoration: InputDecoration(labelText: l10n.translate('converted_total_syp')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.translate('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.translate('save'))),
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
        title: Text(l10n.translate('exchange_history')),
        content: exchanges.isEmpty
            ? Text(l10n.translate('no_exchanges'))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: exchanges.map((e) => Card(
                    child: ListTile(
                      title: Text('${e.convertedAmountUsd.toStringAsFixed(2)} ${l10n.translate('usd')}'),
                      subtitle: Text(
                        '${l10n.translate('exchange_rate')}: ${e.manualUsdToSypRate?.toStringAsFixed(0) ?? '-'} → ${e.amountSypAtExchange?.toStringAsFixed(0) ?? '-'} ${l10n.translate('syp')}',
                      ),
                      trailing: Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}'),
                    ),
                  )).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
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
                SnackBar(content: Text(l10n.translate('transfer_created'))),
              );
              _reload();
            } else if (state is TransferDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translate('transfer_deleted'))),
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
      child: Column(
        children: [
          // Fund Box Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<FundBoxBloc, FundBoxState>(
              builder: (context, state) {
                final balance = state is FundBoxLoaded ? state.fundBox.balanceUsd : 0.0;
                return Card(
                  child: ListTile(
                    title: Text(l10n.translate('fund_box_usd')),
                    subtitle: Text(balance.toStringAsFixed(2)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _setFundBalance(context),
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Search, Filter, and Export Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('search_by_name'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: _exportCash,
                tooltip: l10n.translate('export_cash'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<CashDateFilter>(
                icon: const Icon(Icons.filter_list),
                onSelected: (filter) async {
                  if (filter == CashDateFilter.custom) {
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
                          _dateFilter = filter;
                          _customStartDate = startDate;
                          _customEndDate = endDate;
                        });
                      }
                    }
                  } else {
                    setState(() => _dateFilter = filter);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: CashDateFilter.all, child: Text(l10n.translate('all'))),
                  PopupMenuItem(value: CashDateFilter.thisMonth, child: Text(l10n.translate('this_month'))),
                  PopupMenuItem(value: CashDateFilter.thisYear, child: Text(l10n.translate('this_year'))),
                  PopupMenuItem(value: CashDateFilter.custom, child: Text(l10n.translate('custom'))),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Tabs
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.translate('outgoing')),
            Tab(text: l10n.translate('incoming')),
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
    );
  }

  Widget _buildOutgoingTab(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () => _createTransfer(context),
                icon: const Icon(Icons.call_made),
                label: Text(l10n.translate('transfer')),
              ),
            ],
          ),
        ),
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
                )).toList();
                
                final items = _filterTransfers(transfers);
                if (items.isEmpty) {
                  return Center(child: Text(l10n.translate('no_syp_recorded')));
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
                      
                      String subtitle = '';
                      if (totalExchanged > 0) {
                        subtitle = '${l10n.translate('converted_amount')}: ${totalExchanged.toStringAsFixed(2)} ${l10n.translate('usd')}';
                        if (additionalExchanges.isNotEmpty) {
                          subtitle += ' (${additionalExchanges.length + 1} ${l10n.translate('exchange_history')})';
                        }
                      } else {
                        subtitle = l10n.translate('no_syp_recorded');
                      }
                      
                      return Card(
                        child: ListTile(
                          title: Text('${t.recipientName} • ${actualUsdRemaining.toStringAsFixed(2)} ${l10n.translate('usd')}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subtitle),
                              Text('${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'add_exchange') {
                                await _addExchange(context, t);
                              } else if (value == 'view_history') {
                                await _showExchangeHistory(context, t);
                              } else if (value == 'refund_delete') {
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
                              PopupMenuItem(value: 'add_exchange', child: Text(l10n.translate('add_exchange'))),
                              PopupMenuItem(value: 'view_history', child: Text(l10n.translate('exchange_history'))),
                              const PopupMenuDivider(),
                              PopupMenuItem(value: 'refund_delete', child: Text(l10n.translate('refund_delete'))),
                              PopupMenuItem(value: 'delete', child: Text(l10n.translate('delete'))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
              }
              
              return Center(child: Text(l10n.translate('no_syp_recorded')));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingTab(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () => _createIncoming(context),
                icon: const Icon(Icons.call_received),
                label: Text(l10n.translate('add_incoming')),
              ),
            ],
          ),
        ),
        Expanded(
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
                
                final items = _filterIncoming(incoming);
                if (items.isEmpty) {
                  return Center(child: Text(l10n.translate('no_syp_recorded')));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final i = items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.green),
                        title: Text('${i.description} • ${i.amountUsd.toStringAsFixed(2)} ${l10n.translate('usd')}'),
                        subtitle: Text('${i.transactionDate.day}/${i.transactionDate.month}/${i.transactionDate.year}'),
                        trailing: PopupMenuButton<String>(
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
                            PopupMenuItem(value: 'refund_delete', child: Text(l10n.translate('refund_delete'))),
                            PopupMenuItem(value: 'delete', child: Text(l10n.translate('delete'))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return Center(child: Text(l10n.translate('no_syp_recorded')));
              },
            ),
          ),
      ],
    );
  }
}
