import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/flavor_config.dart';
import '../../domain/entities/exchange.dart';
import '../bloc/exchange_bloc.dart';
import '../bloc/exchange_event.dart';
import '../bloc/exchange_state.dart';
import '../../../admin_group/presentation/bloc/admin_group_bloc.dart';
import '../../../admin_group/presentation/bloc/admin_group_event.dart';
import '../../../admin_group/presentation/bloc/admin_group_state.dart';
import '../../../../state/filters.dart';
import '../../../../utils/pdf_export_helper.dart';
import '../../../../core/widgets/watermark_background.dart';

/// Exchange History Page
/// Shows user's own exchanges (filtered by backend based on authenticated user)
class ExchangeHistoryPage extends StatefulWidget {
  const ExchangeHistoryPage({super.key});

  @override
  State<ExchangeHistoryPage> createState() => _ExchangeHistoryPageState();
}

class _ExchangeHistoryPageState extends State<ExchangeHistoryPage> {
  List<String> _groupMemberNames = [];
  bool _isExporting = false;
  String? _selectedCurrency; // null = 'all', 'SYP', or 'TRY'
  
  @override
  void initState() {
    super.initState();
    _loadExchanges();
    _loadGroupMembers();
  }

  void _loadExchanges() {
    // Load all exchanges - backend filters by authenticated user
    // Admin sees all exchanges in their group
    // Regular users see only their own exchanges
    // Currency filter: null = 'all', 'SYP', or 'TRY'
    context.read<ExchangeBloc>().add(LoadAllExchangesEvent(currency: _selectedCurrency));
  }
  
  void _loadGroupMembers() {
    // Load group members for admin flavor
    if (FlavorConfig.instance.isAdmin) {
      context.read<AdminGroupBloc>().add(const LoadGroupMembersEvent());
    }
  }
  
  List<Exchange> _getFilteredExchanges(List<Exchange> exchanges) {
    var filtered = exchanges;
    
    // Filter by user (userName) - only for admin flavor
    // For user flavor, backend already filters to show only user's own exchanges
    if (FlavorConfig.instance.isAdmin) {
      final selectedUser = RecipientFilterNotifier.instance.value;
      if (selectedUser != null) {
        filtered = filtered.where((e) => e.userName == selectedUser).toList();
      }
    }
    
    // Filter by currency (if not 'all')
    if (_selectedCurrency != null && _selectedCurrency != 'all') {
      filtered = filtered.where((e) => e.targetCurrency == _selectedCurrency).toList();
    }
    
    return filtered;
  }
  
  double _calculateSypSum(List<Exchange> exchanges) {
    return exchanges.fold(0.0, (sum, e) {
      final sypAmount = e.amountSyp ?? 0.0;
      return sum + sypAmount;
    });
  }
  
  double _calculateTrySum(List<Exchange> exchanges) {
    return exchanges.fold(0.0, (sum, e) {
      final tryAmount = e.amountTry ?? 0.0;
      return sum + tryAmount;
    });
  }

