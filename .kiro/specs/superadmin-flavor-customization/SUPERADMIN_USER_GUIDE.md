# SuperAdmin User Guide

## Overview

This guide provides comprehensive instructions for using the SuperAdmin flavor of the Finance application. SuperAdmins have unique capabilities to manage multiple admin groups and monitor organizational financial activities.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Registration](#registration)
3. [Navigation](#navigation)
4. [Group Management](#group-management)
5. [Cash Management](#cash-management)
6. [Expense Monitoring](#expense-monitoring)
7. [Profile Management](#profile-management)
8. [Troubleshooting](#troubleshooting)

## Getting Started

### What is a SuperAdmin?

A SuperAdmin is the highest privilege level user who:
- Manages multiple admin groups
- Oversees organizational financial activities
- Creates outgoing transfers to admin users
- Monitors aggregated expense data across all admin groups
- Does not create individual expenses or exchanges

### Key Differences from Admin/User Flavors

SuperAdmin flavor has a simplified interface focused on oversight:
- **Removed Features**: Currency Exchange, Export, Incoming Transfers, Exchange History
- **Modified Features**: Cash page (outgoing only), Expenses page (read-only aggregated view)
- **Unique Features**: Group code generation, multi-group oversight

## Registration

### Creating a SuperAdmin Account

1. Open the Finance SuperAdmin app
2. Tap "Register" on the welcome screen
3. Fill in the registration form:
   - Full Name
   - Email Address
   - Password (minimum 8 characters)
   - Confirm Password
   - Admin Group Name (your organization name)
4. Tap "Register"

### Group Code Generation

After successful registration, you will immediately see a dialog displaying your unique **Group Code**.

**Important**: This group code is essential for admins to join your group.

#### What to Do with Your Group Code

1. **Copy the Code**: Tap the "Copy" button to copy the code to your clipboard
2. **Share with Admins**: Send the group code to admin users who need to join your group
3. **Keep it Secure**: Treat the group code like a password - only share with trusted admins

#### Accessing Your Group Code Later

If you need to view your group code again:
1. Navigate to "Group Management" from the bottom navigation
2. Your group code is displayed at the top of the page
3. Tap the copy icon to copy it again

## Navigation

### Bottom Navigation Bar

The SuperAdmin interface has four main sections:

1. **Group Management** (👥 icon)
   - View your admin group information
   - See group code
   - Manage group members
   - Remove members if needed

2. **Cash (النقد)** (💰 icon)
   - View fund box balance
   - Create outgoing transfers to admins
   - View transfer history

3. **Expenses** (📊 icon)
   - Monitor expense summaries by admin group
   - View detailed expenses per group
   - Filter by admin group

4. **Profile** (👤 icon)
   - View and edit your profile
   - Change password
   - View statistics
   - Logout

## Group Management

### Viewing Group Information

1. Tap "Group Management" in the bottom navigation
2. You will see:
   - Your admin group name
   - Your unique group code
   - List of admin members in your group

### Managing Group Members

#### Viewing Members

The group management page displays all admins who have joined your group using the group code.

For each member, you can see:
- Name
- Email
- Join date

#### Removing Members

If you need to remove an admin from your group:

1. Find the member in the list
2. Tap the "Remove" button next to their name
3. Confirm the removal in the dialog
4. The member will be removed from your group

**Note**: Removed members will lose access to group resources and data.

### Regenerating Group Code

If your group code has been compromised:

1. Go to Group Management
2. Tap "Regenerate Code"
3. Confirm the action
4. A new group code will be generated
5. Share the new code with your admins

**Warning**: The old code will no longer work for new members to join.

## Cash Management

### Understanding the Cash Page

The SuperAdmin cash page is a unified interface for managing outgoing transfers to admin users.

### Viewing Fund Box Balance

Your fund box balance is displayed prominently at the top of the cash page in USD.

This represents the total funds available for distribution to admin users.

### Creating Outgoing Transfers

To send funds to an admin user:

1. Tap the "+ Create Outgoing Transfer" button
2. Fill in the transfer form:
   - **Recipient**: Select an admin from your group
   - **Amount**: Enter the transfer amount in USD
   - **Description**: Add a note about the transfer (optional)
3. Review the details
4. Tap "Create Transfer"
5. Confirm the transfer

### Viewing Transfer History

The cash page displays a list of all outgoing transfers you've created:

- Transfer date and time
- Recipient name
- Amount
- Status (pending, completed, failed)
- Description

#### Filtering Transfers

Use the filter options to:
- View transfers by date range
- Filter by recipient
- Filter by status

### What You Won't See

As a SuperAdmin, the cash page does NOT include:
- Incoming transfers (you only send, not receive)
- Exchange history (currency exchange is not available)
- Cash inbox (no incoming transactions)

## Expense Monitoring

### Understanding the Expenses Page

The SuperAdmin expenses page provides a read-only, aggregated view of expenses across all admin groups under your supervision.

**Key Point**: SuperAdmins cannot create, edit, or delete expenses. This page is for monitoring only.

### Viewing Expense Summaries

The main expenses page shows a summary card for each admin group:

#### Summary Card Information

Each card displays:
- **Admin Group Name**
- **Total Amount**: Sum of all expenses for that group
- **Expense Count**: Number of expenses
- **Pending**: Number of pending expenses
- **Approved**: Number of approved expenses
- **Rejected**: Number of rejected expenses

### Filtering by Admin Group

Use the dropdown filter at the top to:
- View all groups
- Filter to a specific admin group

### Viewing Detailed Expenses

To see detailed expenses for a specific admin group:

1. Find the admin group summary card
2. Tap "View Details" button
3. You will see a list of individual expenses including:
   - Expense description
   - Amount
   - Date
   - Status
   - Category
   - Admin who created it

### Expense Status Indicators

Expenses are color-coded by status:
- **Pending** (Yellow): Awaiting approval
- **Approved** (Green): Approved and processed
- **Rejected** (Red): Rejected and not processed

### What You Cannot Do

As a SuperAdmin, you cannot:
- Create new expenses
- Edit existing expenses
- Delete expenses
- Approve or reject expenses

These actions are performed by admin users within their groups.

## Profile Management

### Viewing Your Profile

1. Tap "Profile" in the bottom navigation
2. View your profile information:
   - Name
   - Email
   - Role (SuperAdmin)
   - Registration date

### Editing Profile Information

To update your profile:

1. Tap the "Edit" button
2. Modify your information:
   - Full Name
   - Email (if allowed)
3. Tap "Save Changes"

### Changing Password

To change your password:

1. Go to Profile
2. Tap "Change Password"
3. Enter your current password
4. Enter your new password
5. Confirm your new password
6. Tap "Update Password"

### Viewing Statistics

Your profile page displays statistics about your account:
- Total outgoing transfers
- Total transfer amount
- Number of admin groups managed
- Number of admins in your group

### Logging Out

To log out of your account:

1. Go to Profile
2. Scroll to the bottom
3. Tap "Logout"
4. Confirm logout

## Troubleshooting

### I Lost My Group Code

**Solution**: 
1. Navigate to Group Management
2. Your group code is displayed at the top
3. Tap the copy icon to copy it

### An Admin Cannot Join My Group

**Possible Causes**:
- Incorrect group code entered
- Group code was regenerated (old code no longer works)
- Network connectivity issues

**Solutions**:
1. Verify you're sharing the correct group code
2. Check if you recently regenerated the code
3. Ask the admin to check their internet connection
4. Try regenerating the group code and sharing the new one

### My Fund Box Balance is Incorrect

**Solutions**:
1. Pull down to refresh the cash page
2. Check if recent transfers are still pending
3. Verify all transfers have been processed
4. Contact support if the issue persists

### I Cannot See Expenses for an Admin Group

**Possible Causes**:
- The admin group has no expenses yet
- Network connectivity issues
- The admin group is not under your supervision

**Solutions**:
1. Pull down to refresh the expenses page
2. Check your internet connection
3. Verify the admin group is part of your organization
4. Contact support if the issue persists

### The App is Not Loading Data

**Solutions**:
1. Check your internet connection
2. Pull down to refresh the page
3. Close and reopen the app
4. Clear app cache (Settings > Apps > Finance SuperAdmin > Clear Cache)
5. Reinstall the app if the issue persists

### I Need to Remove Multiple Members

**Solution**:
Remove members one at a time from the Group Management page. There is currently no bulk removal feature.

### Transfer Creation Failed

**Possible Causes**:
- Insufficient fund box balance
- Network connectivity issues
- Invalid recipient selection

**Solutions**:
1. Verify your fund box has sufficient balance
2. Check your internet connection
3. Ensure you selected a valid admin recipient
4. Try again after a few moments
5. Contact support if the issue persists

## Best Practices

### Group Code Security

- Only share your group code with trusted admin users
- Regenerate the code if you suspect it has been compromised
- Keep a secure record of your group code

### Transfer Management

- Add descriptive notes to transfers for better tracking
- Review transfer history regularly
- Verify recipient before creating large transfers

### Expense Monitoring

- Check expense summaries regularly to monitor organizational spending
- Use filters to focus on specific admin groups
- Review pending expenses to ensure timely processing

### Account Security

- Use a strong, unique password
- Change your password regularly
- Log out when using shared devices
- Enable two-factor authentication if available

## Support

If you encounter issues not covered in this guide:

1. Check the FAQ section in the app
2. Contact your system administrator
3. Reach out to technical support with:
   - Description of the issue
   - Steps to reproduce
   - Screenshots if applicable
   - Your account email (never share your password)

## Glossary

- **SuperAdmin**: Highest privilege user managing multiple admin groups
- **Admin Group**: Collection of admin users under SuperAdmin supervision
- **Group Code**: Unique code for admins to join a SuperAdmin's group
- **Fund Box**: SuperAdmin's available balance for transfers
- **Outgoing Transfer**: Funds sent from SuperAdmin to admin users
- **Expense Summary**: Aggregated view of expenses by admin group
