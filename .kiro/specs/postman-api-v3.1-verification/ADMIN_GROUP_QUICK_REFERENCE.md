# Admin Group Management - Quick Reference

## Overview

Complete Admin Group Management functionality with Bearer token authentication for Admin, SuperAdmin, and User roles.

---

## API Endpoints

### Admin Endpoints

```dart
// Get admin group info
GET /api/v1/admin/group
Authorization: Bearer {token}

// Get group members (paginated)
GET /api/v1/admin/group/members?page=1&per_page=15&search=john&department=IT
Authorization: Bearer {token}

// Regenerate group code
POST /api/v1/admin/group/regenerate
Authorization: Bearer {token}

// Remove member
DELETE /api/v1/admin/group/members/{userId}
Authorization: Bearer {token}
```

### SuperAdmin Endpoints

```dart
// Get SuperAdmin group info
GET /api/v1/superadmin/group
Authorization: Bearer {token}

// Get group members (paginated)
GET /api/v1/superadmin/group/members?page=1&per_page=15
Authorization: Bearer {token}

// Regenerate group code
POST /api/v1/superadmin/group/regenerate-code
Authorization: Bearer {token}

// Remove member
DELETE /api/v1/superadmin/group/members/{adminId}
Authorization: Bearer {token}
```

### User Endpoints

```dart
// Join admin group
POST /api/v1/user/join-group
Authorization: Bearer {token}
Body: { "group_code": "ABC123" }

// Get user's group info
GET /api/v1/user/group-info
Authorization: Bearer {token}
```

---

## Usage Examples

### Admin: Get Group Info

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// In your widget
context.read<AdminGroupBloc>().add(LoadAdminGroupEvent());

// Listen to state
BlocBuilder<AdminGroupBloc, AdminGroupState>(
  builder: (context, state) {
    if (state.adminGroup != null) {
      final group = state.adminGroup!;
      print('Group Code: ${group.groupCode}');
      print('Members: ${group.membersCount}');
    }
    return YourWidget();
  },
)
```

### Admin: Get Group Members

```dart
// Load first page
context.read<AdminGroupBloc>().add(LoadGroupMembersEvent());

// Load more (pagination)
context.read<AdminGroupBloc>().add(
  LoadGroupMembersEvent(
    page: 2,
    loadMore: true,
  ),
);

// With filters
context.read<AdminGroupBloc>().add(
  LoadGroupMembersEvent(
    search: 'john',
    department: 'IT',
  ),
);
```

### Admin: Regenerate Group Code

```dart
// Show confirmation dialog first
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Regenerate Code'),
    content: Text('This will invalidate the old code. Continue?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          context.read<AdminGroupBloc>().add(RegenerateGroupCodeEvent());
        },
        child: Text('Regenerate'),
      ),
    ],
  ),
);

// Listen for success
BlocListener<AdminGroupBloc, AdminGroupState>(
  listener: (context, state) {
    if (state is GroupCodeRegenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code regenerated: ${state.adminGroup.groupCode}')),
      );
    }
  },
  child: YourWidget(),
)
```

### Admin: Remove Member

```dart
// Show confirmation dialog first
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Remove Member'),
    content: Text('Remove ${memberName} from the group?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          context.read<AdminGroupBloc>().add(
            RemoveGroupMemberEvent(userId: userId),
          );
        },
        child: Text('Remove'),
      ),
    ],
  ),
);
```

### User: Join Group

```dart
// Navigate to join page
Navigator.of(context).pushNamed('/join-group');

// Or trigger join directly
context.read<AdminGroupBloc>().add(
  JoinGroupEvent(groupCode: 'ABC123'),
);

// Listen for success
BlocListener<AdminGroupBloc, AdminGroupState>(
  listener: (context, state) {
    if (state is GroupJoined) {
      Navigator.of(context).pushReplacementNamed('/group-info');
    }
  },
  child: YourWidget(),
)
```

### User: View Group Info

```dart
// Load group info
context.read<AdminGroupBloc>().add(LoadUserGroupInfoEvent());

// Display info
BlocBuilder<AdminGroupBloc, AdminGroupState>(
  builder: (context, state) {
    final groupInfo = state.userGroupInfo;
    if (groupInfo != null) {
      return Column(
        children: [
          Text('Group: ${groupInfo.groupName}'),
          Text('Admin: ${groupInfo.adminName}'),
          Text('Members: ${groupInfo.membersCount}'),
        ],
      );
    }
    return Text('Not in a group');
  },
)
```

---

## Navigation Routes

```dart
// Admin Group Management
Navigator.of(context).pushNamed('/group-management');

// User Join Group
Navigator.of(context).pushNamed('/join-group');

// User Group Info
Navigator.of(context).pushNamed('/group-info');
```

---

## DTOs

### AdminGroupDto

```dart
class AdminGroupDto {
  final int id;
  final int adminUserId;
  final String groupCode;        // 6-character code
  final String? groupName;
  final bool isActive;
  final int? membersCount;
  final String createdAt;
  final String updatedAt;
}
```

### GroupMemberDto

```dart
class GroupMemberDto {
  final int id;
  final String name;
  final String email;
  final String role;             // 'user', 'admin', 'superAdmin'
  final String? organizationName;
  final String? departmentName;
  final String createdAt;
}
```

### GroupInfoDto

```dart
class GroupInfoDto {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final DateTime joinedAt;
}
```

---

## Error Handling

### Common Errors

```dart
// 401 Unauthorized - Token expired
// Automatically handled by Bearer token interceptor
// Will attempt token refresh, then redirect to login if fails

