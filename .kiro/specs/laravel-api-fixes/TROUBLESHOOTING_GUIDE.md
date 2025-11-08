# Troubleshooting Guide

## Overview

This guide provides solutions to common issues encountered with the Laravel API integration.

## Connection Issues

### Issue: "Unable to connect to server"

**Symptoms**:
- App shows "Unable to connect to server" error
- All API calls fail
- Sync doesn't work

**Possible Causes**:
1. Laravel backend is not running
2. Wrong API URL configured
3. Network connectivity issues
4. Firewall blocking connection

**Solutions**:

1. **Check Laravel Backend**
   ```bash
   # Navigate to backend directory
   cd financeApp-backend-main
   
   # Start Laravel server
   php artisan serve
   
   # Should show: Laravel development server started on http://127.0.0.1:8000
   ```

2. **Verify API URL**
   ```dart
   // In lib/core/config/api_config.dart
   static const String baseUrl = 'http://localhost:8000/api/v1';
   
   // For Android emulator, use:
   static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
   
   // For physical device, use your computer's IP:
   static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
   ```

3. **Test Connection**
   ```bash
   # Test from command line
   curl http://localhost:8000/api/v1/health
   
   # Should return: {"status":"ok"}
   ```

4. **Check Firewall**
   - Windows: Allow port 8000 in Windows Firewall
   - Mac: System Preferences > Security & Privacy > Firewall
   - Linux: `sudo ufw allow 8000`

### Issue: "Request timed out"

**Symptoms**:
- API calls take too long and fail
- App shows "Request timed out" error

**Solutions**:

1. **Increase Timeout**
   ```dart
   // In lib/core/api/api_client.dart
   final dio = Dio(BaseOptions(
     connectTimeout: Duration(seconds: 30),
     receiveTimeout: Duration(seconds: 30),
   ));
   ```

2. **Check Server Performance**
   ```bash
   # Check Laravel logs
   tail -f storage/logs/laravel.log
   
   # Check for slow queries
   php artisan telescope:prune
   ```

3. **Optimize Database**
   ```bash
   # Run migrations
   php artisan migrate
   
   # Clear cache
   php artisan cache:clear
   php artisan config:clear
   ```

## Authentication Issues

### Issue: "Session expired. Please login again."

**Symptoms**:
- Randomly logged out
- 401 Unauthorized errors
- Token validation fails

**Solutions**:

1. **Check Token Expiration**
   ```php
   // In Laravel config/sanctum.php
   'expiration' => 60 * 24 * 7, // 7 days
   ```

2. **Clear Stored Token**
   ```dart
   // In app
   await tokenManager.clearToken();
   await authService.logout();
   ```

3. **Login Again**
   - Go to login page
   - Enter credentials
   - Token will be refreshed

### Issue: "Invalid credentials"

**Symptoms**:
- Login fails with "Invalid credentials"
- Correct email and password don't work

**Solutions**:

1. **Verify User Exists**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Check user
   User::where('email', 'user@example.com')->first();
   ```

2. **Reset Password**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Reset password
   $user = User::where('email', 'user@example.com')->first();
   $user->password = Hash::make('newpassword');
   $user->save();
   ```

3. **Check Email Format**
   - Email must be valid format
   - No spaces before or after
   - Case-insensitive

### Issue: "Access denied. Admin privileges required."

**Symptoms**:
- 403 Forbidden errors
- Admin features not accessible
- Fund box shows access denied

**Solutions**:

1. **Check User Role**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Check role
   $user = User::where('email', 'user@example.com')->first();
   echo $user->role; // Should be 'admin' for admin features
   ```

2. **Update User Role**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Set as admin
   $user = User::where('email', 'user@example.com')->first();
   $user->role = 'admin';
   $user->save();
   ```

3. **Logout and Login**
   - Logout from app
   - Login again
   - Role will be refreshed

## Data Issues

### Issue: "Validation failed" (422 Error)

**Symptoms**:
- Create/update operations fail
- Shows field-specific errors
- Data not saved

**Common Validation Errors**:

1. **Amount is required**
   ```dart
   // Ensure amount is provided and > 0
   final expense = ExpenseDto(
     amount: 100.50, // Must be > 0
     category: 'Food',
     date: '2025-10-28',
     paymentMethod: 'cash',
   );
   ```

2. **Invalid payment method**
   ```dart
   // Must be: cash, card, or bank_transfer
   paymentMethod: 'cash' // ✓ Valid
   paymentMethod: 'credit' // ✗ Invalid
   ```

3. **Invalid date format**
   ```dart
   // Must be YYYY-MM-DD
   date: '2025-10-28' // ✓ Valid
   date: '10/28/2025' // ✗ Invalid
   date: '28-10-2025' // ✗ Invalid
   ```

