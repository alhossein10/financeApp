# Migration Guide for Existing Users

## Overview

This guide helps existing users migrate from the old API integration to the new Laravel API integration with fixed field mappings, enhanced error handling, and role-based access control.

## What's Changed

### API Field Mappings

All DTOs have been updated to match the Laravel API specification:

| Module | Old Field | New Field | Impact |
|--------|-----------|-----------|--------|
| Transfer | recipient_name | from_account, to_account | Breaking change |
| Incoming | title | source | Breaking change |
| Incoming | - | payment_method | New required field |
| Fund Box | balance_usd | total_balance | Breaking change |
| Admin Stats | - | Multiple new fields | New fields added |
| Expense | - | payment_method validation | Enhanced validation |

### Error Handling

- All API errors now use `ApiException` with user-friendly messages
- 401 errors trigger automatic logout
- 403 errors show access denied messages
- 422 errors display field-specific validation errors
- Network errors queue operations for later sync

### Role-Based Access Control

- Admin-only features now properly restricted
- Fund box requires admin role
- Admin dashboard requires admin role
- Audit logs require admin role
- Non-admin users see appropriate error messages

## Migration Steps

### Step 1: Backup Your Data

Before updating, backup your local database:

```dart
// Run this script to export your data
dart run scripts/export_data.dart
```

This creates a backup file at `backup/data_backup_[timestamp].json`

### Step 2: Update the App

```bash
# Pull latest changes
git pull origin main

# Clean build
flutter clean
flutter pub get

# Rebuild the app
flutter build apk --flavor user
flutter build apk --flavor admin
```

### Step 3: Data Migration

The app will automatically migrate your local data on first launch:

1. **Transfer Migration**
   - Old `recipient_name` field will be split into `from_account` and `to_account`
   - If splitting is not possible, `from_account` will be set to "Unknown"

2. **Incoming Migration**
   - Old `title` field will be renamed to `source`
   - `payment_method` will be set to "cash" by default
   - You can update payment methods manually after migration

3. **Fund Box Migration**
   - Old `balance_usd` field will be renamed to `total_balance`
   - No data loss expected

### Step 4: Sync with Server

After migration, sync your data with the server:

1. Open the app
2. Login with your credentials
3. Go to Settings > Sync
4. Tap "Sync Now"
5. Wait for sync to complete

