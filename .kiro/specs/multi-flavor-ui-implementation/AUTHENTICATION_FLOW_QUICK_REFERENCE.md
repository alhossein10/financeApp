# Authentication Flow Quick Reference

## Overview
Quick reference guide for flavor-specific authentication flows in the Finance app.

## Registration Flows by Flavor

### 🔴 SuperAdmin Registration

**Flavor:** `superAdmin`

**Required Fields:**
- Username
- Email
- Password
- Organization Name
- **Admin Group Name** (unique to SuperAdmin)

**No Group Code Required** - Backend generates automatically

**Success Flow:**
1. Backend creates SuperAdmin account
2. Backend generates unique 6-character SuperAdmin group code
3. Frontend displays `SuperAdminRegistrationSuccessDialog`
4. Dialog shows generated code with copy button
5. User can share code with admins

**Code Example:**
```dart
// Flavor detection
if (FlavorConfig.instance.isSuperAdmin) {
  // Show admin group name field
  // Hide group code input
  // Role = 'superAdmin'
}
```

---

### 🟡 Admin Registration

**Flavor:** `admin`

**Required Fields:**
- Username
- Email
- Password
- Organization Name
- **SuperAdmin Group Code** (6 characters)

**Success Flow:**
1. User enters SuperAdmin group code
2. Backend validates code and adds admin to SuperAdmin's group
3. Backend generates admin's own group code
4. Frontend displays `AdminRegistrationSuccessDialog`
5. Dialog shows admin's group code for sharing with users

**Code Example:**
```dart
// Flavor detection
if (FlavorConfig.instance.isAdmin) {
  // Show SuperAdmin group code input
  // Validate 6 characters
  // Role = 'admin'
}
```

---

### 🟢 User Registration

**Flavor:** `user`

**Required Fields:**
- Username
- Email
- Password
- Organization Name
- **Admin Group Code** (6 characters)

**Success Flow:**
1. User enters admin group code
2. Backend validates code and adds user to admin's group
3. Frontend shows success snackbar
4. Navigate to home page

**Code Example:**
```dart
// Flavor detection
if (FlavorConfig.instance.isUser) {
  // Show admin group code input
  // Validate 6 characters
  // Role = 'user'
}
```

---

## API Endpoints

### Registration Endpoint
```
POST /api/v1/auth/register
```

**Request Body:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string",
  "password_confirmation": "string",
  "role": "superAdmin|admin|user",
  "organization_name": "string",
  "department_name": "string (optional)",
  "admin_group_name": "string (SuperAdmin only)",
  "super_admin_group_code": "string (Admin only)",
  "group_code": "string (User only)"
}
```

**Response:**
```json
{
  "token": "string",
  "token_type": "Bearer",
  "expires_at": "datetime",
  "user": {
    "id": "number",
    "name": "string",
    "email": "string",
    "role": "string"
  },
  "super_admin_group_code": "string (SuperAdmin only)",
  "group_code": "string (Admin only)",
  "admin_group_name": "string (SuperAdmin only)"
}
```

---

## Group Code Validation

### Format Rules
- **Length:** Exactly 6 characters
- **Characters:** Alphanumeric only (a-z, A-Z, 0-9)
- **Case:** Case-insensitive

### Validation Messages
```dart
// Empty
"Group code is required"

// Wrong length
"Group code must be 6 characters"

// Invalid characters
"Group code must contain only letters and numbers"

// Invalid code (from backend)
"The selected group code is invalid"

// Already in group
"You are already in a group"

// Admin trying to join
"Admins cannot join other groups"
```

---

## Success Dialogs

### SuperAdmin Dialog
**File:** `superadmin_registration_success_dialog.dart`

**Features:**
- ✅ Displays generated SuperAdmin group code
- ✅ Shows admin group name
- ✅ Copy-to-clipboard button
- ✅ Warning message
- ✅ Localized (EN/AR)

**Usage:**
```dart
SuperAdminRegistrationSuccessDialog.show(
  context: context,
  superAdminGroupCode: 'ABC123',
  adminGroupName: 'My Organization',
  onContinue: () {
    Navigator.pushReplacementNamed(context, '/home');
  },
);
```

### Admin Dialog
**File:** `admin_registration_success_dialog.dart`

**Features:**
- ✅ Displays generated admin group code
- ✅ Copy-to-clipboard button
- ✅ Instructions for sharing
- ✅ Localized (EN/AR)

**Usage:**
```dart
AdminRegistrationSuccessDialog.show(
  context: context,
  groupCode: 'XYZ789',
  isSuperAdmin: false,
  onContinue: () {
    Navigator.pushReplacementNamed(context, '/home');
  },
);
```

### User Success
**No special dialog** - Uses snackbar:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Account created successfully!'),
    backgroundColor: Colors.green,
  ),
);
```

