# Balance Verification Service Usage Guide

## Overview

The `BalanceVerificationService` provides client-side balance verification before financial operations to prevent operations that would result in negative balances. This service integrates with the FundBox API to retrieve current balances and verify sufficient funds are available.

## Requirements Addressed

- **21.1**: Verify sufficient balance before creating expenses
- **21.2**: Verify sufficient balance before creating transfers
- **21.3**: Verify sufficient balance before creating exchanges
- **21.4**: Reject operations immediately if balance is insufficient
- **21.5**: Display clear error messages with current balance

## Features

- ✅ Verify single currency balance
- ✅ Verify multiple currency balances at once
- ✅ Get current balances for all currencies (USD, SYP, TRY)
- ✅ Support for calculated balances (real-time from transactions)
- ✅ Support for checking other users' balances (Admin/Superadmin)
- ✅ Clear error messages with InsufficientBalanceException
- ✅ Automatic currency code normalization (handles lowercase)

## Installation

The service is automatically registered in the dependency injection container:

```dart
// In injection_container.dart
sl.registerLazySingleton<BalanceVerificationService>(
  () => BalanceVerificationService(fundBoxApiDataSource: sl()),
);
```

## Basic Usage

### 1. Verify Single Currency Balance

```dart
import 'package:finance_app/core/services/balance_verification_service.dart';
import 'package:finance_app/core/exceptions/insufficient_balance_exception.dart';

// Inject the service
final balanceVerificationService = sl<BalanceVerificationService>();

// Verify balance before creating an expense
try {
  await balanceVerificationService.verifyBalance(
    currency: 'USD',
    amount: 100.0,
    context: 'expense creation',
  );
  
  // Balance is sufficient, proceed with operation
  await createExpense(...);
  
} on InsufficientBalanceException catch (e) {
  // Show error to user
  showErrorDialog(
    title: 'Insufficient Balance',
    message: e.message,
    // Message format: "Insufficient USD balance (expense creation). Required: 100.00, Available: 50.00"
  );
} on ApiException catch (e) {
  // Handle API errors
  showErrorDialog(
    title: 'Error',
    message: e.message,
  );
}
```

### 2. Get Current Balances

```dart
try {
  final balances = await balanceVerificationService.getCurrentBalances();
  
  print('USD: \$${balances['USD']}');
  print('SYP: ${balances['SYP']} SYP');
  print('TRY: ${balances['TRY']} TRY');
  
} on ApiException catch (e) {
  print('Error fetching balances: ${e.message}');
}
```

### 3. Verify Multiple Currencies

Useful for operations that affect multiple currencies:

```dart
try {
  await balanceVerificationService.verifyMultipleBalances(
    amounts: {
      'USD': 50.0,
      'SYP': 100000.0,
    },
    context: 'multi-currency operation',
  );
  
  // All balances are sufficient
  await performMultiCurrencyOperation(...);
  
} on InsufficientBalanceException catch (e) {
  // Shows the first insufficient balance found
  showErrorDialog(
    title: 'Insufficient Balance',
    message: e.message,
  );
}
```

### 4. Verify Calculated Balance

Use real-time calculation from transactions instead of stored balance:

```dart
try {
  await balanceVerificationService.verifyCalculatedBalance(
    currency: 'USD',
    amount: 100.0,
    context: 'transfer creation',
  );
  
  // Calculated balance is sufficient
  await createTransfer(...);
  
} on InsufficientBalanceException catch (e) {
  showErrorDialog(
    title: 'Insufficient Balance',
    message: e.message,
  );
}
```

### 5. Check Other Users' Balances (Admin/Superadmin)

```dart
// Admin checking a user's balance
try {
  await balanceVerificationService.verifyBalance(
    currency: 'USD',
    amount: 100.0,
    userId: 123, // User ID to check
    context: 'admin transfer verification',
  );
  
  // User has sufficient balance
  await createTransferToUser(userId: 123, ...);
  
} on InsufficientBalanceException catch (e) {
  showErrorDialog(
    title: 'User Has Insufficient Balance',
    message: e.message,
  );
}
```

## Integration Examples

### Expense Creation

```dart
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final BalanceVerificationService _balanceVerificationService;
  final CreateExpenseUseCase _createExpenseUseCase;
  
  Future<void> _onCreateExpense(
    CreateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    
    try {
      // Verify balance before creating expense
      await _balanceVerificationService.verifyBalance(
        currency: event.currency,
        amount: event.amount,
        context: 'expense creation',
      );
      
      // Balance is sufficient, create expense
      final expense = await _createExpenseUseCase(event.expenseData);
      
      emit(ExpenseCreated(expense));
      
    } on InsufficientBalanceException catch (e) {
      emit(ExpenseError(e.message));
    } on ApiException catch (e) {
      emit(ExpenseError(e.message));
    }
  }
}
```

### Transfer Creation

```dart
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final BalanceVerificationService _balanceVerificationService;
  final CreateTransferUseCase _createTransferUseCase;
  
  Future<void> _onCreateTransfer(
    CreateTransferEvent event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    
    try {
      // Verify USD balance (transfers are always in USD)
      await _balanceVerificationService.verifyBalance(
        currency: 'USD',
        amount: event.amount,
        context: 'transfer creation',
      );
      
      // Balance is sufficient, create transfer
      final transfer = await _createTransferUseCase(event.transferData);
      
      emit(TransferCreated(transfer));
      
    } on InsufficientBalanceException catch (e) {
      emit(TransferError(e.message));
    } on ApiException catch (e) {
      emit(TransferError(e.message));
    }
  }
}
```

