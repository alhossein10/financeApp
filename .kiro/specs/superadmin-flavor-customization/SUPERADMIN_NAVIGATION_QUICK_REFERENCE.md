# SuperAdmin Navigation - Quick Reference

## Navigation Structure

### Bottom Navigation Bar (3 items)
1. **Groups** 👥
   - Icon: `Icons.group`
   - Page: `GroupManagementPage`
   - Purpose: Manage admin groups and members

2. **Cash** 💰
   - Icon: `Icons.account_balance_wallet`
   - Page: `SuperAdminCashPage`
   - Purpose: View fund box and manage outgoing transfers

3. **Expenses** 🧾
   - Icon: `Icons.receipt_long`
   - Page: `SuperAdminExpensesPage`
   - Purpose: View aggregated expenses by admin group

### AppBar Actions
- **Profile** 👤
  - Icon: `Icons.person`
  - Page: `ProfilePage`
  - Purpose: View and edit profile, logout

## What's Included for SuperAdmin

✅ **Group Management**
- View group code
- Manage group members
- Remove members
- Regenerate group code

✅ **Cash Management**
- View fund box balance (USD, SYP, TRY)
- Create outgoing transfers to admins
- View outgoing transfer history
- Filter recipients to admins only

✅ **Expense Monitoring**
- View expense summaries by admin group
- Filter by admin group
- View detailed expenses per group
- See status breakdown (pending, approved, rejected)
- Read-only view (no expense creation)

✅ **Profile**
- View profile information
- Edit profile
- Change password
- Logout

## What's Removed for SuperAdmin

❌ **Currency Exchange (تصريف)**
- Not needed for SuperAdmin role
- SuperAdmin doesn't perform currency exchanges

❌ **Export Page**
- Not needed for SuperAdmin role
- Export functionality not required

❌ **Exchange History**
- Not needed for SuperAdmin role
- No exchange transactions to view

❌ **Incoming Transfers**
- SuperAdmin only sends transfers (outgoing)
- Does not receive transfers from others

❌ **User Cash Inbox**
- Replaced with SuperAdmin Cash Page
- Different functionality for SuperAdmin role

## Navigation Flow

```
Login/Register (SuperAdmin)
    ↓
Home (Group Management) ← Default landing page
    ↓
Bottom Navigation:
    ├─ Groups (Group Management)
    ├─ Cash (SuperAdmin Cash Page)
    └─ Expenses (SuperAdmin Expenses Page)

AppBar:
    └─ Profile (Profile Page)
```

## Key Differences from Admin/User

| Feature | SuperAdmin | Admin | User |
|---------|-----------|-------|------|
| Group Management | ✅ | ✅ | ❌ |
| Cash Page | SuperAdmin Cash | Admin Cash Inbox | User Cash Inbox |
| Transfers | Outgoing only | Both | Incoming only |
| Currency Exchange | ❌ | ✅ | ✅ |
| Expenses | Aggregated view | Full CRUD | Full CRUD |
| Export | ❌ | ✅ | ✅ |
| Exchange History | ❌ | ✅ | ✅ |

## Implementation Details

### Flavor Detection
```dart
if (_flavorConfig.isSuperAdmin) {
  // SuperAdmin navigation
}
```

### Configuration Flags
```dart
enableSuperAdminCashPage: true
enableSuperAdminExpensesPage: true
showIncomingTransfers: false
showExchangeHistory: false
enableCurrencyModule: false
enableExportModule: false
```

### Page Order
1. Group Management (index 0)
2. SuperAdmin Cash Page (index 1)
3. SuperAdmin Expenses Page (index 2)

### BLoC Providers
- **Group Management**: AdminGroupBloc
- **SuperAdmin Cash**: FundBoxBloc, TransferBloc, AdminGroupBloc
- **SuperAdmin Expenses**: None (uses direct API datasource)

## Testing Checklist

- [ ] SuperAdmin sees only 3 bottom navigation items
- [ ] Navigation items are in correct order
- [ ] Icons are appropriate for each page
- [ ] Profile is accessible via AppBar
- [ ] Currency Exchange is not accessible
- [ ] Export page is not accessible
- [ ] Exchange History is not accessible
- [ ] Incoming transfers are not shown
- [ ] Page state is preserved when navigating
- [ ] Navigation works correctly between all pages

## Related Files
- `lib/main.dart` - Navigation implementation
- `lib/core/config/flavor_config.dart` - Flavor configuration
- `lib/ui/superadmin_cash_page.dart` - SuperAdmin cash page
- `lib/ui/superadmin_expenses_page.dart` - SuperAdmin expenses page
- `lib/features/admin_group/presentation/pages/group_management_page.dart` - Group management