4. **Email already exists**
   ```dart
   // Use different email or update existing user
   email: 'unique@example.com'
   ```

### Issue: Transfers showing "Unknown" account

**Symptoms**:
- from_account shows "Unknown"
- Old transfers not migrated properly

**Solutions**:

1. **Manual Update**
   - Go to Transfers page
   - Tap on transfer
   - Edit from_account and to_account
   - Save

2. **Batch Update Script**
   ```dart
   // Run migration script
   dart run scripts/fix_transfers.dart
   ```

### Issue: Incoming payment_method always "cash"

**Symptoms**:
- All income records show cash payment method
- Can't change payment method

**Solutions**:

1. **Manual Update**
   - Go to Income page
   - Tap on income record
   - Select correct payment method
   - Save

2. **Update in Database**
   ```sql
   -- In SQLite database
   UPDATE incoming 
   SET payment_method = 'bank_transfer' 
   WHERE source = 'Salary';
   ```

## Sync Issues

### Issue: "Sync failed"

**Symptoms**:
- Sync doesn't complete
- Shows error message
- Data not synchronized

**Solutions**:

1. **Check Network Connection**
   - Ensure internet is available
   - Try opening a website
   - Check WiFi/mobile data

2. **Check Server Status**
   ```bash
   # Test API endpoint
   curl http://localhost:8000/api/v1/sync/changes
   ```

3. **Clear Sync Queue**
   ```dart
   // In app settings
   Settings > Advanced > Clear Sync Queue
   ```

4. **Force Sync**
   ```dart
   // In app
   Settings > Sync > Force Sync
   ```

### Issue: Sync conflicts

**Symptoms**:
- Shows conflict resolution dialog
- Same record modified locally and on server

**Solutions**:

1. **Choose Correct Version**
   - **Keep Local**: If local changes are more recent
   - **Keep Server**: If server has correct data
   - **View Details**: Compare both versions

2. **Resolve Manually**
   - View both versions
   - Create new record with correct data
   - Delete conflicting records

### Issue: Offline changes not syncing

**Symptoms**:
- Created records offline
- Records don't appear after going online
- Sync queue not processing

**Solutions**:

1. **Check Sync Queue**
   ```dart
   // View pending operations
   Settings > Sync > View Queue
   ```

2. **Retry Sync**
   ```dart
   // Manually trigger sync
   Settings > Sync > Sync Now
   ```

3. **Check Queue Manager**
   ```dart
   // In code
   final queueSize = await queueManager.getQueueSize();
   print('Pending operations: $queueSize');
   ```

## Performance Issues

### Issue: App is slow

**Symptoms**:
- Slow loading times
- Laggy UI
- High memory usage

**Solutions**:

1. **Clear Cache**
   ```dart
   // In app
   Settings > Advanced > Clear Cache
   ```

2. **Reduce Page Size**
   ```dart
   // In API calls
   final expenses = await expenseApiDataSource.getExpenses(
     perPage: 10, // Reduce from 15 to 10
   );
   ```

3. **Enable Pagination**
   ```dart
   // Use infinite scroll instead of loading all data
   InfiniteScrollList(
     onLoadMore: () => loadMoreExpenses(),
   );
   ```

4. **Optimize Images**
   ```dart
   // Compress images before upload
   final compressed = await imageCompression.compress(file);
   ```

### Issue: High data usage

**Symptoms**:
- App uses too much mobile data
- Slow sync on mobile network

**Solutions**:

1. **Enable WiFi-Only Sync**
   ```dart
   // In app settings
   Settings > Sync > WiFi Only
   ```

2. **Reduce Sync Frequency**
   ```dart
   // In app settings
   Settings > Sync > Sync Interval > Manual
   ```

3. **Compress Uploads**
   ```dart
   // Enable compression
   Settings > Advanced > Compress Uploads
   ```

## Admin Features Issues

### Issue: Fund box not loading

**Symptoms**:
- Fund box shows loading forever
- Error: "Access denied"
- Balance not displayed

**Solutions**:

1. **Verify Admin Role**
   ```bash
   # Check user role in Laravel
   php artisan tinker
   User::where('email', 'admin@example.com')->first()->role;
   ```

2. **Check API Endpoint**
   ```bash
   # Test fund box endpoint
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/api/v1/fund-box
   ```

3. **Clear App Data**
   - Logout
   - Clear app data
   - Login again

### Issue: Admin dashboard shows no data

**Symptoms**:
- Dashboard is empty
- Stats show 0
- No users or expenses displayed

**Solutions**:

