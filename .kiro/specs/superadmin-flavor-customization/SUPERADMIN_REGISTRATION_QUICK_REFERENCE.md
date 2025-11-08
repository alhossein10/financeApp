# SuperAdmin Registration - Quick Reference

## Overview
SuperAdmin registration flow with automatic group code generation and display.

## Key Features
- ✅ No group code input required during registration
- ✅ Backend automatically generates unique group code
- ✅ Dialog displays group code immediately after registration
- ✅ Copy-to-clipboard functionality
- ✅ Automatic navigation to home after acknowledgment

## Registration Flow

### 1. User Fills Registration Form
```
- Username
- Email
- Password
- Confirm Password
- Organization Name
- Department Name (optional)
```

**Note**: SuperAdmin flavor does NOT require group code input (unlike Admin/User flavors)

### 2. Backend Processing
```
POST /api/register
{
  "username": "...",
  "email": "...",
  "password": "...",
  "role": "superAdmin",
  "organization_name": "...",
  "department_name": "..."
}

Response:
{
  "user": {...},
  "token": "...",
  "superAdminGroupCode": "ABC123",  // Auto-generated
  "adminGroupName": "SuperAdmin Group"
}
```

### 3. Dialog Display
```
┌─────────────────────────────────────┐
│ ✓ Registration Successful!          │
├─────────────────────────────────────┤
│ Group Name                          │
│ ┌─────────────────────────────────┐ │
│ │ SuperAdmin Group                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Your Group Code                     │
│ ┌─────────────────────────────────┐ │
│ │      A B C 1 2 3                │ │
│ │   [📋 Copy Code]                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ℹ️ Share this code with admins     │
│    so they can join your group      │
│                                     │
│         [Continue]                  │
└─────────────────────────────────────┘
```

### 4. Navigation
After clicking "Continue", user is navigated to `/home`

## Code Location

### Main Implementation
- **File**: `lib/features/auth/presentation/pages/register_page.dart`
- **Lines**: 166-230 (BlocListener)

### Dialog Widget
- **File**: `lib/features/auth/presentation/widgets/superadmin_registration_success_dialog.dart`

### State Management
- **File**: `lib/features/auth/presentation/bloc/auth_bloc.dart`
- **State**: `lib/features/auth/presentation/bloc/auth_state.dart`

## Key Code Snippets

### Detecting SuperAdmin Registration Success
```dart
if (FlavorConfig.instance.isSuperAdmin && 
    registrationResult?.superAdminGroupCode != null) {
  // Show dialog
}
```

### Showing Dialog with Navigation
```dart
SuperAdminRegistrationSuccessDialog.show(
  context: context,
  groupCode: registrationResult!.superAdminGroupCode!,
  adminGroupName: registrationResult.adminGroupName ?? 'SuperAdmin Group',
).then((_) {
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/home');
  }
});
```

## Flavor Configuration

### SuperAdmin Flavor
```dart
FlavorConfig.initialize(AppFlavor.superAdmin);
```

### Entry Point
```dart
// lib/main_superadmin.dart
void main() {
  FlavorConfig.initialize(AppFlavor.superAdmin);
  runApp(const MyApp());
}
```

## Testing

### Manual Test Steps
1. Run SuperAdmin flavor: `flutter run -t lib/main_superadmin.dart`
2. Navigate to registration
3. Fill form (no group code field should appear)
4. Submit registration
5. Verify dialog shows with group code
6. Test copy button
7. Click "Continue"
8. Verify navigation to home

### Expected Behavior
- ✅ No group code input field on registration form
- ✅ Dialog appears after successful registration
- ✅ Group code is displayed prominently
- ✅ Copy button works
- ✅ Navigation occurs after dialog dismissal
- ✅ No back navigation to registration page

## Troubleshooting

### Dialog Not Showing
**Check**:
1. Is `FlavorConfig.instance.isSuperAdmin` true?
2. Does `registrationResult.superAdminGroupCode` exist?
3. Is backend returning the group code in response?

### Navigation Not Working
**Check**:
1. Is context still mounted?
2. Is `/home` route defined?
3. Check console for navigation errors

### Group Code Not Copying
**Check**:
1. Is clipboard permission granted?
2. Check `SuperAdminRegistrationSuccessDialog` implementation
3. Verify `Clipboard.setData()` is called

## Related Documentation
- [Task 7 Completion Summary](./TASK_7_REGISTRATION_PAGE_SUMMARY.md)
- [SuperAdmin Registration Success Dialog](./TASK_2_COMPLETION_SUMMARY.md)
- [Requirements Document](./requirements.md)
- [Design Document](./design.md)

## API Requirements

### Backend Endpoint
```
POST /api/register
```

### Required Response Fields for SuperAdmin
```json
{
  "user": {
    "id": 1,
    "username": "superadmin",
    "email": "super@example.com",
    "role": "superAdmin"
  },
  "token": "eyJ...",
  "superAdminGroupCode": "ABC123",
  "adminGroupName": "SuperAdmin Group"
}
```

## Localization Keys

### Required Translations
```
superadmin_registration_success
group_code_generated
share_with_admins
copy_group_code
continue
```

### Usage
```dart
AppLocalizations.of(context).translate('superadmin_registration_success')
```
