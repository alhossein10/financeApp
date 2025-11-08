# Exchange Feature Integration Guide

## Quick Start

This guide shows you how to integrate the Exchange feature into your app's navigation and UI.

## Step 1: Add to Navigation Drawer (Optional)

If you have a navigation drawer, add an exchange history menu item:

```dart
// In your drawer widget
ListTile(
  leading: const Icon(Icons.currency_exchange),
  title: const Text('Exchange History'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<ExchangeBloc>(),
          child: const ExchangeHistoryPage(),
        ),
      ),
    );
  },
),
```

## Step 2: Add Exchange Button to Transfer Pages

### Option A: In Transfer List Page

Add an exchange icon button to each transfer item:

```dart
// In your transfer list item widget
ListTile(
  title: Text(transfer.recipientName),
  subtitle: Text('\$${transfer.amountUsd.toStringAsFixed(2)}'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.currency_exchange),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<ExchangeBloc>(),
                child: CreateExchangePage(transfer: transfer),
              ),
            ),
          );
        },
        tooltip: 'Create Exchange',
      ),
      // ... other buttons
    ],
  ),
)
```

### Option B: In Transfer Detail Page

Add a prominent exchange button:

```dart
// In your transfer detail page
Column(
  children: [
    // ... transfer details
    
    const SizedBox(height: 16),
    
    ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => di.sl<ExchangeBloc>(),
              child: CreateExchangePage(transfer: transfer),
            ),
          ),
        );
      },
      icon: const Icon(Icons.currency_exchange),
      label: const Text('Create Exchange'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    
    // Show exchange history for this transfer
    TextButton.icon(
      onPressed: () {
        // Navigate to filtered exchange history
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => di.sl<ExchangeBloc>()
                ..add(LoadExchangesByTransferEvent(transfer.id!)),
              child: const ExchangeHistoryPage(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text('View Exchange History'),
    ),
  ],
)
```

## Step 3: Add Required Imports

Make sure to add these imports where needed:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/features/exchanges/presentation/pages/create_exchange_page.dart';
import 'package:finance_app/features/exchanges/presentation/pages/exchange_history_page.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_event.dart';
import 'package:finance_app/injection_container.dart' as di;
```

## Step 4: Add to Main Menu (Optional)

If you have a main menu or dashboard, add an exchange card:

```dart
// In your dashboard or home page
GridView.count(
  crossAxisCount: 2,
  children: [
    // ... other menu items
    
    Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => di.sl<ExchangeBloc>(),
                child: const ExchangeHistoryPage(),
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.currency_exchange, size: 48),
            SizedBox(height: 8),
            Text('Exchanges'),
          ],
        ),
      ),
    ),
  ],
)
```

## Step 5: Add Localization (Optional)

If your app supports multiple languages, add these keys to your localization files:

```dart
// In your localization file (e.g., app_en.arb)
{
  "exchange_history": "Exchange History",
  "create_exchange": "Create Exchange",
  "exchange_rate": "Exchange Rate",
  "amount_usd": "Amount (USD)",
  "amount_syp": "Amount (SYP)",
  "exchange_date": "Exchange Date",
  "transfer_balance": "Transfer Balance",
  "original_amount": "Original Amount",
  "total_exchanged": "Total Exchanged",
  "remaining_balance": "Remaining Balance",
  "you_will_receive": "You will receive",
  "exchange_created_successfully": "Exchange created successfully!",
  "no_exchanges_yet": "No exchanges yet",
  "insufficient_balance": "Amount exceeds available balance",
  "enter_exchange_rate": "Enter today's exchange rate",
  "notes_optional": "Notes (Optional)"
}
```

## Step 6: Test the Integration

1. **Test Navigation**
   - Verify all navigation paths work correctly
   - Check that BLoC is properly provided
   - Ensure back navigation works

2. **Test Create Exchange**
   - Open create exchange from transfer list
   - Verify balance loads correctly
   - Test form validation
   - Create a test exchange

3. **Test Exchange History**
   - Open exchange history from menu
   - Verify exchanges are displayed
   - Test refresh functionality

## Example: Complete Transfer Detail Page with Exchange

Here's a complete example of a transfer detail page with exchange integration:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/models/transfer.dart';
import 'package:finance_app/features/exchanges/presentation/pages/create_exchange_page.dart';
import 'package:finance_app/features/exchanges/presentation/pages/exchange_history_page.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_event.dart';
import 'package:finance_app/injection_container.dart' as di;

class TransferDetailPage extends StatelessWidget {
  final Transfer transfer;

  const TransferDetailPage({Key? key, required this.transfer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient: ${transfer.recipientName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Amount: \$${transfer.amountUsd.toStringAsFixed(2)}'),
                    Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(transfer.transactionDate)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exchange Actions
            const Text(
              'Exchange Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Create Exchange Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => di.sl<ExchangeBloc>(),
                      child: CreateExchangePage(transfer: transfer),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Create Exchange'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),

            // View Exchange History Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => di.sl<ExchangeBloc>()
                        ..add(LoadExchangesByTransferEvent(transfer.id!)),
                      child: const ExchangeHistoryPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View Exchange History'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Issue: BLoC not found
**Solution**: Make sure you're wrapping the page with `BlocProvider` and using `di.sl<ExchangeBloc>()`

### Issue: Transfer model not compatible
**Solution**: The Transfer model should have an `id` field. Check `lib/models/transfer.dart`

### Issue: Navigation not working
**Solution**: Verify all imports are correct and the pages are in the correct paths

### Issue: API errors
**Solution**: Check that the backend API is running and the endpoints match the documentation

## Next Steps

1. Test the integration thoroughly
2. Add analytics tracking for exchange events
3. Consider adding exchange notifications
4. Implement exchange statistics dashboard
5. Add export functionality for exchange reports

## Support

If you encounter any issues:
1. Check the console for error messages
2. Verify all dependencies are registered in `injection_container.dart`
3. Review `EXCHANGE_FEATURE_IMPLEMENTATION.md` for detailed information
4. Test API endpoints using the Postman collection
