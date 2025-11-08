# Exchange Feature - Quick Reference Card

## 🚀 Quick Start

### Import Required Packages
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/features/exchanges/presentation/pages/create_exchange_page.dart';
import 'package:finance_app/features/exchanges/presentation/pages/exchange_history_page.dart';
import 'package:finance_app/features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'package:finance_app/injection_container.dart' as di;
```

### Navigate to Create Exchange
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => di.sl<ExchangeBloc>(),
      child: CreateExchangePage(transfer: transfer),
    ),
  ),
);
```

### Navigate to Exchange History
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => di.sl<ExchangeBloc>(),
      child: const ExchangeHistoryPage(),
    ),
  ),
);
```

## 📊 Data Models

### Exchange Entity
```dart
Exchange(
  id: 1,
  transferId: 5,
  amountUsd: 100.0,
  exchangeRate: 11600.0,
  amountSyp: 1160000.0,
  exchangeDate: DateTime(2025, 11, 2),
  notes: 'Optional notes',
  recipientName: 'John Doe',
)
```

### Transfer Balance
```dart
TransferBalance(
  transferId: 5,
  originalAmount: 500.0,
  totalExchanged: 150.0,
  remainingBalance: 350.0,
  recipientName: 'John Doe',
  transferDate: DateTime(2025, 11, 1),
)
```

## 🎯 BLoC Events

### Create Exchange
```dart
context.read<ExchangeBloc>().add(
  CreateExchangeEvent(
    transferId: 5,
    amountUsd: 100.0,
    exchangeRate: 11600.0,
    exchangeDate: DateTime.now(),
    notes: 'Optional',
  ),
);
```

### Load All Exchanges
```dart
context.read<ExchangeBloc>().add(const LoadAllExchangesEvent());
```

### Load Exchanges by Transfer
```dart
context.read<ExchangeBloc>().add(LoadExchangesByTransferEvent(transferId));
```

### Load Transfer Balance
```dart
context.read<ExchangeBloc>().add(LoadTransferBalanceEvent(transferId));
```

### Reset State
```dart
context.read<ExchangeBloc>().add(const ResetExchangeStateEvent());
```

## 📱 BLoC States

### Initial
```dart
ExchangeInitial()
```

### Loading
```dart
ExchangeLoading()
```

### Exchange Created
```dart
ExchangeCreated(exchange)
```

### Exchanges Loaded
```dart
ExchangesLoaded(exchanges)
```

### Balance Loaded
```dart
TransferBalanceLoaded(balance)
```

### Error
```dart
ExchangeError(message)
```

## 🔧 Common Patterns

### Listen to State Changes
```dart
BlocListener<ExchangeBloc, ExchangeState>(
  listener: (context, state) {
    if (state is ExchangeCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exchange created!')),
      );
    } else if (state is ExchangeError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  },
  child: YourWidget(),
)
```

### Build UI Based on State
```dart
BlocBuilder<ExchangeBloc, ExchangeState>(
  builder: (context, state) {
    if (state is ExchangeLoading) {
      return const CircularProgressIndicator();
    }
    if (state is ExchangesLoaded) {
      return ListView.builder(
        itemCount: state.exchanges.length,
        itemBuilder: (context, index) {
          final exchange = state.exchanges[index];
          return ListTile(
            title: Text('\$${exchange.amountUsd}'),
            subtitle: Text('${exchange.amountSyp} SYP'),
          );
        },
      );
    }
    return const Text('No data');
  },
)
```

### Combined Listener and Builder
```dart
BlocConsumer<ExchangeBloc, ExchangeState>(
  listener: (context, state) {
    // Handle side effects
  },
  builder: (context, state) {
    // Build UI
  },
)
```

## 🎨 UI Components

### Add Exchange Button
```dart
ElevatedButton.icon(
  onPressed: () => _navigateToCreateExchange(),
  icon: const Icon(Icons.currency_exchange),
  label: const Text('Create Exchange'),
)
```

### Exchange List Item
```dart
Card(
  child: ListTile(
    leading: const CircleAvatar(
      child: Icon(Icons.currency_exchange),
    ),
    title: Text('\$${exchange.amountUsd} → ${exchange.amountSyp} SYP'),
    subtitle: Text('Rate: ${exchange.exchangeRate}'),
  ),
)
```

### Balance Display
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Original: \$${balance.originalAmount}'),
        Text('Exchanged: \$${balance.totalExchanged}'),
        Text('Remaining: \$${balance.remainingBalance}'),
      ],
    ),
  ),
)
```

## 🔢 Number Formatting

### Format USD
```dart
'\$${amount.toStringAsFixed(2)}'  // $100.00
```

### Format SYP
```dart
import 'package:intl/intl.dart';

NumberFormat('#,###.##').format(amount)  // 1,160,000.00
```

### Format Exchange Rate
```dart
NumberFormat('#,###.##').format(rate)  // 11,600.00
```

## 📅 Date Formatting

### Format Date for Display
```dart
import 'package:intl/intl.dart';

DateFormat('yyyy-MM-dd').format(date)  // 2025-11-02
```

### Format Date for API
```dart
import 'package:finance_app/core/utils/date_formatter.dart';

DateFormatter.toApiDate(date)  // 2025-11-02
```

## ✅ Validation

### Amount Validation
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter amount';
  }
  final amount = double.tryParse(value);
  if (amount == null || amount <= 0) {
    return 'Please enter valid amount';
  }
  if (amount > remainingBalance) {
    return 'Amount exceeds available balance';
  }
  return null;
}
```

### Exchange Rate Validation
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter exchange rate';
  }
  final rate = double.tryParse(value);
  if (rate == null || rate <= 0) {
    return 'Please enter valid rate';
  }
  return null;
}
```

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /exchanges | Create exchange |
| GET | /exchanges | Get all exchanges |
| GET | /exchanges/{id} | Get exchange by ID |
| GET | /exchanges/transfer/{id} | Get exchanges by transfer |
| GET | /exchanges/transfer/{id}/balance | Get transfer balance |

## 🔐 Permissions

- **Regular Users**: Own exchanges only
- **Admins**: All exchanges in their group

## 🐛 Common Issues

### BLoC Not Found
```dart
// ❌ Wrong
CreateExchangePage(transfer: transfer)

// ✅ Correct
BlocProvider(
  create: (context) => di.sl<ExchangeBloc>(),
  child: CreateExchangePage(transfer: transfer),
)
```

### State Not Updating
```dart
// Make sure to dispatch events
context.read<ExchangeBloc>().add(LoadAllExchangesEvent());
```

### Navigation Not Working
```dart
// Check imports
import 'package:finance_app/injection_container.dart' as di;
```

## 📚 Documentation Files

- `EXCHANGE_FEATURE_FLUTTER_GUIDE.md` - API specification
- `EXCHANGE_FEATURE_IMPLEMENTATION.md` - Implementation details
- `EXCHANGE_FEATURE_INTEGRATION_GUIDE.md` - Integration examples
- `EXCHANGE_FEATURE_READY.md` - Completion summary
- `Finance-API-Complete-v2.postman_collection.json` - API testing

## 🎯 Testing Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/features/exchanges/
```

### Check for Issues
```bash
flutter analyze
```

## 💡 Tips

1. Always wrap pages with `BlocProvider`
2. Use `BlocConsumer` for both listening and building
3. Reset state when leaving pages if needed
4. Format large SYP numbers with thousand separators
5. Validate balance before allowing exchange
6. Show loading indicators during API calls
7. Handle errors gracefully with user-friendly messages

## 🚀 Ready to Use!

The exchange feature is fully implemented and ready for integration. Just add navigation to your app and start using it!
