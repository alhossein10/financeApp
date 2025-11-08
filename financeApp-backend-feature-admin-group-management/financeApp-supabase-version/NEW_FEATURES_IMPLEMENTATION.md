# New Features Implementation Guide

## Features to Implement:

### 1. Cash Page Export (PDF)
- Add export button to Cash page
- Export filtered incoming/outgoing transactions to PDF
- Respect current filters (date, search)

### 2. Invoice Images Export (PDF)
- Add button to export all invoice images
- Combine multiple invoice images into single PDF
- One image per page with expense details

### 3. Exchange History for Transfers
- Allow editing transfer after creation
- Save each exchange as separate record
- Display exchange history under transfer card
- Track: converted amount, rate, SYP amount, date

## Implementation Status:

### ✅ Completed:
1. Created `ExchangeRecord` model
2. Updated database to v4 with `exchange_history` table
3. Added database methods for exchange CRUD
4. Created `PdfExportHelper` utility with:
   - `exportCashTransactions()` method
   - `exportInvoiceImages()` method
5. Added new translations

### ⏳ Remaining:
1. Update Cash Page UI:
   - Add export button
   - Wire up PDF export
   - Add exchange history display
   - Add "Add Exchange" button to transfers
   
2. Update Export Page:
   - Add "Export Invoice Images" button

## Code Changes Needed:

### 1. Cash Page - Add Export Button

In `lib/ui/cash_inbox_page.dart`, add import:
```dart
import '../utils/pdf_export_helper.dart';
```

Add export method:
```dart
Future<void> _exportCash() async {
  try {
    final transfers = await _transfersFuture;
    final incoming = await _incomingFuture;
    
    final filteredTransfers = _filterTransfers(transfers);
    final filteredIncoming = _filterIncoming(incoming);
    
    await PdfExportHelper.exportCashTransactions(
      transfers: filteredTransfers,
      incoming: filteredIncoming,
      title: 'معاملات النقد',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

Add button in AppBar actions:
```dart
appBar: AppBar(
  title: Text(l10n.translate('app_title')),
  actions: [
    IconButton(
      icon: const Icon(Icons.picture_as_pdf),
      onPressed: _exportCash,
      tooltip: l10n.translate('export_cash'),
    ),
  ],
),
```

### 2. Exchange History - Add to Transfer Card

Add method to show exchange history dialog:
```dart
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
                children: exchanges.map((e) => ListTile(
                  title: Text('${e.convertedAmountUsd.toStringAsFixed(2)} USD'),
                  subtitle: Text(
                    'Rate: ${e.manualUsdToSypRate?.toStringAsFixed(0) ?? '-'} → ${e.amountSypAtExchange?.toStringAsFixed(0) ?? '-'} SYP',
                  ),
                  trailing: Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}'),
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
```

Add method to add new exchange:
```dart
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
```

Update transfer card menu to include exchange options:
```dart
PopupMenuButton<String>(
  onSelected: (value) async {
    if (value == 'add_exchange') {
      await _addExchange(context, t);
    } else if (value == 'view_history') {
      await _showExchangeHistory(context, t);
    } else if (value == 'refund_delete') {
      await _db.deleteTransfer(t.id!, refund: true);
      setState(_reload);
    } else if (value == 'delete') {
      await _db.deleteTransfer(t.id!, refund: false);
      setState(_reload);
    }
  },
  itemBuilder: (ctx) => [
    PopupMenuItem(value: 'add_exchange', child: Text(l10n.translate('add_exchange'))),
    PopupMenuItem(value: 'view_history', child: Text(l10n.translate('exchange_history'))),
    PopupMenuItem(value: 'refund_delete', child: Text(l10n.translate('refund_delete'))),
    PopupMenuItem(value: 'delete', child: Text(l10n.translate('delete'))),
  ],
),
```

### 3. Export Page - Add Invoice Images Export

In `lib/ui/export_page.dart`, add import:
```dart
import '../utils/pdf_export_helper.dart';
```

Add method:
```dart
Future<void> _exportInvoiceImages() async {
  setState(() => _busy = true);
  try {
    final expenses = await _db.listExpenses();
    await PdfExportHelper.exportInvoiceImages(expenses);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) setState(() => _busy = false);
  }
}
```

Add button in UI:
```dart
FilledButton.icon(
  onPressed: _busy ? null : _exportInvoiceImages,
  icon: const Icon(Icons.image),
  label: Text(l10n.translate('export_invoices')),
),
```

## Files Modified:
1. ✅ `lib/models/exchange_record.dart` - NEW
2. ✅ `lib/data/db.dart` - Updated to v4
3. ✅ `lib/l10n/app_localizations.dart` - Added translations
4. ✅ `lib/utils/pdf_export_helper.dart` - NEW
5. ⏳ `lib/ui/cash_inbox_page.dart` - Needs updates
6. ⏳ `lib/ui/export_page.dart` - Needs updates

## Testing Checklist:
- [ ] Cash page export button works
- [ ] PDF includes filtered transactions
- [ ] Add exchange to transfer works
- [ ] Exchange history displays correctly
- [ ] Multiple exchanges tracked per transfer
- [ ] Invoice images export works
- [ ] Multiple images combined in one PDF
- [ ] All Arabic text displays correctly
