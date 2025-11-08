# Frequently Asked Questions (FAQ)

## General Questions

### What is Finance App?

Finance App is a comprehensive financial management application that helps you track expenses, transfers, and incoming funds. It features multi-currency support, invoice management, offline capabilities, and role-based access control.

### What's new in version 2.0?

Version 2.0 introduces Laravel backend integration, replacing the old SQLite/Supabase/PocketBase architecture. Key improvements include:
- Centralized data management
- Better synchronization
- Enhanced security
- Improved offline support
- Admin dashboard and analytics
- Audit logging
- Better performance

### Is my data secure?

Yes! We implement multiple security measures:
- HTTPS encryption for all data transmission
- Secure password hashing (never stored in plain text)
- Token-based authentication
- Secure local storage for tokens
- Regular security audits
- Role-based access control

### Can I use the app offline?

Absolutely! The app works fully offline:
- View all previously loaded data
- Create, edit, and delete records
- Changes are queued locally
- Automatic sync when you're back online
- No data loss

---

## Account & Authentication

### How do I create an account?

1. Open the app
2. Tap "Create Account"
3. Enter your name, email, and password
4. Tap "Register"
5. You're automatically logged in

### I forgot my password. What do I do?

1. On the login screen, tap "Forgot Password?"
2. Enter your email address
3. Tap "Send Reset Link"
4. Check your email for reset instructions
5. Click the link and set a new password

### How do I change my password?

1. Go to Profile
2. Tap "Change Password"
3. Enter your current password
4. Enter your new password
5. Confirm your new password
6. Tap "Update Password"

### Why do I keep getting logged out?

This can happen if:
- Your session expired (default: 30 days)
- You logged in on another device
- Your device time is incorrect
- App cache was cleared

Solution: Enable "Keep me logged in" or contact admin to extend session duration.

### Can I use the same account on multiple devices?

Yes! Log in with the same credentials on any device. Your data syncs automatically across all devices.

### How do I delete my account?

1. Go to Profile → Settings
2. Scroll to bottom
3. Tap "Delete Account"
4. Confirm deletion
5. Your account and all data will be permanently deleted within 30 days

**Warning**: This action cannot be undone!

---

## Data Management

### How do I add an expense?

1. Tap the "+" button
2. Select "Add Expense"
3. Fill in description, amount, and date
4. Optionally add an invoice
5. Tap "Save"

### Can I add expenses in multiple currencies?

Yes! Each expense supports three currencies:
- USD (US Dollar)
- SYP (Syrian Pound)
- TRY (Turkish Lira)

You can enter amounts in one, two, or all three currencies.

### How do I attach an invoice?

1. When creating/editing an expense
2. Tap "Add Invoice"
3. Choose "Take Photo" or "Choose from Gallery"
4. The invoice is automatically uploaded

### What file formats are supported for invoices?

Supported formats:
- JPG/JPEG images
- PNG images
- PDF documents

Maximum file size: 10MB

### How do I view my invoices?

1. Open an expense
2. Tap on the invoice thumbnail
3. View full-size image
4. Pinch to zoom
5. Swipe to close

### Can I edit an expense after creating it?

Yes! You can edit any expense at any time:
1. Open the expense
2. Tap the Edit icon
3. Make your changes
4. Tap "Save Changes"

### How do I delete an expense?

1. Open the expense
2. Tap the Delete icon
3. Confirm deletion
4. The expense is permanently deleted

### What happens to deleted data?

Deleted data is:
- Removed from your account immediately
- Kept in backups for 30 days
- Permanently deleted after 30 days
- Cannot be recovered after permanent deletion

---

## Transfers & Incoming

### What is a transfer?

A transfer is money you send to someone else. It tracks:
- Recipient name
- Amount sent
- Date of transfer
- Optional notes
- Exchange information (if applicable)

### What is exchange information?

Exchange information tracks currency conversion:
- Original amount (USD)
- Converted amount (SYP)
- Exchange rate used
- Date of exchange

This helps you track how much local currency you received for your USD.

### What is incoming funds?

Incoming funds are money you receive, such as:
- Salary
- Payments received
- Refunds
- Gifts
- Any money coming in

