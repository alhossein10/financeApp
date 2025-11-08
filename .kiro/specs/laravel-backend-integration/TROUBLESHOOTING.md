# Troubleshooting Guide

## Overview

This guide helps you resolve common issues with the Finance App Laravel backend integration.

## Quick Diagnostics

Before troubleshooting, check these basics:

- [ ] Internet connection is active
- [ ] App is updated to latest version
- [ ] You're logged in
- [ ] Server is not under maintenance

---

## Authentication Issues

### Cannot Login

**Symptoms**:
- "Invalid credentials" error
- Login button doesn't respond
- App crashes on login

**Solutions**:

1. **Verify Credentials**
   ```
   - Check email spelling
   - Verify password (case-sensitive)
   - Try "Forgot Password" if unsure
   ```

2. **Check Internet Connection**
   ```
   - Open browser and visit a website
   - Toggle WiFi off and on
   - Try mobile data if WiFi fails
   ```

3. **Clear App Cache**
   ```
   - Go to device Settings
   - Apps → Finance App
   - Clear Cache (not Clear Data)
   - Reopen app and try again
   ```

4. **Update App**
   ```
   - Check app store for updates
   - Install latest version
   - Try logging in again
   ```

### Session Expired Frequently

**Symptoms**:
- "Session expired" message appears often
- Logged out unexpectedly
- Need to login multiple times per day

**Solutions**:

1. **Check Token Expiration Settings**
   ```
   - Contact admin to extend token lifetime
   - Default is 30 days
   ```

2. **Verify Device Time**
   ```
   - Go to device Settings
   - Date & Time
   - Enable "Automatic date & time"
   ```

3. **Clear Secure Storage**
   ```
   - Go to Profile → Settings
   - Tap "Clear Secure Storage"
   - Log in again
   ```

### Forgot Password Not Working

**Symptoms**:
- Reset email not received
- Reset link doesn't work
- "Invalid token" error

**Solutions**:

1. **Check Email**
   ```
   - Check spam/junk folder
   - Wait 5-10 minutes for email
   - Verify email address is correct
   ```

2. **Request New Link**
   ```
   - Reset links expire after 1 hour
   - Request a new reset link
   - Use it immediately
   ```

3. **Contact Support**
   ```
   - If still not working, email support
   - Provide your registered email
   - Support can reset manually
   ```

---

## Data Sync Issues

### Data Not Syncing

**Symptoms**:
- Changes don't appear on other devices
- "Pending sync" status persists
- Sync icon keeps spinning

**Solutions**:

1. **Check Connectivity**
   ```
   - Verify internet connection
   - Check if server is accessible
   - Try opening a website
   ```

2. **Manual Sync**
   ```
   - Pull down on any list to refresh
   - Or go to Profile → Sync Now
   - Wait for sync to complete
   ```

3. **Check Sync Status**
   ```
   - Go to Profile → Sync Status
   - View pending operations
   - Tap "Retry Failed Operations"
   ```

4. **Clear Queue**
   ```
   - If sync is stuck, clear queue:
   - Profile → Settings → Clear Sync Queue
   - Warning: This removes pending changes
   ```

### Duplicate Records

**Symptoms**:
- Same expense appears twice
- Multiple copies of transfers
- Duplicate incoming transactions

**Solutions**:

1. **Delete Duplicates**
   ```
   - Identify duplicate records
   - Delete extra copies manually
   - Keep the most recent version
   ```

2. **Prevent Future Duplicates**
   ```
   - Don't tap "Save" multiple times
   - Wait for confirmation before closing
   - Ensure stable internet during save
   ```

3. **Report to Support**
   ```
   - If duplicates persist, contact support
   - Provide screenshots
   - Support can clean up database
   ```

### Sync Conflicts

**Symptoms**:
- "Conflict detected" message
- Data differs between devices
- Changes overwritten

**Solutions**:

1. **Choose Resolution Strategy**
   ```
   - Server Wins: Use server version
   - Client Wins: Use local version
   - Manual: Review and choose
   ```

