# Group Management Quick Guide

## 🎯 How to Access Group Management

### For Admin Users:

```
Login → Admin Dashboard → Click Group Icon (👥) in top-right
```

**Visual Location:**
```
┌─────────────────────────────────────────┐
│ Admin Dashboard        [👥] [🔄]        │  ← Click the group icon here!
├─────────────────────────────────────────┤
│                                         │
│  Statistics                             │
│  ┌──────────┬──────────┐               │
│  │ Users    │ Expenses │               │
│  └──────────┴──────────┘               │
│                                         │
└─────────────────────────────────────────┘
```

## 📋 What You Can Do in Group Management

### 1. View Group Information
- Your 6-character group code
- Group name
- Number of members
- Creation date

### 2. Manage Group Code
- **Copy Code** - Share with team members
- **Regenerate Code** - Create a new code (invalidates old one)

### 3. Manage Members
- View all group members
- See member details (name, email, department)
- Remove members from group
- Search and filter members

## 🔐 Your Group Code

After admin registration, you receive a **6-character alphanumeric code** like:

```
ABC123
```

### Share This Code With:
- Team members who need to join your group
- New employees during onboarding
- Anyone who should access your organization's data

### Security Tips:
- Keep your code private
- Only share with trusted team members
- Regenerate if compromised
- Monitor who joins your group

## 👥 How Regular Users Join

Regular users need your group code during registration:

```
Registration Form
├── Username
├── Email
├── Password
├── Organization Name (required)
├── Department Name (optional)
└── Group Code (required) ← They enter your code here
```

## 🔄 Regenerating Group Code

**When to regenerate:**
- Code has been compromised
- Want to revoke access using old code
- Security policy requires periodic changes

**How to regenerate:**
1. Go to Group Management
2. Click "Regenerate Code" button
3. New code is generated
4. Old code becomes invalid
5. Share new code with team

**Note:** Existing members stay in the group, only the join code changes.

## ❌ Removing Members

**To remove a member:**
1. Go to Group Management
2. Find the member in the list
3. Click remove/delete icon
4. Confirm removal

**What happens:**
- Member loses access to group data
- Member's data remains in system
- Member can rejoin with a new group code

## 🐛 Troubleshooting

### "I don't see the group icon"
- Make sure you're logged in as **admin**
- Check you're on the **Admin Dashboard** tab
- Admin flavor must be enabled

### "Group Management page is empty"
- You may not have created a group yet
- Try logging out and registering as a new admin
- Check your network connection

### "Can't access Group Management"
- Only **admin users** can access this feature
- Regular users see "Group Info" instead
- Check your user role in profile

## 📱 Navigation Routes

```dart
'/group-management'  // Admin: Manage group and members
'/group-info'        // User: View group information
'/join-group'        // User: Join a group with code
```

## 🎨 UI Elements

### Admin Dashboard App Bar:
- **Group Icon (👥)** - Opens Group Management
- **Refresh Icon (🔄)** - Refreshes dashboard data

### Group Management Page:
- Group code display with copy button
- Member list with search/filter
- Regenerate code button
- Remove member buttons

## 💡 Best Practices

1. **Share code securely** - Use secure channels (not public)
2. **Monitor members** - Regularly review who's in your group
3. **Rotate codes** - Regenerate periodically for security
4. **Document members** - Keep track of who should have access
5. **Remove promptly** - Remove members who leave the organization

## 🚀 Quick Actions

| Action | Steps |
|--------|-------|
| View group code | Dashboard → Group Icon → See code at top |
| Copy group code | Dashboard → Group Icon → Click copy button |
| Share with team | Copy code → Send via secure channel |
| Add new member | Share code → They register with it |
| Remove member | Group Management → Find member → Remove |
| Change code | Group Management → Regenerate button |

## 📞 Support

If you encounter issues:
1. Check this guide first
2. Verify you're logged in as admin
3. Check network connection
4. Review error messages
5. Check backend logs