1. **Check Database**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Check data
   User::count();
   Expense::count();
   ```

2. **Seed Test Data**
   ```bash
   # In Laravel backend
   php artisan db:seed
   ```

3. **Check API Response**
   ```bash
   # Test dashboard endpoint
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/api/v1/admin/dashboard/stats
   ```

### Issue: Audit logs not showing

**Symptoms**:
- Audit logs page is empty
- No log entries displayed

**Solutions**:

1. **Check Audit Logging**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Check logs
   AuditLog::count();
   ```

2. **Enable Audit Logging**
   ```php
   // In Laravel config/audit.php
   'enabled' => true,
   ```

3. **Trigger Some Actions**
   - Create an expense
   - Update a transfer
   - Check audit logs again

## File Upload Issues

### Issue: File upload fails

**Symptoms**:
- Upload shows error
- File not uploaded
- Shows "File too large" error

**Solutions**:

1. **Check File Size**
   ```dart
   // Max file size: 10MB
   if (file.lengthSync() > 10 * 1024 * 1024) {
     showError('File too large. Max size: 10MB');
     return;
   }
   ```

2. **Check File Type**
   ```dart
   // Allowed types: jpg, png, pdf
   final allowedTypes = ['jpg', 'jpeg', 'png', 'pdf'];
   final extension = file.path.split('.').last.toLowerCase();
   
   if (!allowedTypes.contains(extension)) {
     showError('Invalid file type. Allowed: JPG, PNG, PDF');
     return;
   }
   ```

3. **Compress Image**
   ```dart
   // Compress before upload
   final compressed = await imageCompression.compress(file);
   await fileUploadService.uploadFile(file: compressed);
   ```

### Issue: File download fails

**Symptoms**:
- Download shows error
- File not downloaded
- Shows "File not found" error

**Solutions**:

1. **Check File Path**
   ```dart
   // Ensure path is encrypted path from upload response
   final encryptedPath = upload.path;
   await fileUploadService.downloadFile(encryptedPath);
   ```

2. **Check File Exists**
   ```bash
   # In Laravel backend
   php artisan tinker
   
   # Check file
   Storage::exists($path);
   ```

3. **Check Permissions**
   ```bash
   # In Laravel backend
   chmod -R 775 storage/app/uploads
   ```

## Export Issues

### Issue: Export fails

**Symptoms**:
- Export shows error
- PDF/Excel not generated
- Status stuck on "processing"

**Solutions**:

1. **Check Queue Worker**
   ```bash
   # In Laravel backend
   php artisan queue:work
   ```

2. **Check Export Status**
   ```dart
   // Poll status
   final status = await exportApiDataSource.getExportStatus(exportId);
   print('Status: ${status.status}');
   ```

3. **Check Laravel Logs**
   ```bash
   # In Laravel backend
   tail -f storage/logs/laravel.log
   ```

### Issue: Export download fails

**Symptoms**:
- Download button doesn't work
- File not downloaded
- Shows "Export not ready" error

**Solutions**:

1. **Wait for Completion**
   - Export takes time to generate
   - Wait for status to be "completed"
   - Then download

2. **Check Download URL**
   ```dart
   // Ensure download URL is available
   if (export.downloadUrl != null) {
     await exportApiDataSource.downloadExport(export.id);
   }
   ```

## Getting Help

### Debug Mode

Enable debug mode to see detailed logs:

```dart
// In lib/main.dart
void main() {
  if (kDebugMode) {
    ApiLogger.enableDebugMode();
  }
  runApp(MyApp());
}
```

### Logs

Check logs for detailed error information:

```dart
// App logs
Settings > Advanced > View Logs

// Laravel logs
tail -f storage/logs/laravel.log
```

### Report Issue

If you can't resolve the issue:

1. **Gather Information**
   - Error message
   - Steps to reproduce
   - App version
   - Device information
   - Logs

2. **Create GitHub Issue**
   - Go to GitHub repository
   - Click "New Issue"
   - Provide all information
   - Attach logs if possible

3. **Contact Support**
   - Email: support@example.com
   - Discord: Join our community
   - Include issue details

## Common Error Messages

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Session expired" | Token expired | Login again |
| "Access denied" | Insufficient permissions | Check user role |
| "Validation failed" | Invalid data | Check field values |
| "Resource not found" | Record doesn't exist | Refresh data |
| "Too many requests" | Rate limit exceeded | Wait and retry |
| "Server error" | Backend issue | Check Laravel logs |
| "No internet connection" | Network issue | Check connectivity |
| "Request timed out" | Slow connection | Increase timeout |
| "Invalid payment method" | Wrong value | Use cash/card/bank_transfer |
| "Invalid date format" | Wrong format | Use YYYY-MM-DD |

## Summary

- Check connection and server status first
- Verify authentication and role
- Validate data format before submission
- Use debug mode for detailed logs
- Check Laravel logs for backend issues
- Report persistent issues on GitHub
- Contact support if needed
