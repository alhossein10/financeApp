# Usage Examples - Postman API v3.1 Integration

## Overview

This document provides practical usage examples for all major features implemented in the Postman API v3.1 integration, including SuperAdmin features, multi-currency expenses, balance-based exchanges, and group management.

## Table of Contents

1. [SuperAdmin Features](#superadmin-features)
2. [Multi-Currency Expenses](#multi-currency-expenses)
3. [Balance-Based Exchanges](#balance-based-exchanges)
4. [Group Management](#group-management)
5. [Transfer Operations](#transfer-operations)
6. [Complete User Flows](#complete-user-flows)

---

## SuperAdmin Features

### Example 1: SuperAdmin Registration

```dart
import 'package:finance_app/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:finance_app/core/services/token_manager.dart';

// SuperAdmin registration with organization and admin group creation
Future<void> registerSuperAdmin() async {
  final authDatasource = AuthApiDatasource(apiClient: apiClient);
  
  try {
    final response = await authDatasource.register(
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePassword123!',
      role: 'superAdmin',
      organizationName: 'My Organization',  // Creates new organization
      adminGroupName: 'Main Admin Group',   // Creates SuperAdmin group
    );
    
    // Save authentication token
    await tokenManager.saveToken(
      token: response.token,
      tokenType: response.tokenType,
    );
    
    // Display SuperAdmin group code to user
    print('SuperAdmin Group Code: ${response.superAdminGroupCode}');
    print('Share this code with admins to join your group');
    
    // Navigate to SuperAdmin home
    navigateToSuperAdminHome();
  } catch (e) {
    print('Registration failed: $e');
  }
}
```

### Example 2: View SuperAdmin Analytics

```dart
import 'package:finance_app/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart';

// Fetch and display analytics for all admin groups
Future<void> viewAnalytics() async {
  final analyticsDatasource = SuperAdminAnalyticsApiDatasource(
    apiClient: apiClient,
  );
  
  try {
    // Fetch analytics for the last 15 days
    final analytics = await analyticsDatasource.getAnalytics(
      period: '15days',  // Options: '15days', 'month', 'all'
    );
    
    // Display analytics for each admin group
    for (final group in analytics.adminGroups) {
      print('Admin Group: ${group.adminGroupName}');
      print('  Transfers: ${group.transferCount} (Total: \$${group.transferTotalUsd})');
      print('  Expenses: ${group.expenseCount}');
      print('    USD: \$${group.expenseTotalUsd}');
      print('    SYP: ${group.expenseTotalSyp} ل.س');
      print('    TRY: ${group.expenseTotalTry} ₺');
      print('---');
    }
  } catch (e) {
    print('Failed to load analytics: $e');
  }
}
```

### Example 3: Manage SuperAdmin Group

```dart
import 'package:finance_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';

// View group info and members
Future<void> manageSuperAdminGroup() async {
  final groupDatasource = SuperAdminGroupApiDatasource(
    apiClient: apiClient,
  );
  
  try {
    // Get group information
    final groupInfo = await groupDatasource.getGroupInfo();
    print('Group: ${groupInfo.name}');
    print('Code: ${groupInfo.groupCode}');
    print('Members: ${groupInfo.memberCount}');
    
    // Get paginated list of admin members
    final membersResponse = await groupDatasource.getMembers(
      page: 1,
      perPage: 15,
    );
    
    print('\nAdmin Members:');
    for (final member in membersResponse.data) {
      print('  ${member.name} (${member.email})');
      print('    Admin Group: ${member.adminGroupName ?? 'None'}');
    }
    
    // Regenerate group code if needed
    if (needsNewCode) {
      final updatedGroup = await groupDatasource.regenerateCode();
      print('\nNew Group Code: ${updatedGroup.groupCode}');
    }
    
    // Remove a member
    if (shouldRemoveMember) {
      await groupDatasource.removeMember(memberIdToRemove);
      print('Member removed successfully');
    }
  } catch (e) {
    print('Group management failed: $e');
  }
}
```

---

## Multi-Currency Expenses

### Example 4: Create Expense in USD

```dart
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';

// Create an expense in USD
Future<void> createUsdExpense() async {
  final expenseDatasource = ExpenseApiDatasource(apiClient: apiClient);
  
  try {
    final expense = ExpenseDto(
      description: 'Office supplies',
      priceUsd: 150.00,
      expenseDate: '2024-01-15',
    );
    
    final createdExpense = await expenseDatasource.createExpense(expense);
    
    print('Expense created: ${createdExpense.description}');
    print('Amount: \$${createdExpense.priceUsd}');
    print('ID: ${createdExpense.id}');
    
    // Fund box USD balance is automatically decreased
  } catch (e) {
    if (e.toString().contains('Insufficient')) {
      print('Insufficient USD balance');
    } else {
      print('Failed to create expense: $e');
    }
  }
}
```

### Example 5: Create Expense in Multiple Currencies

```dart
// Create an expense with multiple currency amounts
Future<void> createMultiCurrencyExpense() async {
  final expenseDatasource = ExpenseApiDatasource(apiClient: apiClient);
  
  try {
    final expense = ExpenseDto(
      description: 'International conference',
      priceUsd: 500.00,
      priceSyp: 2500000.00,  // Equivalent in SYP
      priceTry: 15000.00,     // Equivalent in TRY
      expenseDate: '2024-01-15',
    );
    
    final createdExpense = await expenseDatasource.createExpense(expense);
    
    print('Multi-currency expense created:');
    print('  USD: \$${createdExpense.priceUsd}');
    print('  SYP: ${createdExpense.priceSyp} ل.س');
    print('  TRY: ${createdExpense.priceTry} ₺');
    
    // All currency balances are automatically decreased
  } catch (e) {
    print('Failed to create expense: $e');
  }
}
```

### Example 6: View Multi-Currency Fund Box

```dart
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';

// View all currency balances
Future<void> viewFundBox() async {
  final fundBoxDatasource = FundBoxApiDatasource(apiClient: apiClient);
  
  try {
    // Get all currency balances
    final fundBox = await fundBoxDatasource.getFundBox();
    
    print('Fund Box Balances:');
    print('  USD: \$${fundBox.balanceUsd?.toStringAsFixed(2) ?? '0.00'}');
    print('  SYP: ${fundBox.balanceSyp?.toStringAsFixed(2) ?? '0.00'} ل.س');
    print('  TRY: ${fundBox.balanceTry?.toStringAsFixed(2) ?? '0.00'} ₺');
    print('Last Updated: ${fundBox.lastUpdated}');
    
    // Get specific currency balance
    final usdBalance = await fundBoxDatasource.getFundBoxByCurrency('USD');
    print('\nUSD Balance: \$${usdBalance.balance}');
  } catch (e) {
    print('Failed to load fund box: $e');
  }
}
```

---

## Balance-Based Exchanges

### Example 7: Exchange USD to SYP

```dart
import 'package:finance_app/features/exchanges/data/datasources/exchange_api_datasource.dart';
import 'package:finance_app/features/exchanges/data/models/exchange_dto.dart';

// Exchange USD to SYP using total balance
Future<void> exchangeUsdToSyp() async {
  final exchangeDatasource = ExchangeApiDataSourceImpl(apiClient: apiClient);
  
  try {
    // Create exchange with exchange rate
    final exchange = await exchangeDatasource.createExchange(
      targetCurrency: 'SYP',
      amountUsd: 100.00,
      exchangeRate: 5000.00,  // 1 USD = 5000 SYP
      exchangeDate: '2024-01-15',
      notes: 'Exchange for local expenses',
    );
    
    print('Exchange created:');
    print('  USD: \$${exchange.amountUsd}');
    print('  Rate: ${exchange.exchangeRate}');
    print('  SYP: ${exchange.convertedAmount} ل.س');
    
    // USD balance decreased by 100
    // SYP balance increased by 500,000
  } catch (e) {
    if (e.toString().contains('Insufficient')) {
      print('Insufficient USD balance');
    } else {
      print('Failed to create exchange: $e');
    }
  }
}
```

### Example 8: Exchange with Converted Amount

```dart
// Exchange USD to TRY by specifying converted amount
Future<void> exchangeWithConvertedAmount() async {
  final exchangeDatasource = ExchangeApiDataSourceImpl(apiClient: apiClient);
  
  try {
    // Create exchange with converted amount (backend calculates rate)
    final exchange = await exchangeDatasource.createExchange(
      targetCurrency: 'TRY',
      amountUsd: 200.00,
      convertedAmount: 6000.00,  // Want exactly 6000 TRY
      exchangeDate: '2024-01-15',
      notes: 'Exchange for Turkey trip',
    );
    
    print('Exchange created:');
    print('  USD: \$${exchange.amountUsd}');
    print('  TRY: ${exchange.convertedAmount} ₺');
    print('  Calculated Rate: ${exchange.exchangeRate}');
    
    // Backend calculated: rate = 6000 / 200 = 30
  } catch (e) {
    print('Failed to create exchange: $e');
  }
}
```

### Example 9: Link Exchange to Transfer

```dart
// Create exchange linked to a specific transfer
Future<void> exchangeLinkedToTransfer() async {
  final exchangeDatasource = ExchangeApiDataSourceImpl(apiClient: apiClient);
  
  try {
    // Link exchange to transfer for audit trail
    final exchange = await exchangeDatasource.createExchange(
      transferId: 123,  // Optional: link to transfer
      targetCurrency: 'SYP',
      amountUsd: 500.00,
      exchangeRate: 5000.00,
      exchangeDate: '2024-01-15',
      notes: 'Exchange from transfer #123',
    );
    
    print('Exchange linked to transfer ${exchange.transferId}');
    
    // View all exchanges for this transfer
    final transferExchanges = await exchangeDatasource.getExchangesByTransfer(123);
    print('Total exchanges for transfer: ${transferExchanges.length}');
    
    // View transfer balance info
    final balanceInfo = await exchangeDatasource.getTransferBalance(123);
    print('Transfer Balance:');
    print('  Original: \$${balanceInfo.originalAmountUsd}');
    print('  Exchanged: \$${balanceInfo.exchangedAmountUsd}');
    print('  Remaining: \$${balanceInfo.remainingAmountUsd}');
  } catch (e) {
    print('Failed to create linked exchange: $e');
  }
}
```

### Example 10: View Exchange History

```dart
// View exchange history with currency filter
Future<void> viewExchangeHistory() async {
  final exchangeDatasource = ExchangeApiDataSourceImpl(apiClient: apiClient);
  
  try {
    // Get all exchanges
    final allExchanges = await exchangeDatasource.getAllExchanges();
    print('Total exchanges: ${allExchanges.length}');
    
    // Filter by currency
    final sypExchanges = await exchangeDatasource.getAllExchanges(
      currency: 'SYP',
    );
    print('SYP exchanges: ${sypExchanges.length}');
    
    // Display exchange details
    for (final exchange in sypExchanges) {
      print('---');
      print('Date: ${exchange.exchangeDate}');
      print('USD: \$${exchange.amountUsd}');
      print('Rate: ${exchange.exchangeRate}');
      print('SYP: ${exchange.convertedAmount} ل.س');
      if (exchange.transferId != null) {
        print('Linked to Transfer #${exchange.transferId}');
      }
    }
  } catch (e) {
    print('Failed to load exchange history: $e');
  }
}
```

---

## Group Management

### Example 11: Admin Registration with Group Code

```dart
import 'package:finance_app/features/auth/data/datasources/auth_api_datasource.dart';

// Admin registers and joins SuperAdmin group
Future<void> registerAdmin() async {
  final authDatasource = AuthApiDatasource(apiClient: apiClient);
  
  try {
    final response = await authDatasource.register(
      name: 'Jane Smith',
      email: 'jane@example.com',
      password: 'SecurePassword123!',
      role: 'admin',
      superAdminGroupCode: 'ABC123',  // Join SuperAdmin group
    );
    
    // Save authentication token
    await tokenManager.saveToken(
      token: response.token,
      tokenType: response.tokenType,
    );
    
    // Display admin group info
    print('Joined SuperAdmin Group');
    print('Admin Group: ${response.adminGroup?.name}');
    
    // Navigate to Admin home
    navigateToAdminHome();
  } catch (e) {
    if (e.toString().contains('Invalid group code')) {
      print('Invalid SuperAdmin group code');
    } else {
      print('Registration failed: $e');
    }
  }
}
```

### Example 12: Admin Group Management

```dart
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';

// Manage admin's own group
Future<void> manageAdminGroup() async {
  final groupDatasource = AdminGroupApiDataSourceImpl(
    apiClient: apiClient,
    roleService: roleService,
  );
  
  try {
    // Get admin group info
    final groupInfo = await groupDatasource.getAdminGroup();
    print('Admin Group: ${groupInfo.name}');
    print('Group Code: ${groupInfo.groupCode}');
    print('Members: ${groupInfo.memberCount}');
    
    // Get group members with search
    final membersResponse = await groupDatasource.getGroupMembers(
      page: 1,
      perPage: 15,
      search: 'john',  // Search by name or email
    );
    
    print('\nGroup Members:');
    for (final member in membersResponse.data) {
      print('  ${member.name} (${member.email})');
      print('    Department: ${member.department ?? 'N/A'}');
      print('    Joined: ${member.joinedAt}');
    }
    
    // Regenerate group code
    final updatedGroup = await groupDatasource.regenerateGroupCode();
    print('\nNew Group Code: ${updatedGroup.groupCode}');
    print('Share this code with users to join your group');
    
    // Remove a member
    await groupDatasource.removeMember(userId: 456);
    print('Member removed successfully');
  } catch (e) {
    print('Group management failed: $e');
  }
}
```

### Example 13: User Joins Admin Group

```dart
// User joins admin group using group code
Future<void> joinAdminGroup() async {
  final groupDatasource = AdminGroupApiDataSourceImpl(
    apiClient: apiClient,
    roleService: roleService,
  );
  
  try {
    // Join group with code
    final groupInfo = await groupDatasource.joinGroup('XYZ789');
    
    print('Successfully joined group!');
    print('Group: ${groupInfo.groupName}');
    print('Admin: ${groupInfo.adminName} (${groupInfo.adminEmail})');
    print('Members: ${groupInfo.membersCount}');
    
    // View group info
    final myGroupInfo = await groupDatasource.getUserGroupInfo();
    print('\nMy Group Info:');
    print('  Code: ${myGroupInfo.groupCode}');
    print('  Joined: ${myGroupInfo.joinedAt}');
  } catch (e) {
    if (e.toString().contains('Invalid group code')) {
      print('Invalid group code. Please check and try again.');
    } else if (e.toString().contains('Already in a group')) {
      print('You are already in a group.');
    } else {
      print('Failed to join group: $e');
    }
  }
}
```

---

## Transfer Operations

### Example 14: SuperAdmin Transfer to Admin

```dart
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';

// SuperAdmin transfers funds to admin
Future<void> superAdminTransfer() async {
  final transferDatasource = TransferApiDatasource(apiClient: apiClient);
  
  try {
    final transfer = TransferDto(
      recipientUserId: 456,  // Admin user ID
      recipientName: 'Jane Smith',
      amountUsd: 5000.00,
      transferDate: DateTime.now(),
      notes: 'Monthly funding',
    );
    
    final createdTransfer = await transferDatasource.createTransfer(transfer);
    
    print('Transfer created:');
    print('  To: ${createdTransfer.recipientName}');
    print('  Amount: \$${createdTransfer.amountUsd}');
    print('  ID: ${createdTransfer.id}');
    
    // SuperAdmin USD balance decreased by 5000
    // Admin USD balance increased by 5000
  } catch (e) {
    if (e.toString().contains('not in your group')) {
      print('Recipient is not in your SuperAdmin group');
    } else if (e.toString().contains('Insufficient')) {
      print('Insufficient funds');
    } else {
      print('Transfer failed: $e');
    }
  }
}
```

### Example 15: Admin Transfer to User

```dart
// Admin transfers funds to user in their group
Future<void> adminTransfer() async {
  final transferDatasource = TransferApiDatasource(apiClient: apiClient);
  
  try {
    final transfer = TransferDto(
      recipientUserId: 789,  // User ID
      recipientName: 'Bob Johnson',
      amountUsd: 1000.00,
      transferDate: DateTime.now(),
      notes: 'Project funding',
    );
    
    final createdTransfer = await transferDatasource.createTransfer(transfer);
    
    print('Transfer created:');
    print('  To: ${createdTransfer.recipientName}');
    print('  Amount: \$${createdTransfer.amountUsd}');
    
    // Admin USD balance decreased by 1000
    // User USD balance increased by 1000
  } catch (e) {
    if (e.toString().contains('not in your group')) {
      print('Recipient is not in your admin group');
    } else {
      print('Transfer failed: $e');
    }
  }
}
```

---

## Complete User Flows

### Example 16: Complete SuperAdmin Flow

```dart
// Complete SuperAdmin workflow
Future<void> completeSuperAdminFlow() async {
  // 1. Register as SuperAdmin
  final authResponse = await authDatasource.register(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'SecurePassword123!',
    role: 'superAdmin',
    organizationName: 'My Organization',
    adminGroupName: 'Main Admin Group',
  );
  
  print('SuperAdmin Group Code: ${authResponse.superAdminGroupCode}');
  
  // 2. View analytics
  final analytics = await analyticsDatasource.getAnalytics(period: 'month');
  print('Admin Groups: ${analytics.adminGroups.length}');
  
  // 3. Manage group
  final groupInfo = await groupDatasource.getGroupInfo();
  final members = await groupDatasource.getMembers();
  print('Group Members: ${members.data.length}');
  
  // 4. Transfer to admin
  final transfer = await transferDatasource.createTransfer(
    TransferDto(
      recipientUserId: 456,
      recipientName: 'Admin Name',
      amountUsd: 5000.00,
      transferDate: DateTime.now(),
    ),
  );
  print('Transfer completed: \$${transfer.amountUsd}');
}
```

### Example 17: Complete Admin Flow

```dart
// Complete Admin workflow
Future<void> completeAdminFlow() async {
  // 1. Register as Admin with SuperAdmin group code
  final authResponse = await authDatasource.register(
    name: 'Jane Smith',
    email: 'jane@example.com',
    password: 'SecurePassword123!',
    role: 'admin',
    superAdminGroupCode: 'ABC123',
  );
  
  print('Joined SuperAdmin Group');
  
  // 2. Manage own admin group
  final groupInfo = await groupDatasource.getAdminGroup();
  print('My Group Code: ${groupInfo.groupCode}');
  
  // 3. Transfer to user
  final transfer = await transferDatasource.createTransfer(
    TransferDto(
      recipientUserId: 789,
      recipientName: 'User Name',
      amountUsd: 1000.00,
      transferDate: DateTime.now(),
    ),
  );
  
  // 4. View fund box
  final fundBox = await fundBoxDatasource.getFundBox();
  print('USD Balance: \$${fundBox.balanceUsd}');
}
```

### Example 18: Complete User Flow

```dart
// Complete User workflow
Future<void> completeUserFlow() async {
  // 1. Join admin group
  final groupInfo = await groupDatasource.joinGroup('XYZ789');
  print('Joined Group: ${groupInfo.groupName}');
  
  // 2. View fund box
  final fundBox = await fundBoxDatasource.getFundBox();
  print('Balances:');
  print('  USD: \$${fundBox.balanceUsd}');
  print('  SYP: ${fundBox.balanceSyp} ل.س');
  print('  TRY: ${fundBox.balanceTry} ₺');
  
  // 3. Create expense
  final expense = await expenseDatasource.createExpense(
    ExpenseDto(
      description: 'Office supplies',
      priceUsd: 150.00,
      expenseDate: '2024-01-15',
    ),
  );
  print('Expense created: \$${expense.priceUsd}');
  
  // 4. Exchange USD to SYP
  final exchange = await exchangeDatasource.createExchange(
    targetCurrency: 'SYP',
    amountUsd: 100.00,
    exchangeRate: 5000.00,
    exchangeDate: '2024-01-15',
  );
  print('Exchanged: \$${exchange.amountUsd} → ${exchange.convertedAmount} ل.س');
  
  // 5. Create expense in SYP
  final sypExpense = await expenseDatasource.createExpense(
    ExpenseDto(
      description: 'Local supplies',
      priceSyp: 250000.00,
      expenseDate: '2024-01-15',
    ),
  );
  print('SYP Expense created: ${sypExpense.priceSyp} ل.س');
}
```

---

## Summary

These examples demonstrate the complete functionality of the Postman API v3.1 integration, including:

- **SuperAdmin Features**: Registration, analytics, group management
- **Multi-Currency Support**: Expenses and fund box in USD, SYP, TRY
- **Balance-Based Exchanges**: Currency exchange with optional transfer linking
- **Group Management**: Admin and user group operations
- **Transfer Operations**: SuperAdmin→Admin and Admin→User transfers
- **Complete Workflows**: End-to-end user flows for all roles

All examples use Bearer token authentication automatically via the `BearerTokenInterceptor`.

For API documentation, see [API_DOCUMENTATION.md](./API_DOCUMENTATION.md).

For troubleshooting, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).
