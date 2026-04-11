# Admin Group Management - Quick Reference

## Overview
Admin users can view and manage their group members through a dedicated Group Management page.

## Key Features

### 📋 Group Information
- View group name and member count
- Display and copy group code
- Regenerate group code (with confirmation)

### 👥 Member Management
- View all users in the group
- See user profile, name, email
- View user balances (USD, SYP, TRY)
- Remove members (with confirmation)
- View detailed user information

### 🔄 User Experience
- Pull-to-refresh to update data
- Infinite scroll pagination
- Empty state handling
- Loading indicators
- Error handling with retry

## Usage

### For Developers

#### Import the Page
```dart
import 'package:finance_app/features/admin/presentation/pages/admin_group_management_page.dart';
```

#### Navigate to the Page
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminGroupManagementPage(),
  ),
);
```

#### Use the UserListCard Widget
```dart
import 'package:finance_app/features/admin/presentation/widgets/user_list_card.dart';

UserListCard(
  user: groupMemberDto,
  onTap: () {
    // Handle tap
  },
  onRemove: () {
    // Handle remove
  },
  balanceUsd: 1000.0,
  balanceSyp: 5000000.0,
  balanceTry: 25000.0,
)
```

### For Admin Users

#### Viewing Your Group
1. Open the app (Group Management is the home page)
2. See your group code at the top
3. View the list of all users in your group

#### Copying Group Code
1. Tap the copy icon next to the group code
2. Share the code with users who want to join

#### Regenerating Group Code
1. Tap "Regenerate Code" button
2. Confirm the action
3. New code is displayed with copy option
4. Old code becomes invalid

#### Viewing User Details
1. Tap on any user card
2. View detailed information in the bottom sheet
3. See email, organization, department, join date

#### Removing a Member
1. Tap the delete icon on a user card
2. Confirm the removal
3. User is removed from the group

#### Refreshing Data
1. Pull down on the list to refresh
2. Data is automatically updated

## API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/admin/group` | GET | Get group information |
| `/api/v1/admin/group/members` | GET | Get paginated members list |
| `/api/v1/admin/group/regenerate` | POST | Regenerate group code |
| `/api/v1/admin/group/members/{id}` | DELETE | Remove member |

## Data Models

### AdminGroupDto
```dart
{
  id: int,
  adminUserId: int,
  groupCode: String,
  groupName: String?,
  isActive: bool,
  membersCount: int?,
  createdAt: String,
  updatedAt: String
}
```

### GroupMemberDto
```dart
{
  id: int,
  name: String,
  email: String,
  role: String,
  organizationName: String?,
  departmentName: String?,
  createdAt: String
}
```

## Localization

### Supported Languages
- English (en)
- Arabic (ar)

### Key Translations
| English | Arabic |
|---------|--------|
| Admin Group Management | إدارة مجموعة Admin |
| Group Members | أعضاء المجموعة |
| No users in your group yet | لا يوجد مستخدمين في مجموعتك بعد |
| Group Code | رمز المجموعة |
| Regenerate Code | إعادة إنشاء الرمز |
| Remove | إزالة |
| Confirm Removal | تأكيد الإزالة |

## Styling

### Colors
- **USD Balance:** Green (`Colors.green`)
- **SYP Balance:** Blue (`Colors.blue`)
- **TRY Balance:** Orange (`Colors.orange`)
- **Primary Actions:** Theme primary color
- **Destructive Actions:** Red (`Colors.red`)
- **Warning Actions:** Orange (`Colors.orange`)

### Icons
- **Group:** `Icons.group`
- **User:** `Icons.person`
- **Email:** `Icons.email`
- **Organization:** `Icons.business`
- **Department:** `Icons.apartment`
- **Calendar:** `Icons.calendar_today`
- **Copy:** `Icons.copy`
- **Refresh:** `Icons.refresh`
- **Delete:** `Icons.delete`
- **Info:** `Icons.info_outline`

## Error Handling

### Common Errors
1. **Network Error:** Shows error message with retry button
2. **Authentication Error:** Redirects to login
3. **Permission Error:** Shows "Access denied" message
4. **Not Found Error:** Shows "Group not found" message

### Error Recovery
- Retry button on error screen
- Pull-to-refresh to reload data
- Automatic retry on network restoration

## Performance

### Optimization Features
- Pagination (15 items per page)
- Infinite scroll (loads more at 90% scroll)
- Efficient list rendering with ListView.builder
- Cached API responses
- Debounced scroll events

### Loading States
- Initial load: Full-screen spinner
- Pagination: Bottom spinner
- Pull-to-refresh: Native refresh indicator
- Action feedback: Toast notifications

## Accessibility

### Features
- Semantic labels for screen readers
- Minimum touch target size (48dp)
- High contrast colors
- Keyboard navigation support
- Haptic feedback on actions

## Testing

### Test Files
- Unit tests: `test/features/admin/presentation/widgets/user_list_card_test.dart`
- Widget tests: `test/features/admin/presentation/pages/admin_group_management_page_test.dart`
- Integration tests: `test/integration/admin_group_management_test.dart`

### Test Coverage
- Widget rendering
- User interactions
- API integration
- Error scenarios
- Empty states
- Pagination

## Troubleshooting

### Issue: Members not loading
**Solution:** Check authentication token, verify API endpoint, check network connection

### Issue: Balance not showing
**Solution:** Verify API response includes balance data, check GroupMemberDto parsing

### Issue: Code regeneration fails
**Solution:** Verify admin permissions, check API endpoint, ensure valid session

### Issue: Cannot remove member
**Solution:** Verify admin permissions, check if trying to remove self, verify member exists

## Related Documentation
- [Task 7 Implementation Summary](./TASK_7_ADMIN_GROUP_MANAGEMENT_SUMMARY.md)
- [Requirements Document](./requirements.md) - Requirement 8
- [Design Document](./design.md) - Admin Group Management section
- [API Documentation](../../laravel-backend-integration/API_DOCUMENTATION.md)

## Support
For issues or questions, refer to the main project documentation or contact the development team.
