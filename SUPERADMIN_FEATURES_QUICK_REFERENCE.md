# SuperAdmin Features Quick Reference

## SuperAdmin Registration

### For Users
1. Select SuperAdmin flavor when building the app
2. Fill in registration form:
   - Username
   - Email
   - Password
   - Organization Name (required)
   - Department Name (optional)
   - **SuperAdmin Group Name (required)** - Name for your admin group
3. Submit registration
4. **Important:** Save the SuperAdmin group code displayed in the success dialog
5. Share this code with admins who want to join your group

### For Developers
```dart
// Registration is handled automatically by the register page
// For SuperAdmin flavor, the following fields are sent:
{
  'name': username,
  'email': email,
  'password': password,
  'role': 'superAdmin',
  'organization_name': organizationName,
  'admin_group_name': adminGroupName, // Required for SuperAdmin
}

// Response includes:
{
  'user': {...},
  'token': 'Bearer token',
  'super_admin_group_code': '6-digit code',
  'admin_group_name': 'Group name'
}
```

## SuperAdmin Analytics

### Accessing Analytics
```dart
import 'package:your_app/features/superadmin/presentation/pages/superadmin_analytics_page.dart';

// Navigate to analytics page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SuperAdminAnalyticsPage(),
  ),
);
```

### API Usage
```dart
import 'package:your_app/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart';

final datasource = SuperAdminAnalyticsApiDatasource(
  apiClient: apiClient,
);

// Fetch analytics
final analytics = await datasource.getAnalytics(
  period: '15days', // or 'month', 'all'
);

// Access data
for (final group in analytics.adminGroups) {
  print('Group: ${group.adminGroupName}');
  print('Admins: ${group.adminCount}');
  print('Users: ${group.userCount}');
  print('Transfers: ${group.transferStatistics.totalCount}');
  print('Expenses: ${group.expenseStatistics.totalCount}');
}
```

### Available Periods
- `'15days'` - Last 15 days
- `'month'` - Last month
- `'all'` - All time

## SuperAdmin Group Management

### Accessing Group Management
```dart
import 'package:your_app/features/superadmin/presentation/pages/superadmin_group_management_page.dart';

// Navigate to group management page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SuperAdminGroupManagementPage(),
  ),
);
```

### API Usage

#### Get Group Info
```dart
import 'package:your_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';

final datasource = SuperAdminGroupApiDatasource(
  apiClient: apiClient,
);

// Get group info
final groupInfo = await datasource.getGroupInfo();
print('Group: ${groupInfo.name}');
print('Code: ${groupInfo.groupCode}');
print('Members: ${groupInfo.memberCount}');
```

#### Get Members (Paginated)
```dart
// Get first page
final response = await datasource.getMembers(
  page: 1,
  perPage: 15,
);

print('Members: ${response.data.length}');
print('Has more: ${response.hasMore}');
print('Current page: ${response.currentPage}');
print('Total: ${response.total}');

// Access members
for (final member in response.data) {
  print('Admin: ${member.name} (${member.email})');
  print('Group: ${member.adminGroupName}');
  print('Users: ${member.userCount}');
}
```

#### Regenerate Group Code
```dart
// Regenerate code
final newGroupInfo = await datasource.regenerateCode();
print('New code: ${newGroupInfo.groupCode}');

// Old code is now invalid
// Share new code with admins
```

#### Remove Member
```dart
// Remove admin from group
await datasource.removeMember(adminId);

// Member is removed from SuperAdmin group
// Their admin group remains intact
```

## API Endpoints

All endpoints require Bearer token authentication (automatically added):

### Registration
```
POST /auth/register
Body: {
  "name": "string",
  "email": "string",
  "password": "string",
  "role": "superAdmin",
  "organization_name": "string",
  "admin_group_name": "string"
}
Response: {
  "user": {...},
  "token": "string",
  "super_admin_group_code": "string",
  "admin_group_name": "string"
}
```