2. **Prevent Conflicts**
   ```
   - Sync before making changes
   - Avoid editing same record on multiple devices
   - Use one device at a time
   ```

---

## Performance Issues

### App is Slow

**Symptoms**:
- Long loading times
- Laggy scrolling
- Delayed responses

**Solutions**:

1. **Clear Cache**
   ```
   - Profile → Settings → Clear Cache
   - This removes cached data
   - Fresh data will be downloaded
   ```

2. **Reduce Data Load**
   ```
   - Use date filters to load less data
   - Limit results to recent records
   - Avoid loading all data at once
   ```

3. **Check Internet Speed**
   ```
   - Run speed test
   - Switch to faster WiFi if available
   - Close bandwidth-heavy apps
   ```

4. **Restart App**
   ```
   - Close app completely
   - Clear from recent apps
   - Reopen and try again
   ```

5. **Update App**
   ```
   - Check for app updates
   - Install latest version
   - Performance improvements included
   ```

### High Data Usage

**Symptoms**:
- App uses too much mobile data
- Data plan exhausted quickly
- Large downloads

**Solutions**:

1. **Use WiFi**
   ```
   - Connect to WiFi for syncing
   - Disable mobile data for app
   - Sync only on WiFi
   ```

2. **Reduce Image Quality**
   ```
   - Profile → Settings
   - Image Quality → Low
   - Reduces upload/download size
   ```

3. **Limit Sync Frequency**
   ```
   - Profile → Settings
   - Auto Sync → Manual
   - Sync only when needed
   ```

### Battery Drain

**Symptoms**:
- App drains battery quickly
- Device gets hot
- Battery percentage drops fast

**Solutions**:

1. **Disable Background Sync**
   ```
   - Profile → Settings
   - Background Sync → Off
   - Sync manually when needed
   ```

2. **Reduce Sync Frequency**
   ```
   - Profile → Settings
   - Sync Interval → 1 hour (or more)
   ```

3. **Close App When Not in Use**
   ```
   - Don't leave app running in background
   - Close completely after use
   ```

---

## File Upload Issues

### Invoice Upload Fails

**Symptoms**:
- "Upload failed" error
- Invoice doesn't appear
- Upload progress stuck

**Solutions**:

1. **Check File Size**
   ```
   - Maximum file size: 10MB
   - Compress large images
   - Use lower resolution
   ```

2. **Check Internet Connection**
   ```
   - Verify stable connection
   - Use WiFi for large uploads
   - Avoid moving during upload
   ```

3. **Retry Upload**
   ```
   - Tap "Retry" button
   - Or delete and re-upload
   - Try different image if persists
   ```

4. **Check File Format**
   ```
   - Supported: JPG, PNG, PDF
   - Convert if using other format
   - Avoid corrupted files
   ```

### Invoice Not Loading

**Symptoms**:
- Invoice thumbnail shows error
- Full image doesn't load
- "Failed to load" message

**Solutions**:

1. **Check Internet Connection**
   ```
   - Verify connection is active
   - Try refreshing the page
   - Wait a few seconds
   ```

2. **Clear Image Cache**
   ```
   - Profile → Settings
   - Clear Image Cache
   - Reload the invoice
   ```

3. **Re-upload Invoice**
   ```
   - Delete current invoice
   - Upload again
   - Verify it loads correctly
   ```

---

## Error Messages

### "Unauthorized" (401)

**Meaning**: Your session has expired or token is invalid

**Solutions**:
1. Log out and log back in
2. Clear app data and login again
3. Contact support if persists

### "Forbidden" (403)

**Meaning**: You don't have permission for this action

**Solutions**:
1. Verify you're logged in as correct user
2. Contact admin for permission
3. Check if feature requires admin access

### "Not Found" (404)

**Meaning**: The requested resource doesn't exist

**Solutions**:
1. Refresh the list
2. Record may have been deleted
3. Check if you're viewing correct data

### "Validation Error" (422)

**Meaning**: Input data is invalid

