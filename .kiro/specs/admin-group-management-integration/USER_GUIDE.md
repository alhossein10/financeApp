# Admin Group Management - User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Admin Workflows](#admin-workflows)
4. [User Workflows](#user-workflows)
5. [Troubleshooting](#troubleshooting)
6. [FAQ](#faq)

---

## Introduction

The Admin Group Management feature allows organizations to manage their teams using simple 6-character group codes. This guide will help you understand how to use this feature effectively.

### What's New?

- **For Admins**: Automatically get a group code when you register. Share it with your team.
- **For Users**: Join your admin's group by entering their group code during registration.
- **Data Privacy**: You only see financial data from members of your group.

### Key Concepts

- **Group Code**: A unique 6-character code (e.g., "ABC123") that identifies your group
- **Admin**: The person who creates and manages the group
- **Member**: A user who joins the admin's group
- **Data Scoping**: Automatic filtering so you only see your group's data

---

## Getting Started

### System Requirements

- Mobile device (Android 5.0+ or iOS 11.0+)
- Internet connection
- Finance App installed

### First Time Setup

#### For Admins

1. Open the Finance App
2. Tap "Register" on the welcome screen
3. Fill in your details:
   - Name
   - Email
   - Password
   - Role: Select "Admin"
   - Organization Name (optional)
   - Department Name (optional)
4. Tap "Register"
5. **Important**: A dialog will show your group code
6. Copy the group code and share it with your team
7. Tap "Continue to Dashboard"

#### For Users

1. Open the Finance App
2. Tap "Register" on the welcome screen
3. Fill in your details:
   - Name
   - Email
   - Password
   - Role: Select "User"
   - **Group Code**: Enter the code from your admin
   - Organization Name (optional)
   - Department Name (optional)
4. Tap "Register"
5. You're now part of your admin's group!

---

## Admin Workflows

### 1. Viewing Your Group Information

**Steps:**
1. Login to the app
2. Open the menu (☰)
3. Tap "Group Management"
4. You'll see:
   - Your group code
   - Group name
   - Total number of members
   - List of all members

**Screenshot Reference:**
```
┌─────────────────────────────────────┐
│  Group Management                   │
├─────────────────────────────────────┤
│  Your Group Code:                   │
│  ┌───────────────────────────┐     │
│  │  ABC123  📋 Copy          │     │
│  └───────────────────────────┘     │
│                                     │
│  Group Name: Marketing Team         │
│  Members: 12                        │
│                                     │
│  [Member List Below]                │
└─────────────────────────────────────┘
```

### 2. Copying Your Group Code

**Steps:**
1. Go to "Group Management"
2. Find your group code at the top
3. Tap the "📋 Copy" button
4. A message confirms "Group code copied to clipboard"
5. Share the code with new team members via:
   - Email
   - WhatsApp
   - SMS
   - Any messaging app

**Tips:**
- Keep your group code secure
- Only share with trusted team members
- Regenerate if compromised

### 3. Viewing Group Members

**Steps:**
1. Go to "Group Management"
2. Scroll down to see the member list
3. Each member card shows:
   - Name
   - Email
   - Department
   - Remove button (❌)

**Features:**
- **Search**: Use the search bar to find specific members
- **Filter**: Filter by department
- **Pagination**: Scroll to load more members (15 per page)

**Screenshot Reference:**
```
┌─────────────────────────────────────┐
│  Search: [________________] 🔍      │
│  Filter: [All Departments ▼]        │
├─────────────────────────────────────┤
│  👤 John Doe                        │
│     john@example.com                │
│     Marketing                  [❌] │
├─────────────────────────────────────┤
│  👤 Jane Smith                      │
│     jane@example.com                │
│     Sales                      [❌] │
└─────────────────────────────────────┘
```

### 4. Removing a Member

**When to Remove:**
- Member leaves the organization
- Member should no longer have access
- Incorrect registration

**Steps:**
1. Go to "Group Management"
2. Find the member in the list
3. Tap the "❌" button next to their name
4. A confirmation dialog appears:
   ```
   Remove Member?
   
   Are you sure you want to remove
   John Doe from the group?
   
   [Cancel]  [Remove]
   ```
5. Tap "Remove" to confirm
6. The member is removed immediately
7. They will no longer see group data

**Important Notes:**
- You cannot remove yourself
- Removed members can rejoin with the group code
- Removal is immediate and cannot be undone

### 5. Regenerating Your Group Code

**When to Regenerate:**
- Group code was shared publicly by mistake
- Security concern
- Want to prevent new members from joining

**Steps:**
1. Go to "Group Management"
2. Tap "🔄 Regenerate" button
3. A warning dialog appears:
   ```
   Regenerate Group Code?
   
   This will invalidate the old code.
   Existing members will not be affected,
   but new users cannot join with the old code.
   
   [Cancel]  [Regenerate]
   ```
4. Tap "Regenerate" to confirm
5. A new code is generated
6. Copy and share the new code with team

**Important Notes:**
- Old code stops working immediately
- Existing members stay in the group
- You must share the new code with new members
- Cannot undo regeneration

### 6. Managing Team Data

As an admin, you can:

**View Dashboard Statistics:**
- Total expenses from all group members
- Total transfers
- Total incoming
- Fund box balances
- All calculated for your group only

**Access All Features:**
- Create and manage expenses
- Create and manage transfers
- Create and manage incoming
- Manage fund boxes
- View reports and exports
- Access audit logs

**Data Visibility:**
- See all data from group members
- Cannot see data from other groups
- Complete data isolation

---

## User Workflows

### 1. Joining a Group During Registration

**Steps:**
1. Get the group code from your admin
2. Open the Finance App
3. Tap "Register"
4. Fill in your details
5. In the "Group Code" field, enter the 6-character code
6. Complete registration
7. You're now part of the group!

**Screenshot Reference:**
```
┌─────────────────────────────────────┐
│  Register                           │
├─────────────────────────────────────┤
│  Name: [________________]           │
│  Email: [________________]          │
│  Password: [________________]       │
│  Role: User ▼                       │
│                                     │
│  Group Code (required):             │
│  [______]                           │
│  ℹ️ Get this from your admin        │
│                                     │
│  Organization: [________________]   │
│  Department: [________________]     │
│                                     │
│  [      Register      ]             │
└─────────────────────────────────────┘
```

### 2. Viewing Your Group Information

**Steps:**
1. Login to the app
2. Open the menu (☰)
3. Tap "My Group"
4. You'll see:
   - Group code
   - Group name
   - Admin name and email
   - Total members
   - Date you joined

**Screenshot Reference:**
```
┌─────────────────────────────────────┐
│  My Group                           │
├─────────────────────────────────────┤
│  Group Code: ABC123                 │
│  Group Name: Marketing Team         │
│  Admin: Admin User                  │
│  Email: admin@example.com           │
│  Members: 12                        │
│  Joined: Nov 1, 2025                │
│                                     │
│  ℹ️ Contact your admin to leave    │
│     the group                       │
└─────────────────────────────────────┘
```

### 3. Joining a Group After Registration

If you registered without a group code:

**Steps:**
1. Login to the app
2. Open the menu (☰)
3. Tap "Join Group"
4. Enter the 6-character group code
5. Tap "Join Group"
6. Success message appears
7. You're now part of the group!

**Screenshot Reference:**
```
┌─────────────────────────────────────┐
│  Join Group                         │
├─────────────────────────────────────┤
│  Enter the 6-character group code   │
│  provided by your admin to join     │
│  their group.                       │
│                                     │
│  Group Code:                        │
│  [______]                           │
│                                     │
│  [      Join Group      ]           │
└─────────────────────────────────────┘
```

### 4. Contacting Your Admin

**To Leave the Group:**
1. Go to "My Group"
2. Note your admin's email
3. Contact them directly
4. Request removal from the group

**For Questions:**
- Contact your admin for group-related questions
- Admin email is shown in "My Group" section

### 5. Using the App

As a user, you can:

**Create Financial Records:**
- Add expenses
- Create transfers
- Record incoming transactions
- Manage fund boxes

**View Data:**
- See your own records
- See records from other group members
- Cannot see data from other groups

**Generate Reports:**
- Export your data
- View statistics
- Access your profile

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Invalid Group Code" Error

**Problem**: You enter a group code but get an error.

**Solutions:**
1. **Check the code format**
   - Must be exactly 6 characters
   - Letters and numbers only
   - Case doesn't matter (ABC123 = abc123)

2. **Verify with your admin**
   - Ask admin to resend the code
   - Code might have been regenerated
   - Copy code directly (don't type manually)

3. **Check for typos**
   - Common mistakes: O vs 0, I vs 1, l vs 1
   - Use copy-paste instead of typing

#### Issue 2: "Already in a Group" Error

**Problem**: You try to join but already belong to a group.

**Solutions:**
1. **Check your current group**
   - Go to "My Group" to see current membership
   - Contact current admin to leave first

2. **Cannot join multiple groups**
   - Each user can only be in one group
   - Must leave current group before joining another

#### Issue 3: Not Seeing Group Data

**Problem**: You joined a group but don't see other members' data.

**Solutions:**
1. **Verify group membership**
   - Go to "My Group"
   - Confirm you're in the correct group

2. **Check data exists**
   - Other members must create data first
   - Data appears immediately after creation

3. **Refresh the app**
   - Pull down to refresh lists
   - Logout and login again
   - Clear app cache if needed

#### Issue 4: Cannot Copy Group Code

**Problem**: Copy button doesn't work.

**Solutions:**
1. **Manual copy**
   - Write down the code
   - Take a screenshot
   - Type it manually when sharing

2. **Check permissions**
   - App needs clipboard permission
   - Grant permission in device settings

#### Issue 5: Removed from Group

**Problem**: You were removed and lost access to data.

**Solutions:**
1. **Contact your admin**
   - Ask why you were removed
   - Request to rejoin if appropriate

2. **Rejoin the group**
   - Get the group code again
   - Use "Join Group" feature
   - Your old data will reappear

---

## FAQ

### General Questions

**Q: What is a group code?**
A: A unique 6-character identifier (like "ABC123") that connects team members to their admin's group.

**Q: Can I be in multiple groups?**
A: No, each user can only belong to one group at a time.

**Q: Is the group code case-sensitive?**
A: No, "ABC123" and "abc123" are the same.

**Q: How many members can be in a group?**
A: There's no limit. Groups can have any number of members.

### Admin Questions

**Q: Can I have multiple admins in one group?**
A: No, each group has one admin. Other members are regular users.

**Q: What happens if I delete my account?**
A: Your group and all member data remain. Consider transferring admin role first (contact support).

**Q: Can I rename my group?**
A: Currently, group names are auto-generated. Contact support for custom names.

**Q: How do I transfer admin role to someone else?**
A: Contact support for admin role transfer.

### User Questions

**Q: Can I leave a group?**
A: Yes, contact your admin to be removed from the group.

**Q: What happens to my data if I leave?**
A: Your data stays with you. You can join another group and keep your data.

**Q: Can I see who else is in my group?**
A: Regular users cannot see the full member list. Only admins can view all members.

**Q: Do I need a group code to use the app?**
A: Yes, all users must be part of a group to access financial features.

### Security Questions

**Q: Is my group code secure?**
A: Yes, but treat it like a password. Only share with trusted team members.

**Q: What if my group code is leaked?**
A: Admins can regenerate the code immediately. Old code stops working.

**Q: Can other groups see my data?**
A: No, data is completely isolated between groups.

**Q: Who can remove me from a group?**
A: Only your admin can remove members from the group.

### Technical Questions

**Q: Does this work offline?**
A: Group management requires internet. Financial features work offline with sync.

**Q: How often is data synced?**
A: Data syncs immediately when online. Offline changes sync when connection returns.

**Q: Can I use this on multiple devices?**
A: Yes, login with the same account on any device.

**Q: What languages are supported?**
A: Currently English and Arabic (العربية).

---

## Language Support

### English Interface

All features are available in English with left-to-right layout.

### Arabic Interface (العربية)

All features are available in Arabic with right-to-left layout.

**To Change Language:**
1. Go to Settings
2. Select Language
3. Choose English or العربية
4. App restarts with new language

### Bilingual Teams

- Each user can choose their preferred language
- Group codes work in both languages
- Data is shared regardless of language setting

---

## Getting Help

### In-App Support

1. Open menu (☰)
2. Tap "Help" or "Support"
3. Submit your question

### Contact Admin

For group-related issues:
- Check "My Group" for admin email
- Contact admin directly

### Technical Support

For app issues:
- Email: support@financeapp.com
- Include:
  - Your email
  - Description of issue
  - Screenshots if possible

---

## Best Practices

### For Admins

1. **Secure Your Code**
   - Don't share publicly
   - Use secure channels (email, direct message)
   - Regenerate if compromised

2. **Manage Members Actively**
   - Remove members who leave
   - Review member list regularly
   - Keep group organized

3. **Communicate Clearly**
   - Inform team about group policies
   - Explain data visibility
   - Provide support to members

### For Users

1. **Keep Code Safe**
   - Don't share your admin's code
   - Store it securely
   - Ask admin if you lose it

2. **Stay Connected**
   - Keep admin contact info
   - Report issues promptly
   - Follow group guidelines

3. **Use Features Properly**
   - Enter accurate data
   - Sync regularly
   - Review your records

---

## Appendix

### Group Code Format

- **Length**: Exactly 6 characters
- **Characters**: Letters (A-Z) and numbers (0-9)
- **Case**: Insensitive (ABC123 = abc123)
- **Examples**: 
  - Valid: ABC123, XYZ789, A1B2C3
  - Invalid: ABC12 (too short), ABC1234 (too long), ABC-123 (special chars)

### Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| Invalid group code | Code doesn't exist or wrong format | Verify code with admin |
| Already in a group | You're already a member | Leave current group first |
| Admins cannot join | Admin role can't join groups | Register as user instead |
| Group code required | Field is empty | Enter the 6-character code |
| Member not found | User doesn't exist in group | Check user ID |
| Cannot remove self | Admins can't remove themselves | Have another admin do it |

### Keyboard Shortcuts

Not applicable for mobile app.

### Accessibility

- Screen reader support
- High contrast mode
- Large text support
- Voice input for codes

---

**Document Version**: 1.0.0  
**Last Updated**: November 1, 2025  
**For App Version**: 1.0.0+

