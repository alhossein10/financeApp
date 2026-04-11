import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
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

/// SuperAdmin Transfers List Page
/// 
/// Features:
/// - Display outgoing transfers to Admins
/// - Create new transfer button
/// - Filter by recipient Admin
/// - Filter by date range
/// - Export to PDF button (applies active filters)
class SuperAdminTransfersListPage extends StatefulWidget {
  const SuperAdminTransfersListPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminTransfersListPage> createState() => _SuperAdminTransfersListPageState();
}

class _SuperAdminTransfersListPageState extends State<SuperAdminTransfersListPage> {
  List<AdminMemberDto> _adminMembers = [];
  bool _isLoadingMembers = true;
  String? _errorMessage;
  
  // Filters
  int? _selectedRecipientId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAdminMembers();
    _loadTransfers();
    _loadFundBox();
  }

  void _loadFundBox() {
    context.read<FundBoxBloc>().add(LoadFundBoxEvent());
  }

  void _loadTransfers() {
    context.read<TransferBloc>().add(
      LoadTransfersEvent(
        page: _currentPage,
        startDate: _startDate,
        endDate: _endDate,
        recipientUserId: _selectedRecipientId,
      ),
    );
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

  Future<void> _showCreateTransferDialog() async {
    if (_adminMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('transfers.no_recipients')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get current balance from FundBoxBloc
    final fundBoxState = context.read<FundBoxBloc>().state;
    double currentBalance = 0.0;
    
    if (fundBoxState is FundBoxLoaded) {
      currentBalance = fundBoxState.fundBox.balanceUsd;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('transfers.create_transfer')),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: TransferForm(
              flavor: AppFlavor.superAdmin,
              recipients: _adminMembers,
              currentUsdBalance: currentBalance,
              onSubmit: (transfer) async {
                Navigator.of(dialogContext).pop(true);
                await _submitTransfer(transfer);
              },
              onCancel: () => Navigator.of(dialogContext).pop(false),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _refreshTransfers();
      _loadFundBox();
    }
  }

  Future<void> _submitTransfer(TransferDto transfer) async {
    final tokenManager = sl<TokenManager>();
    final userId = await tokenManager.getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('errors.not_authenticated')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TransferBloc>().add(
      CreateTransferEvent(
        userId: userId,
        recipientName: transfer.recipientName,
        recipientUserId: transfer.recipientUserId!,
        adminGroupId: transfer.adminGroupId,
        amountUsd: transfer.amountUsd,
        transactionDate: DateFormatter.fromApiDate(transfer.transferDate),
        notes: transfer.notes,
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    int? tempRecipientId = _selectedRecipientId;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('filters.title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Recipient filter
                DropdownButtonFormField<int?>(
                  value: tempRecipientId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('transfers.recipient'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(AppLocalizations.of(context)!.translate('filters.all')),
                    ),
                    ..._adminMembers.map((admin) {
                      return DropdownMenuItem<int?>(
                        value: admin.id,
                        child: Text(admin.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempRecipientId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Start date
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('filters.start_date')),
                  subtitle: Text(
                    tempStartDate != null
                        ? DateFormatter.formatDate(tempStartDate!)
                        : AppLocalizations.of(context)!.translate('filters.not_set'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setDialogState(() {
                        tempStartDate = null;
                      });
                    },
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tempStartDate = picked;
                      });
                    }
                  },
                ),

                // End date
                ListTile(
                  title: Text(AppLocalizations.of(context)!.translate('filters.end_date')),
                  subtitle: Text(
                    tempEndDate != null
                        ? DateFormatter.formatDate(tempEndDate!)
                        : AppLocalizations.of(context)!.translate('filters.not_set'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setDialogState(() {
                        tempEndDate = null;
                      });
                    },
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tempEndDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedRecipientId = null;
                });
                Navigator.of(dialogContext).pop();
                _refreshTransfers();
              },
              child: Text(AppLocalizations.of(context)!.translate('filters.clear')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                  _selectedRecipientId = tempRecipientId;
                });
                Navigator.of(dialogContext).pop();
                _refreshTransfers();
              },
              child: Text(AppLocalizations.of(context)!.translate('filters.apply')),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToPdf() {
    // TODO: Implement PDF export with applied filters
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('export.pdf_coming_soon')),
        backgroundColor: Colors.blue,
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedRecipientId != null) count++;
    if (_startDate != null) count++;
    if (_endDate != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('transfers.title')),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_getActiveFilterCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Export button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: l10n.translate('export.to_pdf'),
          ),
        ],
      ),
      body: BlocListener<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.translate('transfers.created_successfully')),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TransferError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshTransfers();
          },
          child: BlocBuilder<TransferBloc, TransferState>(
            builder: (context, state) {
              if (state is TransferLoading && _currentPage == 1) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TransferError && _currentPage == 1) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshTransfers,
                        child: Text(l10n.translate('retry')),
                      ),
                    ],
                  ),
                );
              }

              if (state is TransfersLoaded) {
                if (state.transfers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('transfers.no_transfers'),
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.transfers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final transfer = state.transfers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.arrow_upward,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          transfer.recipientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(DateFormatter.formatDate(transfer.transactionDate)),
                            if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                transfer.notes!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: Text(
                          '\$${transfer.amountUsd.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingMembers ? null : _showCreateTransferDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('transfers.create_transfer')),
      ),
    );
  }
}
