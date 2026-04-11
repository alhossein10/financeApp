# Superadmin Group Management - Quick Reference

## Overview
Quick reference guide for the Superadmin Group Management feature components.

## Components

### 1. AdminListCard Widget

**Purpose**: Display an Admin member in a list with profile, name, email, and tap handling.

**Import**:
```dart
import 'package:finance_app/features/superadmin/presentation/widgets/admin_list_card.dart';
```

**Usage**:
```dart
AdminListCard(
  admin: adminMemberDto,
  onTap: () {
    // Handle tap - typically show details
    _showAdminDetails(context, adminMemberDto);
  },
  onRemove: () {
    // Optional - handle remove action
    _removeMember(adminMemberDto);
  },
)
```

**Properties**:
- `admin` (required): `AdminMemberDto` - The admin member data
- `onTap` (required): `VoidCallback` - Called when card is tapped
- `onRemove` (optional): `VoidCallback?` - Called when remove button is pressed

**Features**:
- Circular avatar with person icon
- Displays name, email, group name, and user count
- Chevron indicator for tap affordance
- Optional remove button (red delete icon)
- Supports Arabic and English

---

### 2. AdminDetailSheet Widget

**Purpose**: Display detailed financial information for an Admin in a bottom sheet.

**Import**:
```dart
import 'package:finance_app/features/superadmin/presentation/widgets/admin_detail_sheet.dart';
```

**Usage**:
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.7,
    minChildSize: 0.5,
    maxChildSize: 0.9,
    builder: (context, scrollController) => AdminDetailSheet(
      admin: adminMemberDto,
    ),
  ),
);
```

**Properties**:
- `admin` (required): `AdminMemberDto` - The admin member data

**Features**:
- Fetches Admin's fund box data automatically
- Displays balances in USD, SYP, and TRY
- Color-coded currency cards:
  - USD: Green with $ symbol
  - SYP: Blue with ل.س symbol
  - TRY: Orange with ₺ symbol
- Shows last updated timestamp
- Handles loading, error, and empty states
- Draggable handle for easy dismissal
- Close button in header
- Supports Arabic and English

**States**:
- **Loading**: Shows circular progress indicator
- **Error**: Shows error icon, message, and retry button
- **Success**: Shows currency balance cards
- **Empty**: Shows "No data available" message

---

### 3. SuperAdminGroupApiDatasource

**Purpose**: API datasource for Superadmin group operations.

**Import**:
```dart
import 'package:finance_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';
```

**Initialization**:
```dart
final datasource = SuperAdminGroupApiDatasource(
  apiClient: di.sl<ApiClient>(),
);
```

**Methods**:

#### Get Group Info
```dart
Future<SuperAdminGroupDto> getGroupInfo()
```
Returns the Superadmin's group information including name, code, and member count.

#### Get Members (Paginated)
```dart
Future<PaginatedResponse<AdminMemberDto>> getMembers({
  int page = 1,
  int perPage = 15,
})
```
Returns paginated list of admin members in the group.

#### Regenerate Group Code
```dart
Future<SuperAdminGroupDto> regenerateCode()
```
Generates a new group code and returns updated group info.

#### Remove Member
```dart
Future<void> removeMember(int adminId)
```
Removes an admin member from the group.

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/utils/pagination_helper.dart';
import 'package:finance_app/injection_container.dart' as di;
import 'package:finance_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';
import 'package:finance_app/features/superadmin/data/models/admin_member_dto.dart';
import 'package:finance_app/features/superadmin/presentation/widgets/admin_list_card.dart';
import 'package:finance_app/features/superadmin/presentation/widgets/admin_detail_sheet.dart';

class MyGroupPage extends StatefulWidget {
  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  late final SuperAdminGroupApiDatasource _datasource;
  List<AdminMemberDto> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _datasource = SuperAdminGroupApiDatasource(
      apiClient: di.sl<ApiClient>(),
    );
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _datasource.getMembers(page: 1);
      setState(() {
        _members = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _showAdminDetails(AdminMemberDto admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AdminDetailSheet(
          admin: admin,
        ),
      ),
    );
  }

  Future<void> _removeMember(AdminMemberDto admin) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Removal'),
        content: Text('Remove ${admin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _datasource.removeMember(admin.id);
        _loadMembers(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member removed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Group Management')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return AdminListCard(
                  admin: member,
                  onTap: () => _showAdminDetails(member),
                  onRemove: () => _removeMember(member),
                );
              },
            ),
    );
  }
}
```