### How do I add a transfer?

1. Tap the "+" button
2. Select "Add Transfer"
3. Enter recipient name and amount
4. Optionally add exchange information
5. Tap "Save"

### How do I add incoming funds?

1. Tap the "+" button
2. Select "Add Incoming"
3. Enter description and amount
4. Select date
5. Tap "Save"

---

## Synchronization

### How does sync work?

The app syncs data automatically:
- When you open the app
- When you create/edit/delete records
- When you pull down to refresh
- When you go from offline to online

### What is sync status?

Sync status shows the state of your data:
- **Synced** (green): Data is on server
- **Pending** (orange): Waiting to sync
- **Syncing** (blue): Currently syncing
- **Failed** (red): Sync failed, will retry

### How do I manually sync?

1. Pull down on any list to refresh
2. Or go to Profile → Sync Now
3. Wait for sync to complete

### What if sync fails?

The app automatically retries failed syncs:
- Immediate retry
- Retry after 2 seconds
- Retry after 4 seconds
- Continues with exponential backoff

You can also manually retry from Profile → Sync Status.

### Can I see what's pending sync?

Yes! Go to Profile → Sync Status to see:
- Number of pending operations
- List of pending changes
- Sync errors
- Retry options

### Does sync use a lot of data?

No, sync is efficient:
- Only changed data is synced
- Images are compressed
- Batch operations reduce requests
- Typical sync uses < 1MB

---

## Offline Mode

### How do I know if I'm offline?

The app shows an offline indicator:
- Orange cloud icon in header
- "Offline" badge on records
- "No internet connection" message

### What can I do offline?

Everything! You can:
- View all previously loaded data
- Create new expenses, transfers, incoming
- Edit existing records
- Delete records
- Attach invoices (synced later)

### What happens to changes made offline?

Changes are:
- Saved locally immediately
- Queued for sync
- Automatically synced when online
- Marked with "Pending sync" status

### How long can I work offline?

As long as you need! There's no time limit. Your changes are safely stored locally and will sync whenever you're back online.

### What if I make changes on multiple devices while offline?

The app handles this with conflict resolution:
- Server version usually wins
- You can choose which version to keep
- No data is lost

---

## Performance

### Why is the app slow?

Common causes:
- Poor internet connection
- Large amount of data
- Low device storage
- Outdated app version

Solutions:
- Use WiFi instead of mobile data
- Clear app cache
- Free up device storage
- Update to latest version

### How do I clear cache?

1. Go to Profile → Settings
2. Tap "Clear Cache"
3. Confirm
4. Cache is cleared
5. Fresh data will be downloaded

### Does clearing cache delete my data?

No! Clearing cache only removes:
- Temporary files
- Downloaded images
- Cached API responses

Your actual data (expenses, transfers, incoming) is safe on the server.

### How can I reduce data usage?

1. Use WiFi for syncing
2. Reduce image quality (Settings)
3. Disable auto-sync
4. Sync manually when needed
5. Limit date ranges when viewing data

---

## Admin Features

### What are admin features?

Admin features include:
- Dashboard with system statistics
- View all users' data
- User activity monitoring
- Fund box management
- Audit logs
- System-wide data export

### How do I become an admin?

Admin access is granted by the system administrator. Contact them to request admin privileges.

### Can I see other users' data?

Only if you're an admin. Regular users can only see their own data.

### What is the fund box?

The fund box tracks the central fund balance. Only admins can:
- View fund box balance
- Update fund box balance
- See fund box history

### What are audit logs?

Audit logs track all system activities:
- Who did what
- When it happened
- What changed
- IP address
- Device information

Only admins can view audit logs.

### How do I export data?

Admins can export data:
1. Go to Admin → Export
2. Choose format (PDF or Excel)
3. Select date range
4. Tap "Export"
5. Download when ready

---

## Troubleshooting

### The app crashes. What should I do?

1. Restart the app
2. Restart your device
3. Clear app cache
4. Update to latest version
5. Reinstall if necessary
6. Contact support if persists

### I can't upload invoices. Why?

Check:
- File size (max 10MB)
- File format (JPG, PNG, PDF only)
- Internet connection
- Available storage space