**Solutions**:
1. Check all required fields are filled
2. Verify data format (dates, numbers)
3. Read error messages for specific issues
4. Fix errors and try again

### "Too Many Requests" (429)

**Meaning**: You've exceeded rate limit

**Solutions**:
1. Wait 60 seconds before trying again
2. Avoid rapid button clicking
3. Batch operations if possible
4. Contact admin if limit is too low

### "Server Error" (500)

**Meaning**: Server encountered an error

**Solutions**:
1. Wait a few minutes and try again
2. App will retry automatically
3. Contact support if persists
4. Check server status page

### "No Internet Connection"

**Meaning**: Device is offline

**Solutions**:
1. Check WiFi/mobile data
2. Toggle airplane mode
3. Restart device
4. Your changes are saved locally

---

## Admin-Specific Issues

### Cannot Access Admin Features

**Symptoms**:
- Admin menu not visible
- "Access denied" on admin pages
- Admin features grayed out

**Solutions**:

1. **Verify Admin Role**
   ```
   - Go to Profile
   - Check if role shows "Admin"
   - Contact admin if role is wrong
   ```

2. **Re-login**
   ```
   - Log out completely
   - Log back in
   - Admin features should appear
   ```

3. **Contact System Admin**
   ```
   - Request admin access
   - Provide your email
   - Wait for role assignment
   ```

### Audit Logs Not Loading

**Symptoms**:
- Audit logs page is empty
- "Failed to load" error
- Logs don't update

**Solutions**:

1. **Check Filters**
   ```
   - Remove all filters
   - Try loading again
   - Adjust date range
   ```

2. **Refresh Page**
   ```
   - Pull down to refresh
   - Or tap refresh button
   - Wait for data to load
   ```

3. **Check Permissions**
   ```
   - Verify you have admin access
   - Contact system admin
   ```

---

## Offline Mode Issues

### Offline Changes Not Syncing

**Symptoms**:
- Changes made offline don't sync
- "Sync failed" status
- Data missing after going online

**Solutions**:

1. **Check Sync Queue**
   ```
   - Profile → Sync Status
   - View pending operations
   - Tap "Retry All"
   ```

2. **Manual Sync**
   ```
   - Go online
   - Pull down to refresh
   - Or tap "Sync Now"
   ```

3. **Check for Errors**
   ```
   - View sync errors
   - Fix validation issues
   - Retry failed operations
   ```

### Offline Indicator Always Shows

**Symptoms**:
- App shows offline even when online
- Orange cloud icon persists
- Cannot sync

**Solutions**:

1. **Restart App**
   ```
   - Close app completely
   - Reopen
   - Check connectivity status
   ```

2. **Check Connectivity Service**
   ```
   - Profile → Settings
   - Connectivity Check → Run
   - Verify result
   ```

3. **Reinstall App**
   ```
   - Uninstall app
   - Reinstall from store
   - Log in again
   ```

---

## Data Issues

### Missing Data

**Symptoms**:
- Records disappeared
- Data not showing
- Empty lists

**Solutions**:

1. **Check Filters**
   ```
   - Remove all filters
   - Check date range
   - Verify sync status filter
   ```

2. **Refresh Data**
   ```
   - Pull down to refresh
   - Wait for data to load
   - Check internet connection
   ```

3. **Check Sync Status**
   ```
   - Profile → Sync Status
   - Verify data is synced
   - Retry if needed
   ```

4. **Restore from Backup**
   ```
   - If data is truly lost
   - Profile → Restore from Backup
   - Select backup file
   ```

### Incorrect Totals

**Symptoms**:
- Total amounts don't match
- Currency totals wrong
- Dashboard shows wrong numbers

**Solutions**:

1. **Refresh Data**
   ```
   - Pull down to refresh
   - Totals will recalculate
   - Verify amounts
   ```

2. **Check Filters**
   ```
   - Filters affect totals
   - Remove filters to see all
   - Adjust date range
   ```

