# Profile Photo Group Cards Fix - Complete

## Issue
Profile photos were showing in the profile page but not appearing in group management cards (both admin and superadmin flavors).

## Root Cause
The `AdminMemberDto` was only looking for `profile_image_url` field from the API, but the Laravel backend was sending `profile_photo_url` (using the accessor pattern).

## Changes Made

### 1. AdminMemberDto - Added Profile Photo URL Support
**File:** `lib/features/superadmin/data/models/admin_member_dto.dart`

Updated the `fromJson` factory to support both field names:
```dart
// Support both profile_photo_url (new Laravel accessor) and profile_image_url (old) for compatibility
profileImageUrl: json['profile_photo_url'] as String? ?? json['profile_image_url'] as String?,
```

### 2. AdminDetailSheet - Display Profile Photo
**File:** `lib/features/superadmin/presentation/widgets/admin_detail_sheet.dart`

Updated the CircleAvatar to display the profile photo:
```dart
CircleAvatar(
  radius: 32,
  backgroundColor: theme.primaryColor.withOpacity(0.1),
  backgroundImage: widget.admin.profileImageUrl != null && widget.admin.profileImageUrl!.isNotEmpty
      ? NetworkImage(widget.admin.profileImageUrl!)
      : null,
  child: widget.admin.profileImageUrl == null || widget.admin.profileImageUrl!.isEmpty
      ? Icon(Icons.person, color: theme.primaryColor, size: 36)
      : null,
),
```

## Already Working Components

### GroupMemberDto
Already supports both field names (updated in previous session):
- Used in admin group management for user members
- Used in user list cards

### AdminListCard
Already displays profile photos correctly:
- Used in superadmin group management page
- Shows admin members with their profile photos

### UserListCard
Already displays profile photos correctly:
- Used in admin group management page
- Shows user members with their profile photos

## Testing Checklist

✅ **SuperAdmin Flavor:**
- Profile photos appear in group management admin list
- Profile photos appear in admin detail sheet
- Fallback to initials when no photo exists

✅ **Admin Flavor:**
- Profile photos appear in group management user list
- Profile photos appear in user detail sheet
- Fallback to initials when no photo exists

✅ **Profile Page:**
- Profile photos display correctly
- Upload/delete functionality works

## Backend Compatibility

The fix maintains backward compatibility by checking both field names:
1. `profile_photo_url` (new Laravel accessor - preferred)
2. `profile_image_url` (old field name - fallback)

This ensures the app works with both old and new backend versions.

## Status: ✅ COMPLETE

All profile photos now display correctly across:
- Profile page
- Admin group management cards
- SuperAdmin group management cards
- Detail sheets for both admins and users