### Analytics
```
GET /super-admin/analytics?period={period}
Response: {
  "period": "string",
  "admin_groups": [
    {
      "admin_group_id": number,
      "admin_group_name": "string",
      "admin_count": number,
      "user_count": number,
      "transfer_statistics": {
        "total_count": number,
        "total_amount_usd": number,
        "total_amount_syp": number,
        "total_amount_try": number
      },
      "expense_statistics": {
        "total_count": number,
        "total_amount_usd": number,
        "total_amount_syp": number,
        "total_amount_try": number
      }
    }
  ],
  "generated_at": "datetime"
}
```

### Group Info
```
GET /superadmin/group
Response: {
  "id": number,
  "name": "string",
  "group_code": "string",
  "member_count": number,
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Members List
```
GET /superadmin/group/members?page={page}&per_page={perPage}
Response: {
  "data": [
    {
      "id": number,
      "name": "string",
      "email": "string",
      "admin_group_id": number,
      "admin_group_name": "string",
      "user_count": number,
      "created_at": "datetime"
    }
  ],
  "current_page": number,
  "last_page": number,
  "per_page": number,
  "total": number
}
```

### Regenerate Code
```
POST /superadmin/group/regenerate-code
Response: {
  "id": number,
  "name": "string",
  "group_code": "string", // New code
  "member_count": number,
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Remove Member
```
DELETE /superadmin/group/members/{id}
Response: 204 No Content
```

## Error Handling

All API calls may throw exceptions:

```dart
try {
  final analytics = await datasource.getAnalytics(period: 'all');
  // Handle success
} catch (e) {
  // Handle error
  if (e is ApiException) {
    if (e.statusCode == 401) {
      // Token expired - redirect to login
    } else if (e.statusCode == 403) {
      // Access denied - not a SuperAdmin
    } else {
      // Other API error
      print('Error: ${e.message}');
    }
  } else {
    // Network or other error
    print('Error: $e');
  }
}
```

## UI Components

### SuperAdmin Registration Success Dialog
```dart
import 'package:your_app/features/auth/presentation/widgets/superadmin_registration_success_dialog.dart';

SuperAdminRegistrationSuccessDialog.show(
  context: context,
  superAdminGroupCode: 'ABC123',
  adminGroupName: 'My Admin Group',
  onContinue: () {
    Navigator.pushReplacementNamed(context, '/home');
  },
);
```

### Features:
- Displays group code prominently
- Copy to clipboard button
- Warning about code importance
- Shows admin group name
- Continue button
- Cannot be dismissed by back button

## Testing Checklist

### Registration
- [ ] Register as SuperAdmin with all required fields
- [ ] Verify success dialog shows group code
- [ ] Copy code to clipboard
- [ ] Verify navigation to home

### Analytics
- [ ] Load analytics for all periods
- [ ] Verify data displays correctly
- [ ] Test empty state
- [ ] Test error state and retry
- [ ] Test pull-to-refresh

### Group Management
- [ ] View group info and code
- [ ] Copy code to clipboard
- [ ] View member list
- [ ] Test pagination (if many members)
- [ ] Regenerate code
- [ ] Verify new code displays
- [ ] Remove member
- [ ] Verify confirmation dialog
- [ ] Verify list refreshes

### Error Scenarios
- [ ] Test with expired token (401)
- [ ] Test with non-SuperAdmin user (403)
- [ ] Test with network error
- [ ] Test with invalid period parameter

## Common Issues

### "Access Denied" Error
- Ensure user is registered as SuperAdmin (role='superAdmin')
- Verify Bearer token is included in request
- Check token is not expired

### "Invalid Period" Error
- Use only: '15days', 'month', or 'all'
- Check spelling and case

### Empty Analytics
- Verify admin groups exist in database
- Check period filter
- Ensure admins have created transfers/expenses

### Member List Not Loading
- Check pagination parameters
- Verify SuperAdmin group has members
- Check network connection

## Integration with Main App

### Add to Navigation
```dart
// In SuperAdmin home page
ListTile(
  leading: Icon(Icons.analytics),
  title: Text('Analytics'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuperAdminAnalyticsPage(),
      ),
    );
  },
),
ListTile(
  leading: Icon(Icons.group),
  title: Text('Group Management'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuperAdminGroupManagementPage(),
      ),
    );
  },
),
```

### Add to Dependency Injection
```dart
// In injection_container.dart
// No additional setup needed - uses existing ApiClient
```

---

**Last Updated:** November 15, 2025
