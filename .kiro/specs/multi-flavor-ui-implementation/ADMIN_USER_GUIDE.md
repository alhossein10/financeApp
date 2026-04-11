# Admin User Guide

## Introduction

Welcome to the Finance App Admin application. This guide will help you understand and use all features available in the Admin flavor.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Registration and Login](#registration-and-login)
3. [Group Management](#group-management)
4. [Financial Box (Cash)](#financial-box-cash)
5. [Currency Exchange](#currency-exchange)
6. [Expenses](#expenses)
7. [Export](#export)
8. [Profile Management](#profile-management)
9. [Troubleshooting](#troubleshooting)

## Getting Started

### What is the Admin Role?

As an Admin, you manage a group of regular Users. You can:
- Manage User members in your group
- Receive USD transfers from your Superadmin
- Transfer USD to Users in your group
- Exchange USD to SYP or TRY
- Create and manage expenses
- View all expenses from your Users
- Export financial reports

### Navigation Overview

The Admin app has six main sections:
- **Group Management**: View and manage your User members
- **Cash**: Manage your financial box and transfers
- **Exchange**: Convert USD to SYP or TRY
- **Expenses**: Create and view expenses with invoices
- **Export**: Generate PDF and Excel reports
- **Profile**: Manage your account settings

## Registration and Login

### First-Time Registration

To register as an Admin, you need a 6-character group code from your Superadmin.

1. Open the Admin app
2. Tap "Register" on the welcome screen
3. Fill in your details:
   - Full Name
   - Email Address
   - Password (minimum 8 characters)
   - **Superadmin Join Code** (6 characters)
4. Tap "Register"

**Important**: After successful registration, you will receive your own 6-character group code. **Save this code securely** - Users will need it to join your group.

### Getting Your Superadmin Join Code

Contact your Superadmin to get the 6-character code needed for registration.

### Copying Your Group Code

After registration, a dialog will display your Admin group code. You can also find it later in the Group Management page.

### Logging In

1. Open the Admin app
2. Enter your email and password
3. Tap "Login"

## Group Management

### Viewing Your Users

The Group Management page is your home screen. Here you can:
- See the total number of Users in your group
- View each User's profile picture, name, and balances
- Access detailed information for each User

### Viewing User Details

1. Tap on any User card
2. A detail sheet will open showing:
   - User's name and email
   - Financial box balances (USD, SYP, TRY)
   - Recent activity summary

### Sharing Your Group Code

1. Navigate to Group Management
2. Your group code is displayed at the top
3. Tap the "Copy" button to copy it to clipboard
4. Share this code with new Users who need to join your group

### Regenerating Your Group Code

If your group code is compromised:
1. Navigate to Group Management
2. Tap the "Regenerate Code" button
3. Confirm the action
4. A new 6-character code will be generated
5. Share the new code with your Users

**Warning**: Old codes will no longer work after regeneration.

### Removing a User

1. Navigate to Group Management
2. Tap on the User you want to remove
3. In the detail sheet, tap "Remove from Group"
4. Confirm the action

**Note**: Removing a User does not delete their account, only removes them from your group.

## Financial Box (Cash)

### Viewing Your Balances

The Cash page displays your current balances in three currencies:
- USD (United States Dollar)
- SYP (Syrian Pound)
- TRY (Turkish Lira)

### Understanding Your Balance Sources

Your balances come from:
- **Incoming**: USD transfers from your Superadmin
- **Exchanges**: Converting USD to SYP or TRY
- **Outgoing**: USD transfers to your Users
- **Expenses**: Spending in any currency

### Viewing Incoming Transfers

The Cash page shows all incoming transfers from your Superadmin:
- Transfer amount (USD)
- Transfer date
- Status

### Creating a Transfer to a User

1. Navigate to Cash page
2. Tap "Transfer to User" button
3. Fill in the transfer details:
   - **Recipient**: Select a User from your group
   - **Amount**: Enter amount in USD
   - **Date**: Select transfer date
   - **Notes**: Add optional notes
4. Review the details
5. Tap "Create Transfer"

**Important**: The system will verify you have sufficient USD balance before creating the transfer.

### Viewing Outgoing Transfers

Scroll down on the Cash page to see all your outgoing transfers to Users.

### Filtering Transfers

1. Tap the filter icon
2. Select filters:
   - **Date Range**: Select start and end dates
   - **Recipient User**: Filter by specific User
3. Tap "Apply"

### Exporting Transfers

1. Apply any desired filters
2. Tap "Export to PDF"
3. The export will include all filtered transfers
4. Save or share the PDF file

## Currency Exchange

### Why Exchange Currency?

You receive USD from your Superadmin but may need SYP or TRY for local expenses. The Exchange feature lets you convert USD to these currencies.

### Creating an Exchange

1. Navigate to Exchange page
2. Fill in the exchange details:
   - **Target Currency**: Select SYP or TRY
   - **Amount in USD**: Enter how much USD to exchange
   - **Exchange Rate**: Enter the current rate
   - **OR Converted Amount**: Enter the final amount (system calculates rate)
   - **Date**: Select exchange date
   - **Notes**: Add optional notes
3. Review the calculation
4. Tap "Create Exchange"

**Important**: The system will verify you have sufficient USD balance before creating the exchange.

### Understanding Exchange Calculations

You can enter either:
- **Exchange Rate**: System calculates converted amount
- **Converted Amount**: System calculates exchange rate

Example:
- Exchange 100 USD to SYP
- Rate: 13,000 (1 USD = 13,000 SYP)
- Result: 1,300,000 SYP

### Viewing Exchange History

1. Tap "Exchange Log" button at the top of Exchange page
2. View all exchanges:
   - Your own exchanges
   - Exchanges from all Users in your group

### Exchange Log Features

The Exchange Log shows:
- **Total Exchanged**: Fixed label showing total amounts in SYP and TRY
- **Individual Exchanges**: List of all exchange transactions
- **User Filter**: Filter by specific User or view only your exchanges
- **Currency Filter**: Filter by SYP or TRY

### Filtering Exchange Log

1. In Exchange Log, tap the filter icon
2. Select filters:
   - **User**: Select yourself or any User in your group
   - **Currency**: Select SYP or TRY
3. Tap "Apply"

### Exporting Exchange Log

1. Apply desired filters
2. Tap "Export to PDF"
3. Save or share the PDF file

## Expenses

### Creating an Expense

1. Navigate to Expenses page
2. Tap the "+" or "New Expense" button
3. Fill in the expense details:
   - **Description**: What was purchased
   - **Currency**: Select USD, SYP, or TRY
   - **Amount**: Enter the expense amount
   - **Date**: Select expense date
   - **Invoice Photo**: Tap to add receipt photo (optional)
4. Review the details
5. Tap "Create Expense"

**Important**: The system will verify you have sufficient balance in the selected currency.

### Adding Invoice Photos

1. When creating an expense, tap "Add Invoice Photo"
2. Choose source:
   - **Camera**: Take a photo now
   - **Gallery**: Select existing photo
3. Photo will be compressed and uploaded
4. Thumbnail appears in the expense form

### Viewing Expenses

The Expenses page shows:
- Your own expenses
- All expenses from Users in your group

Each expense card displays:
- Description
- Amount and currency
- Date
- User who created it
- Invoice preview button (if photo exists)

### Previewing Invoice Photos

1. Find an expense with an invoice photo
2. Tap the "Preview" or camera icon
3. Full-screen image opens with zoom controls
4. Tap outside or "Close" to dismiss

### Filtering Expenses

1. Tap the filter icon
2. Select filters:
   - **Date Range**: Select start and end dates
   - **Currency**: Select USD, SYP, or TRY
   - **User**: Filter by specific User or view only yours
3. Tap "Apply"

**Note**: Filters persist when you navigate to Export page.

### Clearing Filters

1. Tap the filter icon
2. Tap "Clear All Filters"
3. All expenses will be displayed

## Export

### Available Export Formats

The Export page offers three export options:
1. **Export to PDF**: Formatted expense report
2. **Export to Excel**: Spreadsheet format
3. **Export Invoice Images to PDF Bundle**: All invoice photos in one PDF

### Exporting Expenses to PDF

1. Navigate to Export page
2. Ensure desired filters are applied (from Expenses page)
3. Tap "Export to PDF"
4. Wait for export to complete
5. Save or share the PDF file

The PDF includes:
- Expense list with all details
- Totals by currency
- Date range and filters applied

### Exporting to Excel

1. Navigate to Export page
2. Tap "Export to Excel"
3. Wait for export to complete
4. Save or share the Excel file

The Excel file includes:
- One row per expense
- Columns: Date, Description, Amount, Currency, User
- Totals at the bottom

### Exporting Invoice Images

1. Navigate to Export page
2. Tap "Export Invoice Images to PDF Bundle"
3. Wait for export to complete (may take longer for many images)
4. Save or share the PDF file

The PDF bundle includes:
- All invoice photos from filtered expenses
- One photo per page
- Expense details below each photo

### Understanding Filter Persistence

Filters you apply on the Expenses page automatically apply to exports:
- Date range filters
- Currency filters
- User filters

This ensures your exports match what you see on the Expenses page.

## Profile Management

### Viewing Your Profile

Navigate to Profile to see:
- Your name and email
- Profile picture
- Organization name (from Superadmin)
- Admin group name
- Group code
- Account creation date

### Uploading Profile Picture

1. Navigate to Profile
2. Tap on your profile picture or "Upload Photo"
3. Choose source:
   - **Camera**: Take a photo now
   - **Gallery**: Select existing photo
4. Photo will be compressed and uploaded
5. Your Superadmin will see this photo in their Group Management

### Updating Profile Information

1. Navigate to Profile
2. Tap "Edit Profile"
3. Update your information:
   - Full name
   - Admin group name
4. Tap "Save"

**Note**: Email and organization name cannot be changed.

### Changing Password

1. Navigate to Profile
2. Tap "Change Password"
3. Enter:
   - Current password
   - New password
   - Confirm new password
4. Tap "Save"

### Language Settings

1. Navigate to Profile
2. Tap "Language"
3. Select your preferred language:
   - English
   - Arabic (العربية)
4. The app will restart with the new language

### Logging Out

1. Navigate to Profile
2. Scroll to bottom
3. Tap "Logout"
4. Confirm the action

**Note**: All local data will be cleared on logout.

## Troubleshooting

### Common Issues

#### "Insufficient Balance" Error

**Problem**: Cannot create transfer, exchange, or expense due to insufficient balance.

**Solution**: 
1. Check your current balance in the required currency
2. For USD: Wait for Superadmin transfer or reduce amount
3. For SYP/TRY: Exchange more USD to the needed currency
4. Try the operation again

#### User Not Appearing in List

**Problem**: A User who joined is not visible in Group Management.

**Solution**:
1. Pull down to refresh the list
2. Check that the User used the correct group code
3. Verify the User completed registration successfully
4. Ensure the User is using the User flavor app

#### Cannot Upload Invoice Photo

**Problem**: Photo upload fails or doesn't appear.

**Solution**:
1. Check camera/storage permissions in device settings
2. Ensure photo is not too large (max 10MB)
3. Check internet connection
4. Try taking a new photo or selecting a different one
5. Restart the app and try again

#### Exchange Calculation Wrong

**Problem**: Exchange rate or converted amount doesn't match expectations.

**Solution**:
1. Verify you entered the correct exchange rate
2. Check if you entered rate or converted amount (not both)
3. System calculates: Converted Amount = USD Amount × Exchange Rate
4. Double-check your math
5. Clear the form and start over

#### Export Not Working

**Problem**: Export button doesn't work or file doesn't download.

**Solution**:
1. Check your internet connection
2. Ensure you have storage permissions enabled
3. Try exporting again
4. For invoice images, ensure expenses have photos attached
5. If problem persists, contact support

### Performance Issues

#### App Running Slowly

**Solutions**:
- Close and restart the app
- Clear app cache in device settings
- Ensure you have stable internet connection
- Update to the latest app version

#### Data Not Loading

**Solutions**:
1. Check internet connection
2. Pull down to refresh
3. Logout and login again
4. Contact support if issue persists

### Security Best Practices

1. **Keep Your Group Code Secure**: Only share with trusted Users
2. **Use Strong Password**: Minimum 8 characters with mix of letters, numbers, symbols
3. **Regular Password Changes**: Change password every 3-6 months
4. **Logout on Shared Devices**: Always logout when using shared devices
5. **Monitor User Activity**: Regularly review expenses and exchanges

### Getting Help

If you encounter issues not covered in this guide:

1. **Check Documentation**: Review this guide and other documentation
2. **Contact Support**: Email support@financeapp.com
3. **Report Issues**: Use the "Report Issue" option in Profile settings

## Best Practices

### Financial Management

1. **Regular Balance Checks**: Monitor your balances daily
2. **Timely Exchanges**: Exchange USD when you have good rates
3. **Invoice Photos**: Always attach invoice photos for accountability
4. **Accurate Descriptions**: Use clear expense descriptions
5. **Regular Exports**: Export reports monthly for records

### Group Management

1. **Verify Users**: Ensure Users joining are authorized
2. **Monitor Activity**: Review User expenses regularly
3. **Communicate**: Keep Users informed about policies
4. **Code Security**: Regenerate code if compromised

### Data Organization

1. **Use Filters**: Apply filters to find specific transactions
2. **Consistent Dates**: Use actual transaction dates
3. **Add Notes**: Include helpful notes in transfers and exchanges
4. **Regular Exports**: Keep backup copies of reports

## Appendix

### Currency Codes

- **USD**: United States Dollar
- **SYP**: Syrian Pound
- **TRY**: Turkish Lira

### Exchange Rate Examples

| From | To | Rate | Example |
|------|-----|------|---------|
| 1 USD | SYP | 13,000 | 100 USD = 1,300,000 SYP |
| 1 USD | TRY | 28 | 100 USD = 2,800 TRY |

### File Formats

- **PDF**: Best for viewing and printing reports
- **Excel**: Best for data analysis and manipulation
- **PDF Bundle**: Best for archiving invoice photos

### Data Sync

- Data syncs automatically when online
- Offline changes are queued and synced when connection restores
- Pull to refresh to manually sync latest data

### Privacy and Data

- Your data is encrypted in transit and at rest
- Only you and your Superadmin can see your financial box details
- Users cannot see your detailed transactions
- You can see all User expenses in your group

---

**Version**: 1.0  
**Last Updated**: November 2024  
**App Version**: 1.0.0