// 403 Forbidden - Cannot remove self
if (error.statusCode == 403) {
  showError('You cannot remove yourself from the group');
}

// 404 Not Found - User not in group
if (error.statusCode == 404) {
  showError('User not found or not in your group');
}

// 422 Validation Error - Invalid group code
if (error.statusCode == 422) {
  showError('Invalid group code. Please check and try again.');
}

// 400 Bad Request - Already in group
if (error.statusCode == 400) {
  showError('You are already in a group');
}
```

### Error State Handling

```dart
BlocBuilder<AdminGroupBloc, AdminGroupState>(
  builder: (context, state) {
    if (state is AdminGroupError) {
      return ErrorWidget(
        message: state.errorMessage,
        onRetry: () {
          context.read<AdminGroupBloc>().add(LoadAdminGroupEvent());
        },
      );
    }
    // ... other states
  },
)
```

---

## Validation

### Group Code Validation

```dart
String? validateGroupCode(String? value) {
  if (value == null || value.isEmpty) {
    return 'Group code is required';
  }
  
  if (value.length != 6) {
    return 'Code must be exactly 6 characters';
  }
  
  final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
  if (!alphanumericRegex.hasMatch(value)) {
    return 'Code must contain only letters and numbers';
  }
  
  return null;
}
```

---

## Widgets

### Pre-built Widgets

```dart
// Display group code with copy functionality
GroupCodeDisplay(
  groupCode: 'ABC123',
  onCopy: () {
    context.read<AdminGroupBloc>().add(
      CopyGroupCodeEvent(groupCode: 'ABC123'),
    );
  },
)

// Display list of group members
GroupMemberList(
  members: members,
  isLoading: false,
  hasMore: true,
  onLoadMore: () {
    // Load next page
  },
  onRemoveMember: (userId) {
    // Show confirmation and remove
  },
  currentUserId: currentUserId,
  showRemoveButtons: true,
)

// Group code input field
GroupCodeInput(
  controller: controller,
  onChanged: (value) {
    // Handle input
  },
  errorText: errorText,
)

// Join group form
JoinGroupForm(
  onSubmit: (groupCode) {
    context.read<AdminGroupBloc>().add(
      JoinGroupEvent(groupCode: groupCode),
    );
  },
  isLoading: false,
  errorMessage: null,
)
```

---

## Testing

### Unit Tests

```dart
// Test API datasource
test('getAdminGroup returns AdminGroupDto', () async {
  final datasource = AdminGroupApiDataSourceImpl(
    apiClient: mockApiClient,
    roleService: mockRoleService,
  );
  
  when(mockApiClient.get('/admin/group'))
      .thenAnswer((_) async => Response(
        data: {'data': {'id': 1, 'group_code': 'ABC123'}},
        statusCode: 200,
      ));
  
  final result = await datasource.getAdminGroup();
  
  expect(result.groupCode, 'ABC123');
});
```

### Widget Tests

```dart
testWidgets('GroupManagementPage displays group code', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => mockAdminGroupBloc,
        child: GroupManagementPage(),
      ),
    ),
  );
  
  expect(find.text('ABC123'), findsOneWidget);
});
```

---

## Troubleshooting

### Issue: "No authentication token found"

**Solution:** Ensure user is logged in and token is stored:

```dart
// Check if token exists
final token = await tokenManager.getToken();
if (token == null) {
  // Redirect to login
  Navigator.of(context).pushReplacementNamed('/login');
}
```

### Issue: "Group not found"

**Solution:** Verify user role and group membership:

```dart
// Check user role
final role = await roleService.getCurrentUserRole();
if (role == UserRole.user) {
  // Users must join a group first
  Navigator.of(context).pushNamed('/join-group');
}
```

### Issue: "Cannot remove member"

**Solution:** Check if trying to remove self:

```dart
if (memberUserId == currentUserId) {
  showError('You cannot remove yourself from the group');
  return;
}
```

---

## Best Practices

1. **Always show confirmation dialogs** for destructive actions (regenerate code, remove member)
2. **Use loading states** to provide feedback during API calls
3. **Handle errors gracefully** with user-friendly messages and retry options
4. **Validate input** before submitting (group code format)
5. **Refresh data** after successful operations
6. **Use Bearer token** authentication for all protected endpoints
7. **Log errors** for debugging purposes
8. **Provide empty states** when no data is available
9. **Support pagination** for large member lists
10. **Use localization** for all user-facing text

---

## Related Documentation

- [Task 6 Completion Summary](./TASK_6_COMPLETION_SUMMARY.md)
- [Requirements Document](./requirements.md) - Requirements 12 & 13
- [Design Document](./design.md) - Admin Group Management section
- [API Documentation](./../admin-group-management-integration/API_DOCUMENTATION.md)

---

## Support

For issues or questions:
1. Check the completion summary for detailed implementation notes
2. Review the requirements document for acceptance criteria
3. Check existing tests for usage examples
4. Review API responses in logs for debugging