3. **Report to Support**
   ```
   - If totals still wrong
   - Provide screenshots
   - Support will investigate
   ```

---

## Installation Issues

### Cannot Install App

**Symptoms**:
- Installation fails
- "App not compatible" error
- Download doesn't start

**Solutions**:

1. **Check Device Compatibility**
   ```
   - Android 5.0+ required
   - iOS 11.0+ required
   - Check device version
   ```

2. **Free Up Storage**
   ```
   - App requires 100MB minimum
   - Delete unused apps
   - Clear cache
   ```

3. **Update OS**
   ```
   - Update to latest OS version
   - Restart device
   - Try installing again
   ```

### App Crashes on Startup

**Symptoms**:
- App closes immediately
- Crash on splash screen
- Cannot open app

**Solutions**:

1. **Restart Device**
   ```
   - Turn device off
   - Wait 30 seconds
   - Turn back on
   - Try opening app
   ```

2. **Clear App Data**
   ```
   - Device Settings → Apps
   - Finance App → Storage
   - Clear Data (will need to login again)
   ```

3. **Reinstall App**
   ```
   - Uninstall app
   - Restart device
   - Reinstall from store
   ```

4. **Check for Updates**
   ```
   - Update to latest version
   - Bug fixes may resolve crash
   ```

---

## Getting Help

### Self-Service Resources

1. **In-App Help**
   - Profile → Help & Support
   - Context-specific help
   - FAQ section

2. **Documentation**
   - User Guide
   - Migration Guide
   - API Documentation

3. **Community**
   - User forums
   - Community discussions
   - Tips and tricks

### Contact Support

**Email Support**:
- Email: support@example.com
- Response time: 24 hours
- Include: Device model, app version, error messages

**Phone Support**:
- Phone: [Support Number]
- Hours: 9 AM - 5 PM (Mon-Fri)
- For urgent issues

**Live Chat**:
- Available in app
- Profile → Help & Support → Chat
- Instant responses during business hours

### Reporting Bugs

When reporting bugs, include:

1. **Device Information**
   - Device model
   - OS version
   - App version

2. **Steps to Reproduce**
   - What you were doing
   - What you expected
   - What actually happened

3. **Screenshots**
   - Error messages
   - Relevant screens
   - Console logs (if available)

4. **Frequency**
   - Does it happen every time?
   - Intermittent?
   - First occurrence?

---

## Prevention Tips

### Avoid Common Issues

1. **Keep App Updated**
   - Enable auto-updates
   - Check for updates weekly
   - Read update notes

2. **Maintain Good Connection**
   - Use stable WiFi
   - Avoid moving during sync
   - Check connection before important operations

3. **Regular Backups**
   - Backup data weekly
   - Store backups safely
   - Test restore occasionally

4. **Monitor Sync Status**
   - Check sync status regularly
   - Resolve issues promptly
   - Don't let queue grow large

5. **Use Strong Password**
   - At least 8 characters
   - Mix of letters, numbers, symbols
   - Change periodically

6. **Log Out on Shared Devices**
   - Always log out
   - Don't save password
   - Clear app data after use

---

## Advanced Troubleshooting

### Enable Debug Mode

For advanced users:

1. Go to Profile → Settings
2. Tap version number 7 times
3. Debug mode enabled
4. View detailed logs
5. Share logs with support

### Check API Connectivity

1. Profile → Settings → Advanced
2. Tap "Test API Connection"
3. View connection details
4. Check response times
5. Verify endpoints

### View Sync Logs

1. Profile → Settings → Advanced
2. Tap "View Sync Logs"
3. See all sync operations
4. Identify failures
5. Export logs for support

---

## Still Need Help?

If you've tried everything and still have issues:

1. **Document the Problem**
   - Take screenshots
   - Note error messages
   - Record steps to reproduce

2. **Contact Support**
   - Email: support@example.com
   - Include all documentation
   - Be specific about the issue

3. **Emergency Support**
   - For critical issues
   - Call support hotline
   - Available 24/7

We're here to help! Don't hesitate to reach out.
