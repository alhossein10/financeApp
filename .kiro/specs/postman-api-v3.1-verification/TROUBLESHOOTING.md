# Troubleshooting Guide - Postman API v3.1 Integration

## Overview

This guide provides solutions to common issues encountered when using the Postman API v3.1 integration, including Bearer token issues, multi-currency problems, exchange errors, and group management issues.

## Table of Contents

1. [Bearer Token Issues](#bearer-token-issues)
2. [Multi-Currency Issues](#multi-currency-issues)
3. [Exchange Issues](#exchange-issues)
4. [Group Management Issues](#group-management-issues)
5. [Transfer Issues](#transfer-issues)
6. [Authentication Issues](#authentication-issues)
7. [Network and Connectivity Issues](#network-and-connectivity-issues)
8. [Data Synchronization Issues](#data-synchronization-issues)

---

## Bearer Token Issues

### Issue 1: 401 Unauthorized Error

**Symptoms:**
- API requests fail with 401 status code
- Error message: "Unauthorized" or "Unauthenticated"

**Causes:**
- Token expired
- Token not saved properly
- Token not included in request

**Solutions:**

```dart
// Check if token exists
final token = await tokenManager.getToken();
if (token == null) {
  print('No token found - user needs to login');
  navigateToLogin();
}

// Verify token is valid
try {
  final user = await authApiDatasource.getCurrentUser();
  print('Token valid, user: ${user.name}');
} catch (e) {
  print('Token invalid: $e');
  await tokenManager.clearToken();
  navigateToLogin();
}

// Check if Bearer token interceptor is configured
// Verify in lib/core/api/api_client.dart that BearerTokenInterceptor is added
```

**Prevention:**
- Ensure `BearerTokenInterceptor` is added to Dio interceptors
- Always save token after successful login/registration
- Handle token refresh automatically in interceptor


### Issue 2: Token Refresh Loop

**Symptoms:**
- App continuously refreshes token
- Multiple refresh requests in network logs
- App becomes unresponsive

**Causes:**
- Refresh token also expired
- Refresh endpoint returning 401
- Interceptor not handling refresh failure

**Solutions:**

```dart
// Check refresh token validity
final refreshToken = await tokenManager.getRefreshToken();
if (refreshToken == null) {
  print('No refresh token - logout required');
  await logout();
}

// Implement refresh failure handling in BearerTokenInterceptor
class BearerTokenInterceptor extends Interceptor {
  bool _isRefreshing = false;
  
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        await _refreshToken();
        // Retry original request
        return handler.resolve(await _retry(err.requestOptions));
      } catch (e) {
        // Refresh failed - logout
        await _handleRefreshFailure();
        return handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }
}
```

**Prevention:**
- Implement refresh failure counter (max 2 attempts)
- Clear tokens and logout after refresh failure
- Add `_isRefreshing` flag to prevent concurrent refreshes

### Issue 3: Public Endpoints Getting Bearer Token

**Symptoms:**
- Organizations/departments endpoints fail with 401
- Public endpoints require authentication

**Causes:**
- Public endpoint detection not working
- Endpoint path doesn't match public list

**Solutions:**

```dart
// Verify public endpoints list in BearerTokenInterceptor
final publicEndpoints = [
  '/organizations',
  '/organizations/{id}/departments',
  '/auth/register',
  '/auth/login',
  '/auth/forgot-password',
  '/auth/reset-password',
];

// Check if path matching works correctly
bool isPublicEndpoint(String path) {
  return publicEndpoints.any((endpoint) {
    // Handle path parameters
    final pattern = endpoint.replaceAll(RegExp(r'\{[^}]+\}'), '[^/]+');
    return RegExp('^$pattern\$').hasMatch(path);
  });
}
```

**Prevention:**
- Test public endpoints without authentication
- Verify path matching logic handles parameters correctly
- Add logging to see which endpoints are detected as public

---

## Multi-Currency Issues

### Issue 1: Balance Not Updating After Expense

**Symptoms:**
- Expense created successfully
- Fund box balance doesn't decrease
- Wrong currency balance updated

**Causes:**
- Currency mismatch between expense and balance
- Fund box not refreshed after expense
- Backend not updating balance

**Solutions:**

```dart
// Verify expense currency matches balance
final expense = ExpenseDto(
  description: 'Test',
  priceUsd: 100.00,  // Ensure correct currency field
  expenseDate: '2024-01-01',
);

// Refresh fund box after expense creation
await expenseApiDatasource.createExpense(expense);
await fundBoxBloc.add(LoadFundBox());  // Refresh balance

// Check which currency was used
print('Expense USD: ${expense.priceUsd}');
print('Expense SYP: ${expense.priceSyp}');
print('Expense TRY: ${expense.priceTry}');
```

**Prevention:**
- Always refresh fund box after expense creation
- Validate currency before creating expense
- Show balance update in UI immediately

### Issue 2: Insufficient Balance Error

**Symptoms:**
- Error: "Insufficient {currency} balance"
- Balance appears sufficient in UI

**Causes:**
- Balance not synced with backend
- Checking wrong currency balance
- Pending transactions not accounted for

**Solutions:**

```dart
// Refresh balance before validation
await fundBoxBloc.add(LoadFundBox());
await Future.delayed(Duration(milliseconds: 500));  // Wait for refresh

// Check correct currency balance
final fundBox = await fundBoxApiDatasource.getFundBox();
if (expense.priceUsd != null && fundBox.balanceUsd! < expense.priceUsd!) {
  throw InsufficientBalanceException('USD');
}
if (expense.priceSyp != null && fundBox.balanceSyp! < expense.priceSyp!) {
  throw InsufficientBalanceException('SYP');
}
if (expense.priceTry != null && fundBox.balanceTry! < expense.priceTry!) {
  throw InsufficientBalanceException('TRY');
}
```

**Prevention:**
- Always fetch latest balance before validation
- Show real-time balance in expense creation UI
- Implement optimistic updates with rollback on failure

### Issue 3: Multi-Currency Display Issues

**Symptoms:**
- Currencies not formatted correctly
- Wrong currency symbols displayed
- Null values shown as "0.00"

**Causes:**
- Missing currency formatting
- Null handling not implemented
- Wrong currency symbol used

**Solutions:**

```dart
// Implement proper currency formatting
String formatCurrency(double? amount, String currency) {
  if (amount == null) return '-';
  
  switch (currency) {
    case 'USD':
      return '\$${amount.toStringAsFixed(2)}';
    case 'SYP':
      return '${amount.toStringAsFixed(0)} ل.س';
    case 'TRY':
      return '₺${amount.toStringAsFixed(2)}';
    default:
      return amount.toStringAsFixed(2);
  }
}

// Display only non-null currencies
Widget buildCurrencyDisplay(ExpenseDto expense) {
  final currencies = <Widget>[];
  
  if (expense.priceUsd != null) {
    currencies.add(Text(formatCurrency(expense.priceUsd, 'USD')));
  }
  if (expense.priceSyp != null) {
    currencies.add(Text(formatCurrency(expense.priceSyp, 'SYP')));
  }
  if (expense.priceTry != null) {
    currencies.add(Text(formatCurrency(expense.priceTry, 'TRY')));
  }
  
  return Column(children: currencies);
}
```

**Prevention:**
- Use consistent currency formatting throughout app
- Handle null values explicitly
- Test with all three currencies

---

## Exchange Issues

### Issue 1: Exchange Rate Calculation Error

**Symptoms:**
- Converted amount incorrect
- Exchange rate doesn't match expected value
- Backend returns validation error

**Causes:**
- Both rate and amount provided (only one should be)
- Calculation precision issues
- Backend calculation differs from frontend

**Solutions:**

```dart
// Provide either rate OR converted amount, not both
final exchange = ExchangeDto(
  targetCurrency: 'SYP',
  amountUsd: 100.00,
  exchangeRate: 5000.00,  // Backend calculates converted_amount
  // Don't provide convertedAmount
  exchangeDate: DateTime.now(),
);

// OR provide converted amount
final exchange = ExchangeDto(
  targetCurrency: 'SYP',
  amountUsd: 100.00,
  // Don't provide exchangeRate
  convertedAmount: 500000.00,  // Backend calculates exchange_rate
  exchangeDate: DateTime.now(),
);

// Let user choose which to provide
if (userProvidesRate) {
  exchange.exchangeRate = rate;
} else {
  exchange.convertedAmount = amount;
}
```

**Prevention:**
- Validate that only one of rate/amount is provided
- Show calculated value in UI before submission
- Use backend calculation as source of truth

### Issue 2: Balance Not Updated After Exchange

**Symptoms:**
- Exchange created successfully
- USD balance doesn't decrease
- Target currency balance doesn't increase

**Causes:**
- Fund box not refreshed
- Backend not updating balances
- Exchange failed but no error shown

**Solutions:**

```dart
// Refresh fund box after exchange
try {
  await exchangeApiDatasource.createExchange(exchange);
  
  // Wait for backend to process
  await Future.delayed(Duration(milliseconds: 500));
  
  // Refresh fund box
  await fundBoxBloc.add(LoadFundBox());
  
  // Verify balances updated
  final fundBox = await fundBoxApiDatasource.getFundBox();
  print('USD: ${fundBox.balanceUsd}');
  print('${exchange.targetCurrency}: ${exchange.targetCurrency == "SYP" ? fundBox.balanceSyp : fundBox.balanceTry}');
} catch (e) {
  print('Exchange failed: $e');
  // Show error to user
}
```

**Prevention:**
- Always refresh fund box after exchange
- Show loading indicator during exchange
- Verify balance changes in UI

### Issue 3: Transfer Link Not Working

**Symptoms:**
- Exchange created with transfer_id
- Transfer link doesn't show in UI
- Can't view exchanges for transfer

**Causes:**
- Transfer ID invalid
- Transfer doesn't belong to user
- Backend not returning transfer info

**Solutions:**

```dart
// Verify transfer exists and belongs to user
final transfer = await transferApiDatasource.getTransfer(transferId);
if (transfer == null) {
  throw Exception('Transfer not found');
}

// Create exchange with valid transfer ID
final exchange = ExchangeDto(
  transferId: transfer.id,
  targetCurrency: 'SYP',
  amountUsd: 100.00,
  exchangeRate: 5000.00,
  exchangeDate: DateTime.now(),
);

// Fetch exchanges for transfer
final exchanges = await exchangeApiDatasource.getExchangesByTransfer(transferId);
print('Found ${exchanges.length} exchanges for transfer');

// Get transfer balance info
final balanceInfo = await exchangeApiDatasource.getTransferBalanceInfo(transferId);
print('Original: ${balanceInfo.originalAmountUsd}');
print('Exchanged: ${balanceInfo.exchangedAmountUsd}');
print('Remaining: ${balanceInfo.remainingAmountUsd}');
```

**Prevention:**
- Validate transfer ID before creating exchange
- Show transfer info in exchange creation UI
- Test exchange-transfer linking thoroughly

---

## Group Management Issues

### Issue 1: Invalid Group Code Error

**Symptoms:**
- Error: "Invalid group code"
- Code appears correct (6 digits)
- User can't join group

**Causes:**
- Code expired or regenerated
- Code doesn't exist
- User already in a group
- Wrong group type (SuperAdmin vs Admin)

**Solutions:**

```dart
// Verify code format
if (groupCode.length != 6) {
  throw ValidationException('Group code must be 6 characters');
}

// Try joining group
try {
  final result = await adminGroupApiDatasource.joinGroup(groupCode);
  print('Joined group: ${result.groupName}');
} catch (e) {
  if (e.toString().contains('Invalid group code')) {
    // Code doesn't exist or expired
    showError('This group code is invalid or has expired. Please check with your admin.');
  } else if (e.toString().contains('Already in a group')) {
    // User already in group
    showError('You are already in a group. Leave your current group first.');
  } else {
    showError('Failed to join group: $e');
  }
}
```

**Prevention:**
- Show code format requirements in UI
- Validate code format before API call
- Provide clear error messages for each case
- Allow admin to regenerate code if needed

### Issue 2: Can't Remove Group Member

**Symptoms:**
- Remove button doesn't work
- Error when removing member
- Member still appears in list

**Causes:**
- Insufficient permissions
- Member is admin (can't remove self)
- Backend error

**Solutions:**

```dart
// Check if user has permission
if (currentUser.role != 'admin' && currentUser.role != 'superAdmin') {
  throw PermissionException('Only admins can remove members');
}

// Check if trying to remove self
if (memberId == currentUser.id) {
  throw ValidationException('Cannot remove yourself from the group');
}

// Remove member
try {
  await adminGroupApiDatasource.removeMember(memberId);
  
  // Refresh member list
  await adminGroupBloc.add(LoadGroupMembers());
  
  showSuccess('Member removed successfully');
} catch (e) {
  print('Failed to remove member: $e');
  showError('Failed to remove member. Please try again.');
}
```

**Prevention:**
- Disable remove button for self
- Show confirmation dialog before removal
- Refresh member list after removal
- Handle errors gracefully

### Issue 3: Group Code Not Displaying After Regeneration

**Symptoms:**
- Code regenerated successfully
- New code not shown in UI
- Old code still displayed

**Causes:**
- UI not refreshed after regeneration
- Response not parsed correctly
- State not updated

**Solutions:**

```dart
// Regenerate code and update UI
try {
  final newGroup = await adminGroupApiDatasource.regenerateCode();
  
  // Update state with new code
  adminGroupBloc.add(UpdateGroupCode(newGroup.groupCode));
  
  // Show new code prominently
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('New Group Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your new group code is:'),
          SizedBox(height: 16),
          Text(
            newGroup.groupCode,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Share this code with new members'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: newGroup.groupCode));
            showSuccess('Code copied to clipboard');
          },
          child: Text('Copy'),
        ),
      ],
    ),
  );
} catch (e) {
  showError('Failed to regenerate code: $e');
}
```

**Prevention:**
- Update UI immediately after regeneration
- Show new code in prominent dialog
- Add copy-to-clipboard functionality
- Refresh group info after regeneration

---

## Transfer Issues

### Issue 1: Transfer to Wrong User

**Symptoms:**
- Transfer sent to wrong recipient
- Can't find intended recipient in list
- Recipient not in group

**Causes:**
- Recipient not in same group
- User list not filtered correctly
- Wrong user selected

**Solutions:**

```dart
// Fetch only users in same group
final groupMembers = await adminGroupApiDatasource.getGroupMembers();

// Filter out current user
final recipients = groupMembers.where((m) => m.id != currentUser.id).toList();

// Show recipient selection
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Select Recipient'),
    content: Container(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: recipients.length,
        itemBuilder: (context, index) {
          final recipient = recipients[index];
          return ListTile(
            title: Text(recipient.name),
            subtitle: Text(recipient.email),
            onTap: () {
              Navigator.pop(context, recipient);
            },
          );
        },
      ),
    ),
  ),
);

// Verify recipient before transfer
if (!groupMembers.any((m) => m.id == recipientId)) {
  throw ValidationException('Recipient not in your group');
}
```

**Prevention:**
- Show only valid recipients in selection
- Display recipient info clearly before confirmation
- Add search functionality for large groups
- Confirm recipient before sending transfer

### Issue 2: Insufficient Balance for Transfer

**Symptoms:**
- Error: "Insufficient funds"
- Balance appears sufficient
- Transfer fails

**Causes:**
- Balance not synced
- Pending transfers not accounted for
- Wrong currency checked

**Solutions:**

```dart
// Refresh balance before transfer
await fundBoxBloc.add(LoadFundBox());
await Future.delayed(Duration(milliseconds: 500));

// Check USD balance (transfers are always in USD)
final fundBox = await fundBoxApiDatasource.getFundBox();
if (fundBox.balanceUsd! < transferAmount) {
  showError('Insufficient USD balance. Current: \$${fundBox.balanceUsd}, Required: \$$transferAmount');
  return;
}

// Show confirmation with current balance
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm Transfer'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Amount: \$$transferAmount'),
        Text('Current Balance: \$${fundBox.balanceUsd}'),
        Text('After Transfer: \$${fundBox.balanceUsd! - transferAmount}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);
          await _sendTransfer();
        },
        child: Text('Confirm'),
      ),
    ],
  ),
);
```

**Prevention:**
- Always check latest balance before transfer
- Show balance in transfer creation UI
- Display remaining balance after transfer
- Validate amount before submission

---

## Authentication Issues

### Issue 1: Login Fails with Correct Credentials

**Symptoms:**
- Error: "Invalid credentials"
- Credentials are correct
- Can't login to account

**Causes:**
- Account locked or disabled
- Email not verified
- Backend issue

**Solutions:**

```dart
// Check error details
try {
  await authApiDatasource.login(email, password);
} catch (e) {
  if (e is ApiException) {
    if (e.statusCode == 401) {
      showError('Invalid email or password');
    } else if (e.statusCode == 403) {
      showError('Account is locked or disabled. Contact support.');
    } else if (e.message.contains('email not verified')) {
      showError('Please verify your email before logging in');
    } else {
      showError('Login failed: ${e.message}');
    }
  }
}

// Try password reset if needed
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Login Failed'),
    content: Text('Would you like to reset your password?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          navigateToForgotPassword();
        },
        child: Text('Reset Password'),
      ),
    ],
  ),
);
```

**Prevention:**
- Provide clear error messages
- Offer password reset option
- Check account status before login
- Log errors for debugging

### Issue 2: Session Expires Too Quickly

**Symptoms:**
- Logged out frequently
- Token expires within minutes
- Constant re-authentication required

**Causes:**
- Token expiration time too short
- Token not being refreshed
- Refresh token expired

**Solutions:**

```dart
// Implement proactive token refresh
class TokenRefreshService {
  Timer? _refreshTimer;
  
  void startAutoRefresh() {
    // Refresh token 5 minutes before expiration
    final expiresIn = tokenManager.getTokenExpiresIn();
    final refreshIn = expiresIn - Duration(minutes: 5);
    
    _refreshTimer = Timer(refreshIn, () async {
      try {
        await authApiDatasource.refreshToken();
        startAutoRefresh();  // Schedule next refresh
      } catch (e) {
        print('Auto refresh failed: $e');
        logout();
      }
    });
  }
  
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }
}

// Start auto refresh after login
await authApiDatasource.login(email, password);
tokenRefreshService.startAutoRefresh();
```

**Prevention:**
- Implement automatic token refresh
- Refresh token before expiration
- Handle refresh failures gracefully
- Store refresh token securely

---

## Network and Connectivity Issues

### Issue 1: Timeout Errors

**Symptoms:**
- Error: "Connection timeout"
- Requests take too long
- App becomes unresponsive

**Causes:**
- Slow network connection
- Server not responding
- Timeout too short

**Solutions:**

```dart
// Increase timeout for slow connections
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 30),
));

// Implement retry logic
Future<Response> retryRequest(RequestOptions options, {int maxRetries = 3}) async {
  int retries = 0;
  
  while (retries < maxRetries) {
    try {
      return await dio.fetch(options);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        retries++;
        if (retries >= maxRetries) rethrow;
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: retries * 2));
      } else {
        rethrow;
      }
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

**Prevention:**
- Set appropriate timeout values
- Implement retry logic with exponential backoff
- Show loading indicator during requests
- Handle timeout errors gracefully

### Issue 2: No Internet Connection

**Symptoms:**
- Error: "No internet connection"
- All requests fail
- App shows offline state

**Causes:**
- Device offline
- Network unavailable
- Airplane mode enabled

**Solutions:**

```dart
// Check connectivity before requests
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> checkConnectivity() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Show offline indicator
class OfflineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityResult.none) {
          return Container(
            color: Colors.red,
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Text('No internet connection', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

// Queue requests when offline
class OfflineQueueManager {
  final List<RequestOptions> _queue = [];
  
  void queueRequest(RequestOptions options) {
    _queue.add(options);
  }
  
  Future<void> processQueue() async {
    while (_queue.isNotEmpty) {
      final options = _queue.removeAt(0);
      try {
        await dio.fetch(options);
      } catch (e) {
        print('Failed to process queued request: $e');
        _queue.insert(0, options);  // Re-queue on failure
        break;
      }
    }
  }
}
```

**Prevention:**
- Monitor connectivity status
- Show offline indicator in UI
- Queue requests when offline
- Process queue when connection restored

---

## Data Synchronization Issues

### Issue 1: Offline Changes Not Syncing

**Symptoms:**
- Changes made offline
- Sync fails when online
- Data lost after sync

**Causes:**
- Sync service not running
- Conflicts not resolved
- Batch sync failing

**Solutions:**

```dart
// Implement robust sync service
class SyncService {
  Future<void> syncOfflineChanges() async {
    // Get offline changes
    final offlineExpenses = await expenseLocalDatasource.getUnsyncedExpenses();
    
    if (offlineExpenses.isEmpty) {
      print('No offline changes to sync');
      return;
    }
    
    // Batch sync (max 50 at a time)
    final batches = _createBatches(offlineExpenses, 50);
    
    for (final batch in batches) {
      try {
        final response = await batchSyncService.syncBatch(batch);
        
        // Update local records with server IDs
        for (final result in response.results) {
          if (result.success) {
            await expenseLocalDatasource.updateServerId(
              result.localId,
              result.serverId,
            );
          } else {
            print('Sync failed for ${result.localId}: ${result.error}');
          }
        }
      } catch (e) {
        print('Batch sync failed: $e');
        // Continue with next batch
      }
    }
  }
  
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (var i = 0; i < items.length; i += batchSize) {
      batches.add(items.sublist(i, min(i + batchSize, items.length)));
    }
    return batches;
  }
}
```

**Prevention:**
- Implement automatic sync when online
- Handle sync failures gracefully
- Show sync status in UI
- Allow manual sync trigger

### Issue 2: Sync Conflicts

**Symptoms:**
- Error: "Sync conflict detected"
- Data differs between local and server
- Can't resolve conflict

**Causes:**
- Same record modified offline and online
- Conflict resolution not implemented
- User doesn't know which version to keep

**Solutions:**

```dart
// Implement conflict resolution
class ConflictResolutionDialog extends StatelessWidget {
  final Expense localVersion;
  final Expense serverVersion;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sync Conflict'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This expense was modified both locally and on the server.'),
          SizedBox(height: 16),
          Text('Local Version:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${localVersion.description} - \$${localVersion.priceUsd}'),
          Text('Modified: ${localVersion.updatedAt}'),
          SizedBox(height: 16),
          Text('Server Version:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${serverVersion.description} - \$${serverVersion.priceUsd}'),
          Text('Modified: ${serverVersion.updatedAt}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'local'),
          child: Text('Keep Local'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'server'),
          child: Text('Keep Server'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'merge'),
          child: Text('Merge'),
        ),
      ],
    );
  }
}

// Resolve conflict
final resolution = await showDialog<String>(
  context: context,
  builder: (context) => ConflictResolutionDialog(
    localVersion: localExpense,
    serverVersion: serverExpense,
  ),
);

if (resolution != null) {
  await conflictResolutionService.resolveConflict(
    resourceType: 'expense',
    resourceId: localExpense.id,
    resolution: resolution,
  );
}
```

**Prevention:**
- Implement conflict detection
- Show clear conflict resolution UI
- Allow user to choose resolution strategy
- Test conflict scenarios thoroughly

---

## Summary

This troubleshooting guide covers common issues across all major features:
- Bearer token authentication and refresh
- Multi-currency balance and expense management
- Currency exchanges and calculations
- Group management and membership
- Transfers between users
- Authentication and session management
- Network connectivity and offline support
- Data synchronization and conflict resolution

For each issue, we provide:
- Clear symptoms to identify the problem
- Root causes to understand why it happens
- Step-by-step solutions with code examples
- Prevention strategies to avoid future occurrences

For additional help:
- See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for complete API reference
- See [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md) for implementation examples
- See [ERROR_HANDLING_QUICK_REFERENCE.md](./ERROR_HANDLING_QUICK_REFERENCE.md) for error codes

If you encounter an issue not covered here, please check the backend logs and network requests for more details.
