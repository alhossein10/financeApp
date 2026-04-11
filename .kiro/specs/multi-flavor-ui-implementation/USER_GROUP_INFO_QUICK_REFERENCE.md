# User Group Information - Quick Reference Guide

## Overview
This guide provides quick access to the User Group Information feature implementation for regular users.

---

## API Endpoints

### Join Group
```
POST /api/v1/user/join-group
Body: { "group_code": "ABC123" }
Response: GroupInfoDto
```

### Get Group Info
```
GET /api/v1/user/group-info
Response: GroupInfoDto
```

---

## Usage Examples

### 1. Using the API Datasource

```dart
import 'package:finance_app/features/user/data/datasources/user_group_api_datasource.dart';

// Inject the datasource
final userGroupApi = UserGroupApiDataSourceImpl(
  apiClient: apiClient,
);

// Join a group
try {
  final groupInfo = await userGroupApi.joinGroup('ABC123');
  print('Joined group: ${groupInfo.groupName}');
} on ApiException catch (e) {
  if (e.statusCode == 422) {
    print('Invalid group code');
  } else if (e.statusCode == 400) {
    print('Already in a group');
  }
}

// Get group info
try {
  final groupInfo = await userGroupApi.getUserGroupInfo();
  print('Group: ${groupInfo.groupName}');
  print('Admin: ${groupInfo.adminName}');
  print('Members: ${groupInfo.membersCount}');
} on ApiException catch (e) {
  if (e.statusCode == 404) {
    print('Not in any group');
  }
}
```

### 2. Navigation

```dart
// Navigate to Join Group page
Navigator.pushNamed(context, '/join-group');

// Navigate to Group Info page
Navigator.pushNamed(context, '/group-info');
```

### 3. Using the BLoC

```dart
import 'package:finance_app/features/admin_group/presentation/bloc/admin_group_bloc.dart';

// Join a group
context.read<AdminGroupBloc>().add(
  JoinGroupEvent(groupCode: 'ABC123'),
);

// Load group info
context.read<AdminGroupBloc>().add(
  LoadUserGroupInfoEvent(),
);

// Listen to state changes
BlocListener<AdminGroupBloc, AdminGroupState>(
  listener: (context, state) {
    if (state is GroupJoined) {
      // Navigate to group info
      Navigator.pushNamed(context, '/group-info');
    } else if (state is AdminGroupError) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Error')),
      );
    }
  },
  child: YourWidget(),
);
```

---

## Group Code Validation

### Rules
- **Length:** Exactly 6 characters
- **Characters:** Alphanumeric only (A-Z, 0-9)
- **Case:** Automatically converted to uppercase

### Validation Function
```dart
String? validateGroupCode(String code) {
  if (code.isEmpty) {
    return 'Group code is required';
  }
  
  if (code.length != 6) {
    return 'Code must be exactly 6 characters';
  }
  
  final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
  if (!alphanumericRegex.hasMatch(code)) {
    return 'Code must contain only letters and numbers';
  }
  
  return null; // Valid
}
```

---

## Error Handling

### Common Error Codes

| Status Code | Meaning | User Message |
|------------|---------|--------------|
| 200 | Success | Operation completed |
| 400 | Bad Request | Already in a group |
| 404 | Not Found | Not in any group |
| 422 | Validation Error | Invalid group code |
| 500 | Server Error | Server error occurred |

### Error Handling Example
```dart
try {
  final groupInfo = await userGroupApi.joinGroup(code);
  // Success
} on ApiException catch (e) {
  switch (e.statusCode) {
    case 422:
      showError('Invalid group code. Please check and try again.');
      break;
    case 400:
      showError('You are already in a group.');
      break;
    case 404:
      showError('Group not found.');
      break;
    default:
      showError('An error occurred. Please try again.');
  }
}
```

---

## UI Components

### 1. Join Group Page
```dart
import 'package:finance_app/features/admin_group/presentation/pages/join_group_page.dart';

// Use in navigation
MaterialPageRoute(
  builder: (context) => BlocProvider(
    create: (context) => sl<AdminGroupBloc>(),
    child: const JoinGroupPage(),
  ),
);
```

### 2. Group Info Page
```dart
import 'package:finance_app/features/admin_group/presentation/pages/group_info_page.dart';

// Use in navigation
MaterialPageRoute(
  builder: (context) => BlocProvider(
    create: (context) => sl<AdminGroupBloc>()
      ..add(LoadUserGroupInfoEvent()),
    child: const GroupInfoPage(),
  ),
);
```

### 3. Group Code Input Widget
```dart
import 'package:finance_app/features/admin_group/presentation/widgets/group_code_input.dart';

GroupCodeInput(
  controller: codeController,
  enabled: true,
  autofocus: true,
  onChanged: (value) {
    print('Code: $value');
  },
  onSubmitted: () {
    // Handle submission
  },
);
```

---

## Data Models

### GroupInfoDto
```dart
class GroupInfoDto {
  final String groupCode;        // 6-character code
  final String? groupName;       // Optional group name
  final String adminName;        // Admin's name
  final String adminEmail;       // Admin's email
  final int membersCount;        // Number of members
  final String joinedAt;         // ISO 8601 date string
}
```

