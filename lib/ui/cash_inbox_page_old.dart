import 'package:flutter/material.dart';

import '../data/db.dart';
import '../l10n/app_localizations.dart';
import '../models/fund_box.dart';
import '../models/transfer.dart';

class CashInboxPage extends StatefulWidget {
  const CashInboxPage({super.key});

  @override
  State<CashInboxPage> createState() => _CashInboxPageState();
}

class _CashInboxPageState extends State<CashInboxPage> {
  final AppDatabase _db = AppDatabase();
  late Future<FundBox> _fundFuture;
  late Future<List<TransferRecord>> _transfersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _fundFuture = _db.getFundBox();
    _transfersFuture = _db.listTransfers();
  }

  Future<void> _setFundBalance(BuildContext context) async {
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
    if (newValue != null) {
      await _db.setFundBalanceUsd(newValue);
      setState(_reload);
    }
  }

  Future<void> _createTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final convertedUsdController = TextEditingController();
    final rateController = TextEditingController();
    final convertedTotalSypController = TextEditingController();

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
      builder: (ctx) => AlertDialog(
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
    );

    if (result == true) {
      final name = nameController.text.trim();
      final amount = double.tryParse(amountController.text.trim());
      final convertedAmount = double.tryParse(convertedUsdController.text.trim()) ?? 0.0;
      final rate = double.tryParse(rateController.text.trim());
      final sypAmount = double.tryParse(convertedTotalSypController.text.trim());
      if (name.isEmpty || amount == null) return;

      // Validate that converted amount doesn't exceed total amount
      if (convertedAmount > amount) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('converted_amount_error'))),
          );
        }
        return;
      }

      try {
        await _db.createTransfer(
          recipientName: name,
          amountUsd: amount,
          convertedAmountUsd: convertedAmount,
          amountSypAtExchange: sypAmount,
          manualUsdToSypRate: rate,
        );
        setState(_reload);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return RefreshIndicator(
      onRefresh: () async => setState(_reload),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<FundBox>(
            future: _fundFuture,
            builder: (context, snapshot) {
              final balance = snapshot.data?.balanceUsd ?? 0;
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
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => _createTransfer(context),
                icon: const Icon(Icons.call_made),
                label: Text(l10n.translate('transfer')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.translate('transfers'), style: const TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<TransferRecord>>(
            future: _transfersFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <TransferRecord>[];
              return Column(
                children: items
                    .map((t) {
                      // Calculate actual USD transferred (total - converted)
                      final actualUsdTransferred = t.amountUsd - (t.convertedAmountUsd ?? 0.0);
                      final convertedAmount = t.convertedAmountUsd ?? 0.0;
                      
                      // Build subtitle with converted info
                      String subtitle = '';
                      if (convertedAmount > 0 && t.amountSypAtExchange != null) {
                        subtitle = '${l10n.translate('converted_amount')}: ${convertedAmount.toStringAsFixed(2)} ${l10n.translate('usd')} → ${t.amountSypAtExchange!.toStringAsFixed(0)} ${l10n.translate('syp')}';
                      } else if (t.amountSypAtExchange != null) {
                        subtitle = '${l10n.translate('syp')}: ${t.amountSypAtExchange!.toStringAsFixed(0)}';
                      } else {
                        subtitle = l10n.translate('no_syp_recorded');
                      }
                      
                      return Card(
                          child: ListTile(
                            title: Text('${t.recipientName} • ${actualUsdTransferred.toStringAsFixed(2)} ${l10n.translate('usd')}'),
                            subtitle: Text(subtitle),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final convertedUsdCtrl = TextEditingController(text: t.convertedAmountUsd?.toString() ?? '');
                                  final rateCtrl = TextEditingController(text: t.manualUsdToSypRate?.toString() ?? '');
                                  final convertedTotalSypCtrl = TextEditingController(text: t.amountSypAtExchange?.toString() ?? '');
                                  
                                  void recomputeEdit() {
                                    final rate = double.tryParse(rateCtrl.text.trim());
                                    final convertedUsd = double.tryParse(convertedUsdCtrl.text.trim());
                                    if (rate != null && convertedUsd != null) {
                                      convertedTotalSypCtrl.text = (rate * convertedUsd).toStringAsFixed(0);
                                    } else {
                                      convertedTotalSypCtrl.text = '';
                                    }
                                  }
                                  
                                  rateCtrl.addListener(recomputeEdit);
                                  convertedUsdCtrl.addListener(recomputeEdit);
                                  
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.translate('edit_transfer_conversion')),
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
                                  if (ok == true) {
                                    final newConvertedAmount = double.tryParse(convertedUsdCtrl.text.trim()) ?? 0.0;
                                    
                                    // Validate that converted amount doesn't exceed total transfer amount
                                    if (newConvertedAmount > t.amountUsd) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.translate('converted_amount_error'))),
                                        );
                                      }
                                      return;
                                    }
                                    
                                    final updated = t.copyWith(
                                      convertedAmountUsd: newConvertedAmount,
                                      manualUsdToSypRate: double.tryParse(rateCtrl.text.trim()),
                                      amountSypAtExchange: double.tryParse(convertedTotalSypCtrl.text.trim()),
                                    );
                                    await _db.updateTransfer(updated);
                                    setState(_reload);
                                  }
                                } else if (value == 'refund_delete') {
                                  await _db.deleteTransfer(t.id!, refund: true);
                                  setState(_reload);
                                } else if (value == 'delete') {
                                  await _db.deleteTransfer(t.id!, refund: false);
                                  setState(_reload);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: 'edit', child: Text(l10n.translate('edit_conversion'))),
                                PopupMenuItem(value: 'refund_delete', child: Text(l10n.translate('refund_delete'))),
                                PopupMenuItem(value: 'delete', child: Text(l10n.translate('delete'))),
                              ],
                            ),
                          ),
                        );
                    })
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}


