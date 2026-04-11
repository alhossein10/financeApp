# Profile API Quick Reference

## Overview

Complete guide to the Profile API integration with Bearer token authentication.

## 🔑 API Endpoints

### 1. Get Profile
```
GET /api/v1/profile
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "profile_picture_path": "/storage/profiles/1.jpg",
    "last_login": "2024-01-15T10:30:00Z"
  }
}
```

### 2. Update Profile
```
PUT /api/v1/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Smith",
  "email": "john.smith@example.com"
}
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "name": "John Smith",
    "email": "john.smith@example.com",
    "role": "user",
    ...
  }
}
```

**Validation Errors (422):**
```json
{
  "message": "Validation failed",
  "errors": {
    "email": ["The email has already been taken."],
    "name": ["The name must be at least 3 characters."]
  }
}
```

### 3. Change Password
```
PUT /api/v1/profile/password
Authorization: Bearer {token}
Content-Type: application/json

{
  "current_password": "oldPassword123",
  "new_password": "newPassword123",
  "new_password_confirmation": "newPassword123"
}
```

**Success Response (200):**
```json
{
  "message": "Password changed successfully"
}
```

**Error Responses:**
- **401**: Current password is incorrect
- **422**: Validation errors (password too short, passwords don't match)

### 4. Delete Account
```
DELETE /api/v1/profile
Authorization: Bearer {token}
```

**Success Response (204):**
```
No content
```

**Note:** This permanently deletes the user account and all associated data.

### 5. Get User Statistics
```
GET /api/v1/profile/statistics
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "total_expenses": 45,
    "total_expenses_amount": 1250.50,
    "total_transfers": 12,
    "total_transfers_amount": 5000.00,
    "total_incoming": 8,
    "total_incoming_amount": 3500.00,
    "account_age_days": 90,
    "last_login": "2024-01-15T10:30:00Z"
  }
}
```

## 💻 Flutter Implementation

### Data Source

```dart
class ProfileApiDataSourceImpl implements ProfileApiDataSource {
  final ApiClient _apiClient;

  // Get profile (Bearer token added automatically)
  Future<User> getProfile() async {
    final response = await _apiClient.get('/profile');
    final profileDto = ProfileDto.fromJson(response.data['data']);
    return profileDto.toEntity();
  }

  // Update profile
  Future<User> updateProfile({String? name, String? email}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final response = await _apiClient.put('/profile', body: body);
    final profileDto = ProfileDto.fromJson(response.data['data']);
    return profileDto.toEntity();
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.put('/profile/password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });
  }

  // Delete account
  Future<void> deleteAccount() async {
    await _apiClient.delete('/profile');
  }

  // Get statistics
  Future<UserStatisticsModel> getUserStatistics() async {
    final response = await _apiClient.get('/profile/statistics');
    return UserStatisticsModel.fromApiJson(response.data['data']);
  }
}
```

### BLoC Events

```dart
// Load profile
context.read<ProfileBloc>().add(const ProfileLoadRequested());

// Update profile
context.read<ProfileBloc>().add(ProfileUpdateRequested(
  username: 'New Name',
  email: 'new@email.com',
));

// Change password
context.read<ProfileBloc>().add(ProfilePasswordChangeRequested(
  currentPassword: 'old123',
  newPassword: 'new123',
));

// Delete account
context.read<ProfileBloc>().add(const ProfileDeleteAccountRequested());
```

### BLoC States

```dart
// Initial state
ProfileInitial()

// Loading
ProfileLoading()

// Profile loaded
ProfileLoaded(profileData: UserProfileData)

// Update success
ProfileUpdateSuccess(profileData: UserProfileData, message: String)

// Password change success
ProfilePasswordChangeSuccess(message: String)

// Account deleted
ProfileAccountDeleted()

// Error
ProfileError(message: String)
```

## 🎨 UI Components

### 1. Profile Page
Main profile screen with user info and statistics.

**Location:** `lib/features/profile/presentation/pages/profile_page.dart`

**Features:**
- Profile picture with edit option
- User info card (name, email, role)
- Statistics card (expenses, transfers, account age)
- Change password button
- View tutorial button
- Group management (role-based)
- Delete account button
- Logout button

### 2. Edit Profile Dialog
Dialog for updating username and email.

**Location:** `lib/features/profile/presentation/widgets/edit_profile_dialog.dart`

**Validation:**
- Username: 3-30 characters
- Email: Valid email format

### 3. Change Password Dialog
Dialog for changing user password.

**Location:** `lib/features/profile/presentation/widgets/change_password_dialog.dart`

**Features:**
- Current password field
- New password field
- Confirm password field
- Password visibility toggles
- Validation:
  - Current password required
  - New password minimum 8 characters
  - New password must differ from current
  - Passwords must match

### 4. Delete Account Dialog
Confirmation dialog for account deletion.

**Location:** `lib/features/profile/presentation/widgets/delete_account_dialog.dart`

**Features:**
- Warning message
- Consequences list
- Confirmation input (must type "DELETE")
- Loading state
- Automatic logout on success

## 🔐 Bearer Token Authentication

All profile endpoints automatically include Bearer token via `BearerTokenInterceptor`:

```dart
// Automatic token injection
Authorization: Bearer {token}
```

### Token Refresh Flow

1. **401 Detected**: Interceptor catches 401 Unauthorized
2. **Refresh Token**: Calls `POST /auth/refresh` with current Bearer token
3. **Queue Requests**: Queues pending requests during refresh
4. **Retry**: Retries failed requests with new token
5. **Failure**: Clears tokens and redirects to login on refresh failure

### Public Endpoints (No Token)

These endpoints don't require Bearer token:
- `/organizations`
- `/organizations/{id}/departments`
- `/auth/register`
- `/auth/login`
- `/auth/forgot-password`
- `/auth/reset-password`

## 📱 Usage Examples

### Update Profile

```dart
// Show edit profile dialog
showDialog(
  context: context,
  builder: (dialogContext) => BlocProvider.value(
    value: context.read<ProfileBloc>(),
    child: EditProfileDialog(user: currentUser),
  ),
);
```

### Change Password

```dart
// Show change password dialog
showDialog(
  context: context,
  builder: (dialogContext) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: context.read<ProfileBloc>()),
      BlocProvider.value(value: context.read<AuthBloc>()),
    ],
    child: const ChangePasswordDialog(),
  ),
);
```

### Delete Account

```dart
// Show delete account dialog
showDialog(
  context: context,
  builder: (dialogContext) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: context.read<ProfileBloc>()),
      BlocProvider.value(value: context.read<AuthBloc>()),
    ],
    child: const DeleteAccountDialog(),
  ),
);
```

### Listen to Profile Changes

```dart
BlocListener<ProfileBloc, ProfileState>(
  listener: (context, state) {
    if (state is ProfileUpdateSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is ProfilePasswordChangeSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is ProfileAccountDeleted) {
      // Logout and redirect
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (state is ProfileError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: YourWidget(),
)
```

## ⚠️ Error Handling

### Common Errors

**401 Unauthorized:**
- Token expired or invalid
- Automatically triggers token refresh
- Redirects to login if refresh fails

**403 Forbidden:**
- User doesn't have permission
- Display "Access denied" message

**422 Validation Error:**
- Invalid input data
- Display field-specific error messages

**500 Server Error:**
- Backend error
- Display "Server error" with retry option

### Error Messages

```dart
// Profile update validation error
ProfileError(message: "The email has already been taken.")

// Password change error
ProfileError(message: "Current password is incorrect")

// Account deletion error
ProfileError(message: "Failed to delete account")
```

## 🧪 Testing

### Manual Testing Checklist

**Profile Update:**
- [ ] Update username successfully
- [ ] Update email successfully
- [ ] Verify validation errors
- [ ] Verify success message

**Password Change:**
- [ ] Change password successfully
- [ ] Verify incorrect current password error
- [ ] Verify password validation
- [ ] Verify can login with new password

**Account Deletion:**
- [ ] Verify confirmation required
- [ ] Verify account deleted
- [ ] Verify automatic logout
- [ ] Verify data cleared

**Bearer Token:**
- [ ] Verify token included in requests
- [ ] Verify token refresh on 401
- [ ] Verify logout on refresh failure

## 📊 Statistics Display

The profile page displays comprehensive user statistics:

- **Total Expenses**: Count and total amount
- **Total Transfers**: Count and total amount
- **Total Incoming**: Count and total amount
- **Account Age**: Days since registration
- **Last Login**: Timestamp of last login

Statistics are fetched from `GET /profile/statistics` and displayed in the `ProfileStatisticsCard` widget.

## 🎯 Best Practices

1. **Always validate input** before sending to API
2. **Show loading states** during API calls
3. **Display success messages** for user feedback
4. **Handle all error cases** with user-friendly messages
5. **Refresh profile data** after updates
6. **Confirm destructive actions** (like account deletion)
7. **Clear local data** after account deletion
8. **Use Bearer token** for all protected endpoints

## 📝 Notes

- Bearer token is automatically added by the interceptor
- Token refresh is handled automatically on 401 errors
- Profile picture upload requires file upload feature
- Account deletion is permanent and cannot be undone
- Password must be at least 8 characters
- Email changes do not require re-authentication

## 🔗 Related Documentation

- [Bearer Token Verification](./lib/core/api/BEARER_TOKEN_VERIFICATION.md)
- [API Documentation](./API_DOCUMENTATION.md)
- [Error Handling Guide](./ERROR_HANDLING_GUIDE.md)
- [Task 13 Completion Summary](./TASK_13_PROFILE_API_VERIFICATION.md)