### Exchange Creation

```dart
class ExchangeBloc extends Bloc<ExchangeEvent, ExchangeState> {
  final BalanceVerificationService _balanceVerificationService;
  final CreateExchangeUseCase _createExchangeUseCase;
  
  Future<void> _onCreateExchange(
    CreateExchangeEvent event,
    Emitter<ExchangeState> emit,
  ) async {
    emit(ExchangeLoading());
    
    try {
      // Verify USD balance (exchanges always deduct from USD)
      await _balanceVerificationService.verifyBalance(
        currency: 'USD',
        amount: event.amountUsd,
        context: 'currency exchange',
      );
      
      // Balance is sufficient, create exchange
      final exchange = await _createExchangeUseCase(event.exchangeData);
      
      emit(ExchangeCreated(exchange));
      
    } on InsufficientBalanceException catch (e) {
      emit(ExchangeError(e.message));
    } on ApiException catch (e) {
      emit(ExchangeError(e.message));
    }
  }
}
```

## Error Handling

### InsufficientBalanceException

The exception provides detailed information about the balance shortage:

```dart
class InsufficientBalanceException {
  final String currency;      // 'USD', 'SYP', or 'TRY'
  final double required;       // Amount required for operation
  final double available;      // Current available balance
  final String? context;       // Optional context (e.g., 'expense creation')
  
  String get message;          // Formatted error message
}
```

Example error messages:
- `"Insufficient USD balance. Required: 500.00, Available: 100.00"`
- `"Insufficient USD balance (expense creation). Required: 500.00, Available: 100.00"`

### Displaying Errors to Users

```dart
void showBalanceError(InsufficientBalanceException e) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Insufficient ${e.currency} Balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Required: ${e.required.toStringAsFixed(2)} ${e.currency}'),
          Text('Available: ${e.available.toStringAsFixed(2)} ${e.currency}'),
          if (e.context != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Operation: ${e.context}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Best Practices

### 1. Always Verify Before Operations

```dart
// ✅ GOOD: Verify before operation
await balanceVerificationService.verifyBalance(...);
await createExpense(...);

// ❌ BAD: Create without verification
await createExpense(...); // May fail on backend
```

### 2. Provide Context

```dart
// ✅ GOOD: Provide context for better error messages
await balanceVerificationService.verifyBalance(
  currency: 'USD',
  amount: 100.0,
  context: 'expense creation',
);

// ⚠️ OK: Works but less informative
await balanceVerificationService.verifyBalance(
  currency: 'USD',
  amount: 100.0,
);
```

### 3. Handle Both Exception Types

```dart
// ✅ GOOD: Handle both insufficient balance and API errors
try {
  await balanceVerificationService.verifyBalance(...);
} on InsufficientBalanceException catch (e) {
  // Handle insufficient balance
} on ApiException catch (e) {
  // Handle API errors
}

// ❌ BAD: Only catch one type
try {
  await balanceVerificationService.verifyBalance(...);
} catch (e) {
  // Generic catch loses type information
}
```

### 4. Use Calculated Balance for Critical Operations

```dart
// ✅ GOOD: Use calculated balance for important operations
await balanceVerificationService.verifyCalculatedBalance(
  currency: 'USD',
  amount: largeAmount,
  context: 'large transfer',
);

// ⚠️ OK: Regular balance is fine for most operations
await balanceVerificationService.verifyBalance(
  currency: 'USD',
  amount: smallAmount,
);
```

## Testing

The service is fully tested with comprehensive unit tests. See `test/core/services/balance_verification_service_test.dart` for examples.

### Mock Usage in Tests

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FundBoxApiDataSource])
import 'your_test.mocks.dart';

void main() {
  late BalanceVerificationService service;
  late MockFundBoxApiDataSource mockDataSource;
  
  setUp(() {
    mockDataSource = MockFundBoxApiDataSource();
    service = BalanceVerificationService(
      fundBoxApiDataSource: mockDataSource,
    );
  });
  
  test('should verify balance successfully', () async {
    // Arrange
    when(mockDataSource.getFundBox()).thenAnswer(
      (_) async => FundBoxDto(
        id: 1,
        balanceUsd: 1000.0,
        balanceSyp: 50000.0,
        balanceTry: 30000.0,
        lastUpdated: DateTime.now(),
      ),
    );
    
    // Act
    final result = await service.verifyBalance(
      currency: 'USD',
      amount: 500.0,
    );
    
    // Assert
    expect(result, true);
  });
}
```

## API Integration

The service integrates with the following FundBox API endpoints:

- `GET /api/v1/fund-box` - Get current balances
- `GET /api/v1/fund-box?user_id={id}` - Get user balances (Admin/Superadmin)
- `GET /api/v1/calculated-balance` - Get calculated balances

## Performance Considerations

- The service makes API calls to fetch balances, so consider caching if checking multiple times
- Use `getCurrentBalances()` once and check multiple currencies locally if needed
- The `verifyMultipleBalances()` method makes only one API call for all currencies

## Future Enhancements

Potential improvements for future versions:

1. **Local Caching**: Cache balances for a short period to reduce API calls
2. **Optimistic Updates**: Track pending operations to adjust available balance
3. **Batch Verification**: Verify multiple operations at once
4. **Balance Alerts**: Notify users when balance is low
5. **Transaction History**: Show recent transactions affecting balance

## Support

For issues or questions about the Balance Verification Service:

1. Check the test file for usage examples
2. Review the API documentation for FundBox endpoints
3. Consult the design document for architectural decisions
4. Contact the development team for assistance