---

## API Endpoints

### Get Group Info
```
GET /api/v1/superadmin/group
```
**Response**:
```json
{
  "data": {
    "id": 1,
    "name": "My Organization",
    "group_code": "ABC123",
    "member_count": 5,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

### Get Members
```
GET /api/v1/superadmin/group/members?page=1&per_page=15
```
**Response**:
```json
{
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "admin_group_id": 10,
      "admin_group_name": "Sales Team",
      "user_count": 8,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 5,
    "last_page": 1
  }
}
```

### Regenerate Code
```
POST /api/v1/superadmin/group/regenerate-code
```
**Response**: Same as Get Group Info

### Remove Member
```
DELETE /api/v1/superadmin/group/members/{id}
```
**Response**: 200 or 204 (No Content)

---

## Localization Keys

The components support both English and Arabic. Key phrases:

| English | Arabic |
|---------|--------|
| Group Management | إدارة مجموعة SuperAdmin |
| Group: | المجموعة: |
| users | مستخدم |
| Remove | إزالة |
| Financial Balances | الأرصدة المالية |
| Last updated: | آخر تحديث: |
| Error loading data | خطأ في تحميل البيانات |
| Retry | إعادة المحاولة |
| No data available | لا توجد بيانات |

---

## Styling

### Colors
- **USD**: `Colors.green` (with 0.1 opacity background)
- **SYP**: `Colors.blue` (with 0.1 opacity background)
- **TRY**: `Colors.orange` (with 0.1 opacity background)
- **Primary**: `theme.primaryColor`
- **Error**: `Colors.red`

### Spacing
- Card margin: `EdgeInsets.only(bottom: 8)`
- Card padding: `EdgeInsets.all(12)` or `EdgeInsets.all(16)`
- Avatar radius: 28 (list) or 32 (detail)
- Icon size: 32 (list) or 36 (detail)

### Typography
- **Title**: `titleLarge` with `fontWeight.bold`
- **Subtitle**: `bodyMedium` with grey color
- **Small text**: `bodySmall` with grey color
- **Currency amount**: `titleLarge` with `fontWeight.bold`

---

## Error Handling

All components handle errors gracefully:

1. **Network Errors**: Display error message with retry button
2. **API Errors**: Show specific error message from backend
3. **Empty States**: Display appropriate "no data" message
4. **Loading States**: Show progress indicators

Example error handling:
```dart
try {
  final data = await _datasource.getMembers();
  // Handle success
} catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Best Practices

1. **Always use DraggableScrollableSheet** for AdminDetailSheet to allow users to adjust size
2. **Show confirmation dialogs** before destructive actions (remove member)
3. **Refresh data** after mutations (remove, regenerate code)
4. **Handle loading states** to provide feedback during API calls
5. **Use pull-to-refresh** for better UX on list pages
6. **Implement pagination** for large member lists
7. **Cache data** when appropriate to reduce API calls
8. **Log errors** for debugging purposes

---

## Dependencies

Required packages (already in pubspec.yaml):
- `flutter/material.dart` - UI framework
- `intl` - Number and date formatting
- `dio` - HTTP client (via ApiClient)

Required services:
- `ApiClient` - HTTP client with Bearer token interceptor
- `RoleService` - User role management
- Service locator (`injection_container.dart`)

---

## Troubleshooting

### Issue: "Access denied" error
**Solution**: Ensure user has Superadmin role and valid Bearer token

### Issue: Bottom sheet doesn't show
**Solution**: Check that `isScrollControlled: true` and `backgroundColor: Colors.transparent` are set

### Issue: Currency amounts not formatted correctly
**Solution**: Verify that API returns numeric values, not strings

### Issue: Profile images not showing
**Solution**: Currently using placeholder icons. Implement profile image upload feature for actual images.

### Issue: Pagination not working
**Solution**: Ensure scroll controller is attached and `_hasMore` flag is properly managed

---

## Future Enhancements

1. **Profile Images**: Implement actual profile image upload and display
2. **Search**: Add search functionality to filter members
3. **Sorting**: Allow sorting by name, email, or user count
4. **Bulk Actions**: Select multiple members for bulk operations
5. **Export**: Export member list to CSV or PDF
6. **Analytics**: Show charts and graphs for group statistics
7. **Notifications**: Real-time updates when members join/leave
8. **Permissions**: Fine-grained permission management per member