### My data is missing. Where did it go?

Check:
- Date filters (may be hiding data)
- Sync status (may not be synced yet)
- Internet connection
- Pull down to refresh

If still missing, contact support immediately.

### I see duplicate records. How do I fix this?

1. Identify duplicates
2. Delete extra copies
3. Keep the most recent version
4. Contact support if it keeps happening

### The app says "Unauthorized". What does this mean?

Your session expired. Solution:
1. Log out
2. Log back in
3. Your data is safe

---

## Privacy & Security

### What data do you collect?

We collect:
- Account information (name, email)
- Financial data (expenses, transfers, incoming)
- Usage statistics (anonymous)
- Device information (for support)

We DO NOT collect:
- Passwords (stored hashed)
- Payment information
- Personal documents
- Location data (unless you enable it)

### Who can see my data?

- **You**: Full access to your data
- **Admins**: Can see all users' data
- **Support**: Only with your permission
- **No one else**: Your data is private

### Can I export my data?

Yes! Go to Profile → Settings → Export My Data. You'll receive an email with your complete data export.

### How long is my data kept?

- **Active accounts**: Data kept indefinitely
- **Deleted accounts**: Data deleted within 30 days
- **Backups**: Kept for 90 days

### Is my data encrypted?

Yes:
- In transit: HTTPS encryption
- At rest: Database encryption
- Tokens: Secure storage
- Passwords: Bcrypt hashing

---

## Billing & Subscription

### Is the app free?

[Adjust based on your pricing model]

### Are there any limits?

[Adjust based on your plan limits]

### How do I upgrade my plan?

[Adjust based on your upgrade process]

---

## Technical Questions

### What devices are supported?

- **Android**: 5.0 (Lollipop) and above
- **iOS**: 11.0 and above
- **Tablets**: Yes, optimized for tablets
- **Desktop**: Web version coming soon

### What internet speed do I need?

Minimum: 1 Mbps
Recommended: 5 Mbps or higher

### Does the app work on tablets?

Yes! The app is optimized for both phones and tablets.

### Can I use the app on multiple devices?

Yes! Log in with the same account on any device. Data syncs automatically.

### What happens if I lose my device?

Your data is safe on the server:
1. Install app on new device
2. Log in with your credentials
3. All your data will sync

### How do I backup my data?

Automatic backups:
- Data is backed up on server
- No action needed from you

Manual backups:
- Profile → Settings → Backup Data
- Save backup file to safe location

---

## Updates & New Features

### How do I update the app?

- **Android**: Google Play Store → My Apps → Update
- **iOS**: App Store → Updates → Update

Enable auto-updates for automatic updates.

### How often is the app updated?

We release updates:
- Major updates: Every 3-6 months
- Minor updates: Monthly
- Bug fixes: As needed

### Where can I see what's new?

- In-app: Profile → What's New
- App store: Update notes
- Website: Changelog page

### Can I suggest new features?

Yes! We love feedback:
- Profile → Help & Support → Suggest Feature
- Email: feedback@example.com
- Community forums

---

## Getting Help

### How do I contact support?

- **Email**: support@example.com
- **In-app**: Profile → Help & Support → Contact
- **Phone**: [Support Number]
- **Live Chat**: Available in app

### What are support hours?

- **Email**: 24/7 (response within 24 hours)
- **Phone**: 9 AM - 5 PM (Mon-Fri)
- **Live Chat**: 9 AM - 9 PM (Mon-Sat)

### How do I report a bug?

1. Profile → Help & Support
2. Tap "Report a Bug"
3. Describe the issue
4. Include screenshots
5. Submit

We'll investigate and respond within 48 hours.

### Where can I find more help?

- **User Guide**: Complete app documentation
- **Video Tutorials**: Step-by-step guides
- **Community Forums**: Ask other users
- **Knowledge Base**: Common questions

---

## Still Have Questions?

If your question isn't answered here:

1. Check the User Guide
2. Search the Knowledge Base
3. Ask in Community Forums
4. Contact Support

We're here to help!

**Email**: support@example.com
**Phone**: [Support Number]
**Website**: [Your Website]