### Example Response
```json
{
  "success": true,
  "data": {
    "group": {
      "group_code": "ABC123",
      "group_name": "Finance Team",
      "members_count": 5,
      "admin": {
        "name": "John Doe",
        "email": "john@example.com"
      }
    },
    "joined_at": "2024-01-15T10:30:00Z"
  }
}
```

---

## State Management

### BLoC Events
```dart
// Join a group
JoinGroupEvent(groupCode: 'ABC123')

// Load user's group info
LoadUserGroupInfoEvent()

// Copy group code to clipboard
CopyGroupCodeEvent(groupCode: 'ABC123')
```

### BLoC States
```dart
// Initial/Loading
AdminGroupLoading()

// Successfully joined
GroupJoined(groupInfo: GroupInfoDto)

// Group info loaded
AdminGroupState(userGroupInfo: GroupInfoDto)

// Error occurred
AdminGroupError(errorMessage: String)
```

---

## Profile Integration

### Check if User is in a Group
```dart
// In profile page
final user = profileData.user;

if (user.adminGroupId != null) {
  // User is in a group
  // Show "My Group" button
} else {
  // User is not in a group
  // Show "Join a Group" button
}
```

### Profile Buttons
```dart
// For users WITH a group
OutlinedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/group-info'),
  icon: const Icon(Icons.group),
  label: const Text('My Group'),
);

// For users WITHOUT a group
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/join-group'),
  icon: const Icon(Icons.group_add),
  label: const Text('Join a Group'),
);
```

---

## Localization Keys

### Join Group Page
- `admin_group.join_group` - "Join Group"
- `admin_group.join_description` - Description text
- `admin_group.join_instructions` - Instructions
- `admin_group.joined_group` - Success message

### Group Info Page
- `admin_group.my_group` - "My Group"
- `admin_group.group_name` - "Group Name"
- `admin_group.admin_contact` - "Admin"
- `admin_group.members_count` - "Members"
- `admin_group.joined_at` - "Joined"
- `admin_group.not_in_group` - "Not in a group"
- `admin_group.contact_admin_to_leave` - Help text

### Validation Messages
- `admin_group.code_required` - "Group code is required"
- `admin_group.code_must_be_6` - "Code must be exactly 6 characters"
- `admin_group.code_invalid_chars` - "Invalid characters"
- `admin_group.code_too_short` - "Code too short"
- `admin_group.code_too_long` - "Code too long"

---

## Testing

### Unit Test Example
```dart
test('joinGroup returns GroupInfoDto on success', () async {
  // Arrange
  final mockApiClient = MockApiClient();
  final datasource = UserGroupApiDataSourceImpl(
    apiClient: mockApiClient,
  );
  
  when(mockApiClient.post(any, body: any))
    .thenAnswer((_) async => Response(
      statusCode: 200,
      data: {
        'data': {
          'group_code': 'ABC123',
          'group_name': 'Test Group',
          'admin_name': 'Admin',
          'admin_email': 'admin@test.com',
          'members_count': 5,
          'joined_at': '2024-01-01T00:00:00Z',
        },
      },
    ));
  
  // Act
  final result = await datasource.joinGroup('ABC123');
  
  // Assert
  expect(result.groupCode, 'ABC123');
  expect(result.groupName, 'Test Group');
});
```

### Widget Test Example
```dart
testWidgets('Join Group Page displays correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => MockAdminGroupBloc(),
        child: const JoinGroupPage(),
      ),
    ),
  );
  
  expect(find.text('Join Group'), findsOneWidget);
  expect(find.byType(GroupCodeInput), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

---

## Common Issues & Solutions

### Issue 1: "Already in a group" error
**Solution:** User can only be in one group at a time. Contact admin to leave current group first.

### Issue 2: "Invalid group code" error
**Solution:** Verify the code is exactly 6 characters and contains only letters and numbers.

### Issue 3: Group info not loading
**Solution:** Check if user has `adminGroupId` set. If null, user is not in a group.

### Issue 4: Navigation not working
**Solution:** Ensure routes are registered in app router:
```dart
'/join-group': (context) => const JoinGroupPage(),
'/group-info': (context) => const GroupInfoPage(),
```

---

## Best Practices

1. **Always validate group code format before API call**
   - Saves unnecessary network requests
   - Provides immediate feedback

2. **Handle all error cases**
   - Invalid code (422)
   - Already in group (400)
   - Not in group (404)
   - Network errors

3. **Provide clear user feedback**
   - Loading states
   - Success messages
   - Error messages
   - Help text

4. **Use localization**
   - All user-facing text should be localized
   - Support RTL languages

5. **Cache group info**
   - Reduce API calls
   - Improve performance
   - Enable offline viewing

---

## Quick Checklist

### For Joining a Group
- [ ] User is not already in a group
- [ ] Group code is 6 characters
- [ ] Code is alphanumeric only
- [ ] API endpoint is accessible
- [ ] Error handling is in place
- [ ] Success navigation works

### For Viewing Group Info
- [ ] User is in a group
- [ ] API endpoint is accessible
- [ ] All fields display correctly
- [ ] Refresh functionality works
- [ ] Error states are handled

---

## Support

For issues or questions:
1. Check the implementation summary document
2. Review the requirements document
3. Test with the provided examples
4. Check API logs for errors
5. Verify user's group membership status

---

**Last Updated:** 2024
**Version:** 1.0
**Status:** Production Ready
