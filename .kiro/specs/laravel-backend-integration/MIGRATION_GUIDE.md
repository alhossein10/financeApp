# Migration Guide - Laravel Backend Integration

## Overview

This guide provides step-by-step instructions for migrating from the old SQLite/Supabase/PocketBase architecture to the new Laravel backend integration.

## Table of Contents

1. [Pre-Migration Checklist](#pre-migration-checklist)
2. [Data Backup](#data-backup)
3. [Migration Process](#migration-process)
4. [Post-Migration Verification](#post-migration-verification)
5. [Rollback Procedure](#rollback-procedure)
6. [Troubleshooting](#troubleshooting)

---

## Pre-Migration Checklist

Before starting the migration, ensure:

- [ ] Laravel backend is deployed and accessible
- [ ] Database is set up and migrations are run
- [ ] API endpoints are tested and working
- [ ] You have admin access to the backend
- [ ] You have a stable internet connection
- [ ] App is updated to version 2.0.0 or later
- [ ] You have backed up all local data

---

## Data Backup

### Automatic Backup

The app automatically backs up your data before migration:

1. Open the app
2. Go to **Profile** → **Settings**
3. Tap **"Backup Data"**
4. Wait for backup to complete
5. Backup is saved to your device

### Manual Backup

To manually export your data:

1. Go to **Profile** → **Settings**
2. Tap **"Export Data"**
3. Choose export format (JSON recommended)
4. Save the file to a safe location
5. Keep this file until migration is verified

### What Gets Backed Up

- All expenses with invoice paths
- All transfers with exchange information
- All incoming transactions
- User profile information
- App settings and preferences

**Note**: Invoice images are backed up separately. Ensure you have enough storage space.

---

## Migration Process

### Step 1: Prepare for Migration

1. **Update the App**
   - Ensure you're running version 2.0.0 or later
   - Check for updates in your app store

2. **Verify Internet Connection**
   - Connect to a stable WiFi network
   - Avoid using mobile data for large migrations

3. **Close Other Apps**
   - Free up device resources
   - Ensure smooth migration process

### Step 2: Start Migration

1. Open the Finance App
2. You'll see a migration prompt on first launch
3. Tap **"Start Migration"**
4. Or go to **Profile** → **Settings** → **Migrate to Laravel Backend**

### Step 3: Login or Register

If you're a new user:
1. Tap **"Create Account"**
2. Enter your information
3. Tap **"Register"**

If you're an existing user:
1. Enter your email and password
2. Tap **"Login"**

### Step 4: Data Migration

The migration process has several phases:

**Phase 1: Data Export (1-2 minutes)**
- Exporting expenses from local database
- Exporting transfers from local database
- Exporting incoming transactions
- Preparing invoice files

**Phase 2: Data Upload (2-5 minutes)**
- Uploading expenses to Laravel backend
- Uploading transfers to Laravel backend
- Uploading incoming transactions
- Uploading invoice images

**Phase 3: Verification (1 minute)**
- Verifying all records were uploaded
- Checking data integrity
- Confirming invoice uploads

**Phase 4: Cleanup (30 seconds)**
- Removing old local database
- Clearing temporary files
- Finalizing migration

### Step 5: Migration Progress

During migration, you'll see:
- Progress bar showing completion percentage
- Current phase and operation
- Number of records processed
- Estimated time remaining

**Do not close the app during migration!**

### Step 6: Migration Complete

When migration is complete:
1. You'll see a success message
2. Tap **"Continue"** to use the app
3. Your data is now on the Laravel backend
4. Old local database is removed

---

## Post-Migration Verification

### Verify Your Data

After migration, verify your data:

1. **Check Expenses**
   - Go to Expenses tab
   - Verify all expenses are present
   - Check amounts and dates
   - Open a few expenses to verify details
   - Verify invoices are accessible

2. **Check Transfers**
   - Go to Transfers tab
   - Verify all transfers are present
   - Check exchange information
   - Verify amounts and dates

3. **Check Incoming**
   - Go to Incoming tab
   - Verify all transactions are present
   - Check amounts and dates

4. **Check Totals**
   - Compare totals with your backup
   - Verify currency amounts match
   - Check date ranges

### Verify Invoices

1. Open several expenses with invoices
2. Tap on invoice thumbnails
3. Verify images load correctly
4. Check image quality

### Test Functionality

1. **Create New Expense**
   - Add a test expense
   - Verify it appears in the list
   - Delete the test expense

2. **Edit Existing Record**
   - Edit an expense
   - Verify changes are saved
   - Check sync status

3. **Test Offline Mode**
   - Turn on airplane mode
   - Create a test expense
   - Turn off airplane mode
   - Verify it syncs automatically

---

## Rollback Procedure

If migration fails or you encounter issues, you can rollback:

### Automatic Rollback

If migration fails, the app automatically:
1. Stops the migration process
2. Restores your local database
3. Shows an error message
4. Allows you to retry

### Manual Rollback

To manually rollback:

1. **Restore from Backup**
   - Go to Profile → Settings
   - Tap "Restore from Backup"
   - Select your backup file
   - Wait for restoration to complete

2. **Reinstall Previous Version**
   - Uninstall the current app
   - Install version 1.x from backup
   - Your local data will be intact

3. **Contact Support**
   - If rollback fails, contact support
   - Provide your backup file
   - Support will assist with restoration

### When to Rollback

Consider rollback if:
- Migration fails multiple times
- Data is missing after migration
- Invoices are not accessible
- App is unstable after migration

---

## Troubleshooting

### Migration Fails to Start

**Problem**: Migration button is grayed out or doesn't respond

**Solutions**:
1. Check internet connection
2. Restart the app
3. Update to latest version
4. Clear app cache

### Migration Stuck at Export Phase

**Problem**: Export phase takes too long or appears stuck

**Solutions**:
1. Wait at least 5 minutes (large datasets take time)
2. Check available storage space
3. Close other apps to free memory
4. Restart the app and try again

### Migration Fails During Upload

**Problem**: Upload phase fails with error

**Solutions**:
1. Check internet connection
2. Verify Laravel backend is accessible
3. Check if you have sufficient API rate limits
4. Try again during off-peak hours
5. Contact support if issue persists

### Some Records Missing After Migration

**Problem**: Not all records appear after migration

**Solutions**:
1. Pull down to refresh the list
2. Check date filters (may be hiding records)
3. Go to Profile → Sync Status
4. Tap "Retry Failed Operations"
5. If still missing, restore from backup

### Invoices Not Loading

**Problem**: Invoice images don't load after migration

**Solutions**:
1. Check internet connection
2. Wait a few minutes (images may still be uploading)
3. Go to Profile → Sync Status
4. Check for failed invoice uploads
5. Retry failed uploads

### "Unauthorized" Error After Migration

**Problem**: You see "Unauthorized" errors

**Solutions**:
1. Log out and log back in
2. Check if your account is active
3. Verify email and password
4. Contact admin if you're locked out

### App Crashes After Migration

**Problem**: App crashes or freezes after migration

**Solutions**:
1. Restart the app
2. Clear app cache
3. Reinstall the app (data is on server)
4. Update to latest version
5. Contact support with crash logs

---

## Migration for Different User Types

### Regular Users

1. Follow standard migration process
2. All your personal data will be migrated
3. You'll only see your own data after migration

### Admin Users

1. Follow standard migration process
2. Your admin privileges will be preserved
3. You'll have access to admin features after migration
4. You can view system-wide data

### Multiple Devices

If you use multiple devices:

1. **Migrate on Primary Device First**
   - Complete migration on one device
   - Verify data is correct

2. **Update Other Devices**
   - Update app on other devices
   - Log in with same credentials
   - Your data will sync automatically
   - No need to migrate again

---

## Data Migration Details

### What Gets Migrated

✅ **Migrated**:
- All expenses with descriptions, amounts, dates
- All transfers with exchange information
- All incoming transactions
- Invoice images
- User profile information

❌ **Not Migrated**:
- App settings (will use defaults)
- Cached data (will be re-cached)
- Temporary files
- Old sync logs

### Data Transformation

During migration, data is transformed:

1. **Local IDs → Server IDs**
   - Local temporary IDs are replaced with server IDs
   - Relationships are maintained

2. **Timestamps**
   - Local timestamps are preserved
   - Server adds created_at and updated_at

3. **File Paths**
   - Local file paths are replaced with server URLs
   - Images are uploaded to server storage

4. **Sync Status**
   - All records marked as "synced" after migration
   - No pending operations

---

## Performance Considerations

### Migration Time Estimates

| Data Size | Estimated Time |
|-----------|----------------|
| < 100 records | 2-3 minutes |
| 100-500 records | 5-10 minutes |
| 500-1000 records | 10-20 minutes |
| > 1000 records | 20-30 minutes |

**Note**: Time varies based on:
- Internet connection speed
- Number of invoice images
- Server load
- Device performance

### Optimizing Migration

To speed up migration:

1. **Use WiFi**: Faster than mobile data
2. **Close Other Apps**: Free up resources
3. **Charge Device**: Prevent interruption
4. **Off-Peak Hours**: Less server load
5. **Stable Connection**: Avoid moving during migration

---

## Post-Migration Benefits

After successful migration, you'll enjoy:

1. **Centralized Data**: Access from any device
2. **Better Sync**: Real-time synchronization
3. **Improved Performance**: Faster data loading
4. **Enhanced Security**: Server-side encryption
5. **Better Offline Support**: Robust queue system
6. **Admin Features**: Enhanced admin capabilities
7. **Data Export**: Easy PDF/Excel exports
8. **Audit Logs**: Track all changes (admin)

---

## Support

### Getting Help

If you need assistance:

1. **In-App Help**
   - Profile → Help & Support
   - Migration FAQ
   - Contact support

2. **Email Support**
   - support@example.com
   - Include:
     - Device model
     - App version
     - Error messages
     - Screenshots

3. **Emergency Support**
   - For critical issues
   - Call: [Support Phone]
   - Available 24/7

### Reporting Issues

When reporting migration issues:

1. Note the exact error message
2. Take screenshots
3. Note which phase failed
4. Provide approximate data size
5. Describe what you were doing

---

## Frequently Asked Questions

**Q: Will I lose my data during migration?**
A: No, your data is backed up automatically. If migration fails, data is restored.

**Q: Can I use the app during migration?**
A: No, please wait for migration to complete. It usually takes 5-10 minutes.

**Q: What if I don't have internet during migration?**
A: Migration requires internet. Connect to WiFi before starting.

**Q: Can I cancel migration once started?**
A: No, let it complete. If it fails, it will rollback automatically.

**Q: Will my invoices be migrated?**
A: Yes, all invoice images are uploaded to the server.

**Q: Do I need to migrate on all my devices?**
A: No, migrate once, then log in on other devices.

**Q: What happens to my old data?**
A: After successful migration, old local database is removed.

**Q: Can I migrate again if something goes wrong?**
A: Yes, you can retry migration if it fails.

---

## Conclusion

Migration to Laravel backend is a one-time process that significantly improves your experience with Finance App. Follow this guide carefully, and don't hesitate to contact support if you need help.

**Remember**: Your data is safe. We've tested the migration process extensively, and automatic backups ensure you won't lose any information.

Good luck with your migration!
