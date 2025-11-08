# Database and Authentication Fixes

## Issues Fixed

### 1. Database Data Clearing
**Problem**: Need to clear all data from SQLite database while preserving structure.

**Solution**: Created `DatabaseUtils` class with methods to:
- Clear all data from all tables
- Recreate default user and fund box
- Get database statistics

**Files Created**:
- `lib/core/utils/database_utils.dart` - Utility functions for database operations
- `lib/features/admin/presentation/pages/database_management_page.dart` - Admin UI for database management

**How to Use**:
1. Log in as an admin user (role = 1)
2. Go to Profile page
3. Click "Database Management" button
4. View database statistics
5. Click "Clear All Data" to delete all records
6. Confirm the action
7. Default user will be recreated with credentials:
   - Email: `default@finance.app`
   - Password: `password`

### 2. PocketBase Integration
**Problem**: App was not properly integrated with PocketBase for authentication.

**Solution**: Updated login and logout use cases to integrate with PocketBase:

**Files Modified**:
- `lib/features/auth/domain/usecases/login_usecase.dart`
  - Now attempts PocketBase login after successful local login
  - Falls back to local-only auth if PocketBase is unavailable
  
- `lib/features/auth/domain/usecases/logout_usecase.dart`
  - Now clears PocketBase auth store on logout
  - Ensures complete logout from both local and cloud

**Behavior**:
- Login: Authenticates with both local database and PocketBase
- Logout: Clears session from both local database and PocketBase
- If PocketBase is unavailable, app continues with local authentication only

### 3. Logout Authorization Error
**Problem**: Logout was showing "not authorized" error but still logging out on app restart.

**Root Cause**: 
- PocketBase auth store was not being cleared on logout
- Session was only cleared from local database
- On app restart, the check found no valid local session and returned to login

**Solution**:
- Integrated PocketBase logout in `LogoutUseCase`
- Now properly clears both local session and PocketBase auth store
- Logout is immediate and complete

## Configuration

### PocketBase URL
Update the PocketBase URL in `lib/core/config/pocketbase_config.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8090'; // Local development
// or
static const String baseUrl = 'https://your-pocketbase-url.com'; // Production
```

### Testing PocketBase Connection

1. **Start PocketBase locally**:
   ```bash
   cd pocketbase-backend-files
   ./pocketbase serve
   ```

2. **Access Admin UI**: http://127.0.0.1:8090/_/

3. **Import Schema**: Upload `pocketbase-backend-files/pb_schema.json`

4. **Test in App**:
   - Register a new user
   - Check PocketBase Admin UI to see if user was created
   - Create an expense
   - Check if expense syncs to PocketBase
   - Logout and verify clean logout

## Database Management Features

### Statistics View
Shows record counts for all tables:
- users
- sessions
- expenses
- incoming
- transfers
- fund_box
- exchange_history
- password_reset_tokens

### Clear All Data
Permanently deletes all records from database:
- ✓ Preserves database structure (tables, indexes)
- ✓ Recreates default user
- ✓ Recreates fund box for default user
- ✗ Cannot be undone
- ⚠️ PocketBase cloud data remains intact

### Access Control
- Database Management page is only accessible to admin users (role = 1)
- Regular users (role = 0) will not see the button

## Default User Credentials

After clearing database or fresh install:
- **Email**: `default@finance.app`
- **Password**: `password`
- **Role**: 0 (regular user)

To create an admin user, manually update the role in the database:
```sql
UPDATE users SET role = 1 WHERE email = 'your@email.com';
```

## Testing Checklist

- [ ] Clear database data successfully
- [ ] Default user recreated after clear
- [ ] Can log in with default credentials
- [ ] PocketBase login works
- [ ] PocketBase logout works
- [ ] No "not authorized" error on logout
- [ ] Logout is immediate (no need to restart app)
- [ ] Database statistics display correctly
- [ ] Admin-only access to database management

## Notes

- Database clearing is a destructive operation - use with caution
- Always backup important data before clearing
- PocketBase data is independent and not affected by local database clearing
- If PocketBase is unavailable, app continues to work with local data only
- Sync will resume automatically when PocketBase becomes available

## Future Improvements

1. Add database export/import functionality
2. Add selective data clearing (e.g., clear only expenses)
3. Add database backup before clearing
4. Add PocketBase connection status indicator
5. Add manual sync trigger for PocketBase
6. Add conflict resolution for offline changes