  Future<void> _exportExchanges() async {
    final l10n = AppLocalizations.of(context);
    final exchangeState = context.read<ExchangeBloc>().state;
    
    if (exchangeState is! ExchangesLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('no_data_available') ?? 'No data available')),
      );
      return;
    }

    setState(() => _isExporting = true);
    
    try {
      final allExchanges = exchangeState.exchanges;
      final filteredExchanges = _getFilteredExchanges(allExchanges);
      
      if (filteredExchanges.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('no_exchanges_yet') ?? 'No exchanges to export')),
          );
        }
        return;
      }

      // Get the selected recipient name if filter is applied
      final selectedRecipient = RecipientFilterNotifier.instance.value;
      
      // Export using PdfExportHelper
      await PdfExportHelper.exportExchanges(
        exchanges: filteredExchanges,
        userName: selectedRecipient,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('export_error') ?? 'Export error'}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAdmin = FlavorConfig.instance.isAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('exchange_history') ?? 'Exchange History'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportExchanges,
            tooltip: l10n.translate('export_exchanges') ?? 'Export Exchanges',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadExchanges();
              _loadGroupMembers();
            },
          ),
        ],
      ),
      body: WatermarkBackground(
        child: BlocListener<AdminGroupBloc, AdminGroupState>(
        listener: (context, adminGroupState) {
          if (adminGroupState is GroupMembersLoaded) {
            setState(() {
              _groupMemberNames = adminGroupState.members
                  .map((m) => m.name)
                  .toList()
                ..sort();
            });
          }
        },
        child: BlocBuilder<ExchangeBloc, ExchangeState>(
          builder: (context, exchangeState) {
          if (exchangeState is ExchangeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exchangeState is ExchangeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l10n.translate('error') ?? 'Error'}: ${exchangeState.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExchanges,
                    child: Text(l10n.translate('retry') ?? 'Retry'),
                  ),
                ],
              ),
            );
          }

          if (exchangeState is ExchangesLoaded) {
            final allExchanges = exchangeState.exchanges;
            
            // Use ValueListenableBuilder to rebuild when filter changes
            return ValueListenableBuilder<String?>(
              valueListenable: RecipientFilterNotifier.instance,
              builder: (context, selectedUser, _) {
                final filteredExchanges = _getFilteredExchanges(allExchanges);
                final sypSum = _calculateSypSum(filteredExchanges);
                final trySum = _calculateTrySum(filteredExchanges);
                
                return Column(
                  children: [
                    // Filters Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Currency Filter
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: l10n.translate('filter_by_currency') ?? 'Filter by Currency',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.currency_exchange),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'SYP',
                                  child: Text('SYP', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'TRY',
                                  child: Text('TRY', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value;
                                });
                                _loadExchanges();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Recipient filter for admin flavor
                          if (isAdmin && _groupMemberNames.isNotEmpty)
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                initialValue: RecipientFilterNotifier.instance.value,
                                decoration: InputDecoration(
                                  labelText: l10n.translate('filter_by_recipient') ?? 'Filter by User',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.person),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      l10n.translate('all_users') ?? 'All',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  ..._groupMemberNames.map((name) {
                                    return DropdownMenuItem<String?>(
                                      value: name,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }),
                                ],
                                selectedItemBuilder: (BuildContext context) {
                                  return [
                                    Text(
                                      l10n.translate('all_users') ?? 'All',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    ..._groupMemberNames.map((name) {
                                      return Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      );
                                    }),
                                  ];
                                },
                                onChanged: (value) {
                                  RecipientFilterNotifier.instance.value = value;
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                
                // Currency Sum Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedCurrency == null || _selectedCurrency == 'all') ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('total_syp') ?? 'Total SYP',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                NumberFormat('#,###.##').format(sypSum),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total TRY',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                NumberFormat('#,###.##').format(trySum),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_selectedCurrency == 'SYP') ...[
                        Text(
                          l10n.translate('total_syp') ?? 'Total SYP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          NumberFormat('#,###.##').format(sypSum),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ] else if (_selectedCurrency == 'TRY') ...[
                        const Text(
                          'Total TRY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          NumberFormat('#,###.##').format(trySum),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Exchange list
                Expanded(
                  child: filteredExchanges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.currency_exchange_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.translate('no_exchanges_yet') ?? 'No exchanges yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.translate('create_first_exchange') ?? 'Create your first exchange from a transfer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredExchanges.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final exchange = filteredExchanges[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: const Icon(Icons.currency_exchange, color: Colors.white),
                                ),
                                title: Text(
                                  _getExchangeTitle(exchange),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${l10n.translate('rate') ?? 'Rate'}: 1 USD = ${NumberFormat('#,###.##').format(exchange.exchangeRate)} ${exchange.targetCurrency ?? 'SYP'}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${l10n.translate('date') ?? 'Date'}: ${DateFormat('yyyy-MM-dd').format(exchange.exchangeDate)}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isAdmin && exchange.userName != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.account_circle, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${l10n.translate('user') ?? 'User'}: ${exchange.userName}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (exchange.recipientName != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${l10n.translate('recipient') ?? 'Recipient'}: ${exchange.recipientName}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (exchange.notes != null && exchange.notes!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.note, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Notes: ${exchange.notes}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
              },
            );
          }

          return Center(
            child: Text(l10n.translate('no_data_available') ?? 'No data available'),
          );
        },
      ),
        ),
      ),
    );
  }
  
  String _getExchangeTitle(Exchange exchange) {
    final usd = exchange.amountUsd.toStringAsFixed(2);
    if (exchange.targetCurrency == 'TRY') {
      final tryAmount = exchange.amountTry ?? 0.0;
      return '\$$usd → ${NumberFormat('#,###.##').format(tryAmount)} TRY';
    } else {
      // Default to SYP
      return '\$$usd → ${NumberFormat('#,###.##').format(exchange.amountSyp)} SYP';
    }
  }
}