The sync process will:
- Upload all local changes to the server
- Download any server changes
- Resolve conflicts (you'll be prompted to choose)
- Update local database with server IDs

### Step 5: Verify Data

After sync, verify your data:

1. **Transfers**: Check that from_account and to_account are correct
2. **Incoming**: Check that source and payment_method are correct
3. **Expenses**: Check that payment_method is correct
4. **Fund Box** (Admin only): Check that balance is correct

## Breaking Changes

### 1. Transfer DTO

**Old Structure**:
```dart
class TransferDto {
  final double amount;
  final String recipientName;
  final String? description;
  final String date;
}
```

**New Structure**:
```dart
class TransferDto {
  final double amount;
  final String fromAccount;
  final String toAccount;
  final String? description;
  final String date;
}
```

**Migration**:
```dart
// Old code
final transfer = TransferDto(
  amount: 100,
  recipientName: 'John Doe',
  date: '2025-10-28',
);

// New code
final transfer = TransferDto(
  amount: 100,
  fromAccount: 'Savings',
  toAccount: 'Checking',
  date: '2025-10-28',
);
```

### 2. Incoming DTO

**Old Structure**:
```dart
class IncomingDto {
  final double amount;
  final String title;
  final String? description;
  final String date;
}
```

**New Structure**:
```dart
class IncomingDto {
  final double amount;
  final String source;
  final String? description;
  final String date;
  final String paymentMethod; // New required field
}
```

**Migration**:
```dart
// Old code
final incoming = IncomingDto(
  amount: 5000,
  title: 'Salary',
  date: '2025-10-28',
);

// New code
final incoming = IncomingDto(
  amount: 5000,
  source: 'Salary',
  paymentMethod: 'bank_transfer',
  date: '2025-10-28',
);
```

### 3. Fund Box DTO

**Old Structure**:
```dart
class FundBoxDto {
  final double balanceUsd;
}
```

**New Structure**:
```dart
class FundBoxDto {
  final double totalBalance;
  final DateTime lastUpdated;
}
```

**Migration**:
```dart
// Old code
final fundBox = FundBoxDto(balanceUsd: 10000);

// New code
final fundBox = FundBoxDto(
  totalBalance: 10000,
  lastUpdated: DateTime.now(),
);
```

## Data Migration Script

The app includes an automatic migration script that runs on first launch:

```dart
class DataMigrator {
  Future<void> migrate() async {
    final version = await _getDataVersion();
    
    if (version < 2) {
      await _migrateToV2();
    }
    
    await _setDataVersion(2);
  }
  
  Future<void> _migrateToV2() async {
    // Migrate transfers
    await _migrateTransfers();
    
    // Migrate incoming
    await _migrateIncoming();
    
    // Migrate fund box
    await _migrateFundBox();
  }
  
  Future<void> _migrateTransfers() async {
    final db = await database;
    final transfers = await db.query('transfers');
    
    for (var transfer in transfers) {
      final recipientName = transfer['recipient_name'] as String?;
      
      // Try to split recipient_name into from_account and to_account
      String fromAccount = 'Unknown';
      String toAccount = recipientName ?? 'Unknown';
      
      if (recipientName?.contains(' to ') == true) {
        final parts = recipientName!.split(' to ');
        fromAccount = parts[0].trim();
        toAccount = parts[1].trim();
      }
      
      await db.update(
        'transfers',
        {
          'from_account': fromAccount,
          'to_account': toAccount,
        },
        where: 'id = ?',
        whereArgs: [transfer['id']],
      );
    }
  }
  
  Future<void> _migrateIncoming() async {
    final db = await database;
    final incoming = await db.query('incoming');
    
    for (var item in incoming) {
      await db.update(
        'incoming',
        {
          'source': item['title'],
          'payment_method': 'cash', // Default value
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
  }
  
  Future<void> _migrateFundBox() async {
    final db = await database;
    final fundBox = await db.query('fund_box');
    
    for (var item in fundBox) {
      await db.update(
        'fund_box',
        {
          'total_balance': item['balance_usd'],
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
  }
}
```

## Conflict Resolution

During sync, you may encounter conflicts if data was modified both locally and on the server:

### Conflict Types

1. **Update Conflict**: Same record modified locally and on server
2. **Delete Conflict**: Record deleted locally but modified on server (or vice versa)

### Resolution Options

When a conflict is detected, you'll see a dialog:

```
Conflict Detected

Local: Amount: $100, Date: 2025-10-28
Server: Amount: $150, Date: 2025-10-27

Which version do you want to keep?
[Keep Local] [Keep Server] [View Details]
```

**Recommendations**:
- **Keep Local**: If you made recent changes that you want to preserve
- **Keep Server**: If the server has the most up-to-date data
- **View Details**: Compare both versions before deciding

## Rollback Procedure

If you encounter issues after migration, you can rollback:

### Step 1: Restore Backup

```dart
// Run this script to restore your backup
dart run scripts/restore_data.dart backup/data_backup_[timestamp].json
```

### Step 2: Reinstall Old Version

```bash
# Checkout previous version
git checkout v1.0.0

# Rebuild
flutter clean
flutter pub get
flutter build apk
```

### Step 3: Report Issue

Please report the issue on GitHub with:
- Error messages
- Steps to reproduce
- Backup file (if possible)

## Common Issues

### Issue 1: Transfer from_account is "Unknown"

**Cause**: Old recipient_name couldn't be split into from_account and to_account

**Solution**: Manually update transfers:
1. Go to Transfers page
2. Tap on transfer
3. Edit from_account and to_account
4. Save

### Issue 2: Incoming payment_method is always "cash"

**Cause**: Old data didn't have payment_method field

**Solution**: Manually update incoming records:
1. Go to Income page
2. Tap on income record
3. Select correct payment method
4. Save

### Issue 3: Sync fails with 422 validation error

**Cause**: Migrated data doesn't meet server validation rules

**Solution**:
1. Check error message for specific field
2. Update the record with valid data
3. Retry sync

### Issue 4: Admin features not showing

**Cause**: User role not properly set

**Solution**:
1. Logout
2. Login again
3. Check profile to verify role
4. Contact admin if role is incorrect

### Issue 5: 401 Unauthorized after update

**Cause**: Token format changed

**Solution**:
1. Logout
2. Login again
3. Token will be refreshed

## Testing After Migration

### Checklist

- [ ] All transfers have valid from_account and to_account
- [ ] All incoming records have valid source and payment_method
- [ ] All expenses have valid payment_method
- [ ] Fund box balance is correct (admin only)
- [ ] Sync completes without errors
- [ ] No data loss
- [ ] All features work as expected
- [ ] Error messages are user-friendly
- [ ] Admin features work (admin only)
- [ ] User features work (all users)

### Test Scenarios

1. **Create New Transfer**
   - Create transfer with from_account and to_account
   - Verify it syncs to server
   - Verify it appears in list

2. **Create New Incoming**
   - Create income with source and payment_method
   - Verify it syncs to server
   - Verify it appears in list

3. **Create New Expense**
   - Create expense with payment_method
   - Verify it syncs to server
   - Verify it appears in list

4. **Test Offline Mode**
   - Turn off internet
   - Create records
   - Turn on internet
   - Verify auto-sync works

5. **Test Admin Features** (Admin only)
   - Access fund box
   - View admin dashboard
   - View audit logs
   - Verify all data is correct

6. **Test Error Handling**
   - Try invalid data
   - Verify validation errors show
   - Try accessing admin features as user
   - Verify access denied message shows

## Support

If you need help with migration:

1. **Documentation**: Check [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
2. **GitHub Issues**: Open an issue with details
3. **Email**: support@example.com
4. **Discord**: Join our community server

## Summary

- Backup your data before updating
- App will automatically migrate local data
- Sync with server after migration
- Verify all data is correct
- Manually update any "Unknown" or default values
- Test all features thoroughly
- Report any issues on GitHub
- Rollback if necessary using backup
