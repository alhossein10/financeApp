# Troubleshooting Guide

## Overview

This guide provides solutions to common issues encountered when using or developing the multi-flavor Finance application.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Balance and Transaction Issues](#balance-and-transaction-issues)
3. [Group Management Issues](#group-management-issues)
4. [Exchange and Currency Issues](#exchange-and-currency-issues)
5. [Expense and Invoice Issues](#expense-and-invoice-issues)
6. [Export Issues](#export-issues)
7. [Performance Issues](#performance-issues)
8. [Build and Deployment Issues](#build-and-deployment-issues)
9. [Network and Connectivity Issues](#network-and-connectivity-issues)
10. [Data Sync Issues](#data-sync-issues)

## Authentication Issues

### Cannot Register

#### Symptom
Registration fails with error message.

#### Possible Causes and Solutions

**1. Invalid Group Code**
- **Error**: "Invalid group code"
- **Solution**: 
  - Verify you have the correct 6-character code
  - Check for typos (codes are case-sensitive)
  - Ensure code hasn't been regenerated
  - Contact your Admin/Superadmin for current code

**2. Email Already Exists**
- **Error**: "Email already registered"
- **Solution**:
  - Use a different email address
  - Try logging in instead of registering
  - Use "Forgot Password" if you forgot your credentials

**3. Weak Password**
- **Error**: "Password must be at least 8 characters"
- **Solution**:
  - Use minimum 8 characters
  - Include mix of letters, numbers, and symbols
  - Avoid common passwords

**4. Network Error**
- **Error**: "Connection failed"
- **Solution**:
  - Check internet connection
  - Try again in a few moments
  - Verify API server is accessible

### Cannot Login

#### Symptom
Login fails with error message.

#### Possible Causes and Solutions

**1. Invalid Credentials**
- **Error**: "Invalid email or password"
- **Solution**:
  - Double-check email and password
  - Ensure caps lock is off
  - Use "Forgot Password" to reset

**2. Account Not Found**
- **Error**: "Account not found"
- **Solution**:
  - Verify you registered with this email
  - Check if you're using the correct flavor app
  - Register if you haven't already

**3. Token Expired**
- **Error**: "Session expired"
- **Solution**:
  - Login again
  - App will automatically refresh token

### Auto-Logout Issues

#### Symptom
App logs out unexpectedly.

#### Possible Causes and Solutions

**1. Inactivity Timeout**
- **Cause**: 30 minutes of inactivity
- **Solution**:
  - This is expected security behavior
  - Login again to continue
  - Stay active to prevent timeout

**2. Token Invalidation**
- **Cause**: Token expired or invalidated
- **Solution**:
  - Login again
  - Check if password was changed elsewhere

## Balance and Transaction Issues

### Insufficient Balance Error

#### Symptom
Cannot create transfer, exchange, or expense due to insufficient balance.

#### Solutions

**For USD Shortage**:
1. Check current USD balance in Financial Box/Cash page
2. Wait for incoming transfer from Admin/Superadmin
3. Reduce transaction amount
4. Contact Admin/Superadmin for transfer

**For SYP/TRY Shortage**:
1. Check current balance in target currency
2. Exchange more USD to needed currency
3. Reduce expense amount
4. Verify you selected correct currency

### Balance Not Updating

#### Symptom
Balance doesn't reflect recent transactions.

#### Solutions

1. **Pull to Refresh**: Swipe down on balance card
2. **Check Network**: Ensure internet connection
3. **Wait for Sync**: Transactions may take a few seconds
4. **Logout/Login**: Clear cache and refresh data
5. **Verify Transaction**: Check if transaction actually completed

### Incorrect Balance Calculation

#### Symptom
Balance doesn't match expected amount.

#### Solutions

1. **Review Transactions**: Check all recent transactions
2. **Check Currency**: Verify you're looking at correct currency
3. **Refresh Data**: Pull to refresh
4. **Export Report**: Generate report to audit transactions
5. **Contact Support**: If discrepancy persists

## Group Management Issues

### Group Code Not Working

#### Symptom
Cannot join group with provided code.

#### Solutions

**For Admins**:
1. Verify code is exactly 6 characters
2. Check if Superadmin regenerated code
3. Ask Superadmin for current code
4. Ensure you're using Admin flavor app

**For Users**:
1. Verify code is exactly 6 characters
2. Check if Admin regenerated code
3. Ask Admin for current code
4. Ensure you're using User flavor app

### Member Not Appearing in List

#### Symptom
New member who joined is not visible.

#### Solutions

1. **Refresh List**: Pull down to refresh
2. **Verify Registration**: Confirm member completed registration
3. **Check Code**: Ensure member used correct group code
4. **Check Flavor**: Verify member used correct app flavor
5. **Wait**: May take a few seconds to sync

### Cannot Remove Member

#### Symptom
Remove member action fails.

#### Solutions

1. **Check Permissions**: Verify you have permission to remove
2. **Network Connection**: Ensure internet connection
3. **Try Again**: Temporary server issue
4. **Logout/Login**: Refresh session
5. **Contact Support**: If issue persists

## Exchange and Currency Issues

### Exchange Calculation Wrong

#### Symptom
Exchange rate or converted amount doesn't match expectations.

#### Solutions

1. **Verify Input**: Check you entered correct values
2. **Understand Calculation**: 
   - Converted Amount = USD Amount × Exchange Rate
   - Exchange Rate = Converted Amount ÷ USD Amount
3. **Enter One Value**: Enter either rate OR converted amount, not both
4. **Clear Form**: Start over if confused
5. **Use Calculator**: Verify math externally

### Exchange Not Creating

#### Symptom
Exchange creation fails.

#### Solutions

1. **Check USD Balance**: Verify sufficient USD
2. **Verify Amount**: Ensure amount is greater than 0
3. **Check Rate**: Ensure exchange rate is valid
4. **Network Connection**: Check internet
5. **Try Again**: May be temporary issue

### Exchange Log Empty

#### Symptom
No exchanges showing in Exchange Log.

#### Solutions

1. **Create Exchange**: Log is empty if no exchanges exist
2. **Check Filters**: Clear any active filters
3. **Refresh**: Pull to refresh
4. **Verify Role**: Users only see their own exchanges
5. **Check Date Range**: Expand date filter if applied

## Expense and Invoice Issues

### Cannot Upload Invoice Photo

#### Symptom
Photo upload fails or doesn't appear.

#### Solutions

**1. Permission Issues**
- **Solution**:
  - Go to device Settings → Apps → Finance App
  - Enable Camera and Storage permissions
  - Restart app and try again

**2. File Too Large**
- **Error**: "File too large"
- **Solution**:
  - Photo is automatically compressed
  - If still fails, try different photo
  - Maximum size: 10MB

**3. Network Error**
- **Error**: "Upload failed"
- **Solution**:
  - Check internet connection
  - Try again with better connection
  - Photo will be queued if offline

**4. Invalid Format**
- **Error**: "Invalid file format"
- **Solution**:
  - Use JPG or PNG format
  - Take new photo with camera
  - Convert photo if needed

### Invoice Preview Not Working

#### Symptom
Cannot view invoice photo.

#### Solutions

1. **Check Upload**: Verify photo was uploaded successfully
2. **Network Connection**: Need internet to load photo
3. **Wait for Load**: Large photos take time to load
4. **Clear Cache**: Clear app cache and try again
5. **Re-upload**: Upload photo again if corrupted

### Expense Not Showing

#### Symptom
Created expense doesn't appear in list.

#### Solutions

1. **Refresh List**: Pull down to refresh
2. **Check Filters**: Clear date/currency filters
3. **Verify Creation**: Check if expense actually saved
4. **Check Role**: 
   - Users only see their own expenses
   - Admins see all group expenses
5. **Network Sync**: Wait for sync to complete

### Cannot Create Expense

#### Symptom
Expense creation fails.

#### Solutions

1. **Check Balance**: Verify sufficient balance in selected currency
2. **Fill Required Fields**: Description, amount, currency, date
3. **Valid Amount**: Amount must be greater than 0
4. **Network Connection**: Check internet
5. **Try Without Photo**: Create expense without invoice first

## Export Issues

### Export Not Starting

#### Symptom
Export button doesn't work.

#### Solutions

1. **Check Network**: Exports require internet connection
2. **Check Permissions**: Enable storage permissions
3. **Wait**: May take a moment to start
4. **Try Again**: Temporary server issue
5. **Reduce Data**: Apply filters to reduce export size

### Export Takes Too Long

#### Symptom
Export processing for extended time.

#### Solutions

1. **Be Patient**: Large exports take time
2. **Check Progress**: Look for progress indicator
3. **Reduce Size**: Apply filters to limit data
4. **Invoice Images**: Image exports take longest
5. **Check Network**: Slow connection affects speed

### Export File Not Downloading

#### Symptom
Export completes but file doesn't download.

#### Solutions

1. **Check Storage**: Ensure sufficient device storage
2. **Check Permissions**: Enable storage permissions
3. **Check Downloads**: Look in Downloads folder
4. **Try Again**: Re-export if needed
5. **Different Format**: Try PDF instead of Excel or vice versa

### Empty Export

#### Symptom
Export file is empty or has no data.

#### Solutions

1. **Check Filters**: Filters may exclude all data
2. **Verify Data Exists**: Ensure expenses exist in date range
3. **Clear Filters**: Remove all filters and try again
4. **Check Role**: Verify you have access to data
5. **Create Data**: Add expenses before exporting

## Performance Issues

### App Running Slowly

#### Symptom
App is laggy or unresponsive.

#### Solutions

1. **Restart App**: Close and reopen app
2. **Clear Cache**: 
   - Go to device Settings → Apps → Finance App
   - Clear Cache (not Clear Data)
3. **Update App**: Install latest version
4. **Free Memory**: Close other apps
5. **Restart Device**: Reboot phone/tablet

### Data Not Loading

#### Symptom
Lists or pages show loading indefinitely.

#### Solutions

1. **Check Network**: Verify internet connection
2. **Pull to Refresh**: Swipe down to refresh
3. **Logout/Login**: Refresh session
4. **Clear Cache**: Clear app cache
5. **Reinstall**: Uninstall and reinstall app

### Images Loading Slowly

#### Symptom
Profile pictures or invoice photos load slowly.

#### Solutions

1. **Check Network**: Slow connection affects image loading
2. **Wait**: Large images take time
3. **Clear Cache**: Clear image cache
4. **Reduce Quality**: Images are automatically compressed
5. **Better Connection**: Use WiFi instead of mobile data

## Build and Deployment Issues

### Build Fails

#### Symptom
Flutter build command fails.

#### Solutions

**1. Clean Build**
```bash
flutter clean
flutter pub get
flutter build apk --flavor [flavor] --target lib/main_[flavor].dart
```

**2. Check Dependencies**
```bash
flutter pub get
flutter pub upgrade
```

**3. Check Flavor Configuration**
- Verify `build.gradle` has correct flavor setup
- Check `.xcconfig` files for iOS
- Ensure main entry points exist

**4. Check Flutter Version**
```bash
flutter --version
flutter upgrade
```

### Wrong Flavor Running

#### Symptom
App shows features from different flavor.

#### Solutions

1. **Verify Command**: Check `--flavor` and `--target` flags
2. **Clean Build**: Run `flutter clean`
3. **Rebuild**: Build again with correct flavor
4. **Check Config**: Verify `FlavorConfig` initialization

### App Icon Not Showing

#### Symptom
Default icon shows instead of flavor-specific icon.

#### Solutions

1. **Check Icon Files**: Verify icons exist in flavor directories
2. **Clean Build**: Run `flutter clean` and rebuild
3. **Check Configuration**:
   - Android: `manifestPlaceholders` in `build.gradle`
   - iOS: `ASSETCATALOG_COMPILER_APPICON_NAME` in `.xcconfig`
4. **Regenerate Icons**: Use `flutter_launcher_icons` package

## Network and Connectivity Issues

### Connection Timeout

#### Symptom
Requests timeout with error.

#### Solutions

1. **Check Internet**: Verify device has internet
2. **Check API Server**: Verify server is accessible
3. **Increase Timeout**: May need to adjust timeout settings
4. **Try Again**: Temporary network issue
5. **Use WiFi**: Switch from mobile data to WiFi

### Offline Mode Not Working

#### Symptom
App doesn't work offline as expected.

#### Solutions

1. **Understand Limitations**: Some features require internet
2. **Check Cache**: Ensure data was cached while online
3. **Sync When Online**: Connect to internet to sync
4. **Check Indicator**: Look for offline indicator banner
5. **Balance Operations**: Cannot verify balance offline

### SSL/Certificate Errors

#### Symptom
SSL certificate validation fails.

#### Solutions

1. **Check Date/Time**: Ensure device date/time is correct
2. **Update App**: Install latest version
3. **Check Network**: Some networks block HTTPS
4. **Contact Support**: May be server certificate issue

## Data Sync Issues

### Changes Not Syncing

#### Symptom
Local changes don't appear on server.

#### Solutions

1. **Check Network**: Ensure internet connection
2. **Check Queue**: Offline changes are queued
3. **Wait**: Sync happens automatically when online
4. **Force Sync**: Pull to refresh
5. **Check Errors**: Look for sync error messages

### Sync Conflicts

#### Symptom
Conflict resolution dialog appears.

#### Solutions

1. **Choose Version**: Select server or local version
2. **Merge Manually**: If possible, merge changes
3. **Keep Server**: Usually safest option
4. **Keep Local**: If you know local is correct
5. **Contact Support**: For complex conflicts

### Data Loss After Logout

#### Symptom
Data disappears after logout.

#### Solutions

1. **Expected Behavior**: Logout clears local data for security
2. **Export First**: Export data before logout
3. **Login Again**: Data will sync from server
4. **Backup**: Regularly export data for backup

## Getting Help

### Before Contacting Support

1. **Check This Guide**: Review relevant section
2. **Try Basic Solutions**:
   - Restart app
   - Check internet connection
   - Logout and login
   - Clear cache
3. **Gather Information**:
   - App version
   - Device model and OS version
   - Flavor (Superadmin/Admin/User)
   - Error messages
   - Steps to reproduce

### Contact Support

**Email**: support@financeapp.com

**Include**:
- Detailed description of issue
- Steps to reproduce
- Screenshots if applicable
- Device and app information
- Error messages

### Report a Bug

Use "Report Issue" in app:
1. Navigate to Profile
2. Tap "Report Issue"
3. Describe the problem
4. Include steps to reproduce
5. Submit

### Emergency Issues

For critical issues affecting operations:
- Email: emergency@financeapp.com
- Include "URGENT" in subject line
- Describe business impact

## Preventive Measures

### Best Practices

1. **Regular Updates**: Keep app updated
2. **Regular Exports**: Export data monthly
3. **Strong Passwords**: Use secure passwords
4. **Stable Network**: Use reliable internet connection
5. **Regular Backups**: Export and save reports
6. **Monitor Balances**: Check balances regularly
7. **Clear Descriptions**: Use clear transaction descriptions
8. **Attach Invoices**: Always attach invoice photos

### Security Practices

1. **Logout on Shared Devices**: Always logout
2. **Change Passwords**: Change every 3-6 months
3. **Protect Group Codes**: Don't share publicly
4. **Monitor Activity**: Review transactions regularly
5. **Report Suspicious**: Report unusual activity immediately

---

**Version**: 1.0  
**Last Updated**: November 2024

**Need More Help?**  
Email: support@financeapp.com  
Documentation: https://docs.financeapp.com