---

## Flavor Detection

### Check Current Flavor
```dart
// In code
if (FlavorConfig.instance.isSuperAdmin) { }
if (FlavorConfig.instance.isAdmin) { }
if (FlavorConfig.instance.isUser) { }

// Get role string
String role = FlavorConfig.instance.isSuperAdmin 
    ? 'superAdmin' 
    : FlavorConfig.instance.isAdmin 
        ? 'admin' 
        : 'user';
```

### Conditional UI
```dart
// Show field only for SuperAdmin
if (FlavorConfig.instance.isSuperAdmin)
  AuthTextField(
    controller: _adminGroupNameController,
    label: 'SuperAdmin Group Name',
  ),

// Show field only for Admin
if (FlavorConfig.instance.isAdmin)
  AuthTextField(
    controller: _superAdminGroupCodeController,
    label: 'SuperAdmin Group Code',
  ),

// Show field only for User
if (FlavorConfig.instance.isUser)
  GroupCodeInput(
    controller: _groupCodeController,
  ),
```

---

## Error Handling

### Network Errors
```dart
try {
  await register(...);
} on ApiException catch (e) {
  if (e.statusCode == 422) {
    // Validation error
    showError(e.message);
  } else if (e.statusCode == 400) {
    // Bad request (invalid group code)
    showError(e.message);
  } else {
    // Other errors
    showError('Registration failed');
  }
}
```

### Validation Errors
```dart
// Client-side validation
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Group code is required';
  }
  if (value.trim().length != 6) {
    return 'Group code must be 6 characters';
  }
  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
    return 'Group code must contain only letters and numbers';
  }
  return null;
}
```

---

## Testing Checklist

### SuperAdmin Registration
- [ ] Can register without group code
- [ ] Admin group name is required
- [ ] Success dialog shows generated code
- [ ] Copy button works
- [ ] Code is 6 characters
- [ ] Can navigate to home after success

### Admin Registration
- [ ] SuperAdmin group code is required
- [ ] Validates 6-character format
- [ ] Shows error for invalid code
- [ ] Success dialog shows admin's group code
- [ ] Copy button works
- [ ] Can navigate to home after success

### User Registration
- [ ] Admin group code is required
- [ ] Validates 6-character format
- [ ] Shows error for invalid code
- [ ] Success snackbar appears
- [ ] Navigates to home after success
- [ ] Cannot register if already in group

---

## Common Issues

### Issue: "Group code is invalid"
**Cause:** Code doesn't exist in database or is inactive
**Solution:** Verify code with SuperAdmin/Admin who generated it

### Issue: "Already in a group"
**Cause:** User account already linked to a group
**Solution:** User cannot join multiple groups - use existing account

### Issue: "Admins cannot join other groups"
**Cause:** Admin trying to use group code
**Solution:** Admins create their own groups, don't join others

### Issue: Dialog not showing
**Cause:** Missing registration result in state
**Solution:** Check AuthBloc returns RegistrationResult with group code

---

## File Locations

```
lib/
├── core/
│   ├── config/
│   │   └── flavor_config.dart              # Flavor configuration
│   └── services/
│       └── laravel_auth_service.dart       # Registration logic
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── auth_api_datasource.dart  # API interface
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── register_page.dart        # Main registration page
│   │       └── widgets/
│   │           ├── superadmin_registration_success_dialog.dart
│   │           └── admin_registration_success_dialog.dart
│   └── admin_group/
│       └── presentation/
│           └── widgets/
│               └── group_code_input.dart     # Group code input widget
```

---

## Quick Commands

### Run SuperAdmin Flavor
```bash
flutter run --flavor superAdmin -t lib/main_superadmin.dart
```

### Run Admin Flavor
```bash
flutter run --flavor admin -t lib/main_admin.dart
```

### Run User Flavor
```bash
flutter run --flavor user -t lib/main_user.dart
```

### Build APKs
```bash
# SuperAdmin
flutter build apk --flavor superAdmin -t lib/main_superadmin.dart

# Admin
flutter build apk --flavor admin -t lib/main_admin.dart

# User
flutter build apk --flavor user -t lib/main_user.dart
```

---

## Summary

✅ **SuperAdmin:** No code required, generates code for admins
✅ **Admin:** Requires SuperAdmin code, generates code for users
✅ **User:** Requires admin code, joins existing group

All flows are fully implemented with proper validation, error handling, and user feedback.
