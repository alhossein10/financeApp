import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/entities/transfer_type.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';
import '../../../../injection_container.dart';

/// Transfer List Page
/// Displays paginated list of transfers with filtering options
class TransferListPage extends StatefulWidget {
  final TransferType initialType;

  const TransferListPage({
    Key? key,
    this.initialType = TransferType.all,
  }) : super(key: key);

  @override
  State<TransferListPage> createState() => _TransferListPageState();
}

class _TransferListPageState extends State<TransferListPage> {
  TransferType _selectedType = TransferType.all;
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadTransfers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    final tokenManager = sl<TokenManager>();
    final userId = await tokenManager.getUserId();

    if (userId != null) {
      context.read<TransferBloc>().add(
        LoadTransfersEvent(userId, type: _selectedType),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransfers();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadTransfers();
  }

  List<Transfer> _filterByDate(List<Transfer> transfers) {
    if (_startDate == null || _endDate == null) {
      return transfers;
    }

    return transfers.where((transfer) {
      final date = transfer.transactionDate;
      return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: Column(
        children: [
          // Type filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<TransferType>(
                    segments: const [
                      ButtonSegment(
                        value: TransferType.all,
                        label: Text('All'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: TransferType.outgoing,
                        label: Text('Sent'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: TransferType.incoming,
                        label: Text('Received'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<TransferType> newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                      });
                      _loadTransfers();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Date filter indicator
          if (_startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing transfers from ${DateFormatter.formatDate(_startDate!)} to ${DateFormatter.formatDate(_endDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Transfer list
          Expanded(
            child: BlocBuilder<TransferBloc, TransferState>(
              builder: (context, state) {
                if (state is TransferLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is TransferLoaded) {
                  final filteredTransfers = _filterByDate(state.transfers);

                  if (filteredTransfers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transfers found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_startDate != null || _endDate != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearDateFilter,
                              child: const Text('Clear filter'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadTransfers(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTransfers.length,
                      itemBuilder: (context, index) {
                        final transfer = filteredTransfers[index];
                        return _TransferCard(
                          transfer: transfer,
                          type: _selectedType,
                        );
                      },
                    ),
                  );
                } else if (state is TransferError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTransfers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final Transfer transfer;
  final TransferType type;

  const _TransferCard({
    required this.transfer,
    required this.type,
  });

  bool get _isOutgoing {
    // If we're viewing outgoing transfers or all transfers,
    // check if this transfer was sent by the current user
    return type == TransferType.outgoing || type == TransferType.all;
  }

  @override
  Widget build(BuildContext context) {
    final isReceived = transfer.recipientUserId != null;
    final showDirection = type == TransferType.all;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to transfer details
          _showTransferDetails(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with direction indicator
              Row(
                children: [
                  // Direction indicator
                  if (showDirection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isOutgoing
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOutgoing
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: _isOutgoing
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isOutgoing ? 'Sent' : 'Received',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isOutgoing
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Amount
                  Text(
                    '\$${transfer.amountUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recipient info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOutgoing ? 'To' : 'From',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          transfer.recipientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (transfer.recipientUserId != null)
                          Text(
                            'User ID: ${transfer.recipientUserId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatDate(transfer.transactionDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Exchange info if available
              if (transfer.convertedAmountUsd != null &&
                  transfer.manualUsdToSypRate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_exchange,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Exchanged: ${transfer.convertedAmountUsd!.toStringAsFixed(2)} SYP @ ${transfer.manualUsdToSypRate!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              const Text(
                'Transfer Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              _DetailRow(
                icon: Icons.attach_money,
                label: 'Amount',
                value: '\$${transfer.amountUsd.toStringAsFixed(2)} USD',
                valueStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 32),

              // Recipient
              _DetailRow(
                icon: Icons.person,
                label: 'Recipient',
                value: transfer.recipientName,
              ),
              if (transfer.recipientUserId != null) ...[
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.badge,
                  label: 'Recipient ID',
                  value: transfer.recipientUserId.toString(),
                ),
              ],
              const Divider(height: 32),

              // Date
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Transfer Date',
                value: DateFormatter.formatDate(transfer.transactionDate),
              ),
              const Divider(height: 32),

              // Exchange info
              if (transfer.convertedAmountUsd != null &&
                  transfer.manualUsdToSypRate != null) ...[
                _DetailRow(
                  icon: Icons.currency_exchange,
                  label: 'Converted Amount',
                  value: '${transfer.convertedAmountUsd!.toStringAsFixed(2)} SYP',
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.trending_up,
                  label: 'Exchange Rate',
                  value: '${transfer.manualUsdToSypRate!.toStringAsFixed(2)} SYP/USD',
                ),
                const Divider(height: 32),
              ],

              // Created at
              _DetailRow(
                icon: Icons.access_time,
                label: 'Created',
                value: DateFormatter.formatDateTime(transfer.createdAt),
              ),

              // Transfer ID
              if (transfer.id != null) ...[
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.tag,
                  label: 'Transfer ID',
                  value: transfer.id.toString(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
