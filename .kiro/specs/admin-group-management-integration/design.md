# Admin Group Management Integration - Design

## Overview

This document outlines the design for integrating the Admin Group Management feature into the Flutter frontend. The design follows Clean Architecture principles and integrates seamlessly with the existing codebase structure.

## Architecture

### Layer Structure

```
lib/
├── features/
│   ├── admin_group/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── admin_group_api_datasource.dart
│   │   │   │   └── admin_group_cache_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── admin_group_dto.dart
│   │   │   │   ├── group_member_dto.dart
│   │   │   │   └── group_info_dto.dart
│   │   │   └── repositories/
│   │   │       └── admin_group_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── admin_group.dart
│   │   │   │   ├── group_member.dart
│   │   │   │   └── group_info.dart
│   │   │   ├── repositories/
│   │   │   │   └── admin_group_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_admin_group_usecase.dart
│   │   │       ├── regenerate_group_code_usecase.dart
│   │   │       ├── get_group_members_usecase.dart
│   │   │       ├── remove_group_member_usecase.dart
│   │   │       ├── join_group_usecase.dart
│   │   │       └── get_user_group_info_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── admin_group_bloc.dart
│   │       │   ├── admin_group_event.dart
│   │       │   └── admin_group_state.dart
│   │       ├── pages/
│   │       │   ├── group_management_page.dart
│   │       │   ├── group_info_page.dart
│   │       │   └── join_group_page.dart
│   │       └── widgets/
│   │           ├── group_code_display.dart
│   │           ├── group_member_list.dart
│   │           ├── group_member_card.dart
│   │           └── join_group_form.dart
│   └── auth/
│       └── presentation/
│           ├── pages/
│           │   └── register_page.dart (MODIFIED)
│           └── widgets/
│               └── group_code_input.dart (NEW)
```

## Components and Interfaces

### 1. Data Layer

#### AdminGroupApiDataSource

```dart
abstract class AdminGroupApiDataSource {
  /// Get admin's group information
  Future<AdminGroupDto> getAdminGroup();
  
  /// Regenerate group code
  Future<AdminGroupDto> regenerateGroupCode();
  
  /// Get list of group members
  Future<List<GroupMemberDto>> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  });
  
  /// Remove a member from the group
  Future<void> removeMember(int userId);
  
  /// Join a group using a code
  Future<GroupInfoDto> joinGroup(String groupCode);
  
  /// Get user's group information
  Future<GroupInfoDto> getUserGroupInfo();
}
```

#### AdminGroupCacheDataSource

```dart
abstract class AdminGroupCacheDataSource {
  /// Cache admin group information
  Future<void> cacheAdminGroup(AdminGroupDto group);
  
  /// Get cached admin group
  Future<AdminGroupDto?> getCachedAdminGroup();
  
  /// Cache group members
  Future<void> cacheGroupMembers(List<GroupMemberDto> members);
  
  /// Get cached group members
  Future<List<GroupMemberDto>?> getCachedGroupMembers();
  
  /// Cache user group info
  Future<void> cacheUserGroupInfo(GroupInfoDto groupInfo);
  
  /// Get cached user group info
  Future<GroupInfoDto?> getCachedUserGroupInfo();
  
  /// Clear all group cache
  Future<void> clearGroupCache();
}
```

### 2. Domain Layer

#### Entities

**AdminGroup Entity**
```dart
class AdminGroup {
  final int id;
  final int adminUserId;
  final String groupCode;
  final String? groupName;
  final bool isActive;
  final int? membersCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**GroupMember Entity**
```dart
class GroupMember {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;
  final String? departmentName;
  final DateTime createdAt;
}
```

**GroupInfo Entity**
```dart
class GroupInfo {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final DateTime joinedAt;
}
```

#### Repository Interface

```dart
abstract class AdminGroupRepository {
  Future<Either<Failure, AdminGroup>> getAdminGroup();
  Future<Either<Failure, AdminGroup>> regenerateGroupCode();
  Future<Either<Failure, List<GroupMember>>> getGroupMembers({
    int page = 1,
    int perPage = 15,
    String? search,
    String? department,
  });
  Future<Either<Failure, void>> removeMember(int userId);
  Future<Either<Failure, GroupInfo>> joinGroup(String groupCode);
  Future<Either<Failure, GroupInfo>> getUserGroupInfo();
}
```

### 3. Presentation Layer

#### BLoC State Management

**AdminGroupEvent**
```dart
abstract class AdminGroupEvent extends Equatable {
  const AdminGroupEvent();
}

class LoadAdminGroupEvent extends AdminGroupEvent {}
class RegenerateGroupCodeEvent extends AdminGroupEvent {}
class LoadGroupMembersEvent extends AdminGroupEvent {
  final int page;
  final String? search;
  final String? department;
}
class RemoveGroupMemberEvent extends AdminGroupEvent {
  final int userId;
}
class JoinGroupEvent extends AdminGroupEvent {
  final String groupCode;
}
class LoadUserGroupInfoEvent extends AdminGroupEvent {}
class CopyGroupCodeEvent extends AdminGroupEvent {
  final String groupCode;
}
```

**AdminGroupState**
```dart
class AdminGroupState extends Equatable {
  final AdminGroup? adminGroup;
  final List<GroupMember> members;
  final GroupInfo? userGroupInfo;
  final bool isLoading;
  final bool isLoadingMembers;
  final String? errorMessage;
  final String? successMessage;
  final int currentPage;
  final bool hasMoreMembers;
}
```

## Data Models

### DTOs (Data Transfer Objects)

#### AdminGroupDto
```dart
class AdminGroupDto {
  final int id;
  final int adminUserId;
  final String groupCode;
  final String? groupName;
  final bool isActive;
  final int? membersCount;
  final String createdAt;
  final String updatedAt;
  
  factory AdminGroupDto.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  AdminGroup toEntity();
}
```

#### GroupMemberDto
```dart
class GroupMemberDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;
  final String? departmentName;
  final String createdAt;
  
  factory GroupMemberDto.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  GroupMember toEntity();
}
```

#### GroupInfoDto
```dart
class GroupInfoDto {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final String joinedAt;
  
  factory GroupInfoDto.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  GroupInfo toEntity();
}
```

### Updated User Models

#### UserDto Updates
```dart
class UserDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? organizationName;  // NEW
  final String? departmentName;    // NEW
  final int? adminGroupId;         // NEW
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Deprecated but kept for backward compatibility
  final int? organizationId;
  final int? departmentId;
}
```

## Error Handling

### Error Types

```dart
class GroupCodeInvalidFailure extends Failure {
  GroupCodeInvalidFailure() : super('The selected group code is invalid');
}

class GroupCodeRequiredFailure extends Failure {
  GroupCodeRequiredFailure() : super('The group code field is required');
}

class AlreadyInGroupFailure extends Failure {
  AlreadyInGroupFailure() : super('You are already in a group');
}

class AdminCannotJoinFailure extends Failure {
  AdminCannotJoinFailure() : super('Admins cannot join other groups');
}

class MemberNotFoundFailure extends Failure {
  MemberNotFoundFailure() : super('User not found or not in your group');
}

class CannotRemoveSelfFailure extends Failure {
  CannotRemoveSelfFailure() : super('You cannot remove yourself from the group');
}
```

## Testing Strategy

### Unit Tests

1. **Data Layer Tests**
   - AdminGroupDto serialization/deserialization
   - GroupMemberDto serialization/deserialization
   - GroupInfoDto serialization/deserialization
   - API datasource method tests
   - Cache datasource method tests
   - Repository implementation tests

2. **Domain Layer Tests**
   - Entity creation and validation
   - Use case execution tests
   - Repository interface contract tests

3. **Presentation Layer Tests**
   - BLoC event handling tests
   - BLoC state transition tests
   - BLoC error handling tests

### Widget Tests

1. **Registration Page Tests**
   - Group code input validation
   - Organization/department text input display
   - Admin registration success with group code display
   - User registration with group code requirement

2. **Group Management Page Tests**
   - Group code display with copy button
   - Member list display
   - Remove member confirmation dialog
   - Regenerate code confirmation dialog

3. **Group Info Page Tests**
   - Group information display
   - Join group form display
   - Error message display

### Integration Tests

1. **Registration Flow Tests**
   - Complete admin registration flow
   - Complete user registration flow with group code
   - Registration error handling

2. **Group Management Flow Tests**
   - Load and display group information
   - Load and display member list
   - Remove member flow
   - Regenerate code flow

3. **Join Group Flow Tests**
   - Join group with valid code
   - Join group with invalid code
   - Join group when already in a group

## UI/UX Design

### Registration Page Updates

#### Admin Registration Success Dialog
```
┌─────────────────────────────────────┐
│  ✅ Registration Successful!        │
├─────────────────────────────────────┤
│  Your Group Code:                   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     ABC123     📋 Copy      │   │
│  └─────────────────────────────┘   │
│                                     │
│  Share this code with your team     │
│  members so they can join your      │
│  group during registration.         │
│                                     │
│  [   Continue to Dashboard   ]      │
└─────────────────────────────────────┘
```

#### User Registration - Group Code Input
```
┌─────────────────────────────────────┐
│  Group Code (required):             │
│  [______] (6 characters)            │
│  ℹ️ Get this from your admin        │
└─────────────────────────────────────┘
```

### Group Management Page

```
┌─────────────────────────────────────────────────────┐
│  ← Back          Group Management                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Your Group Code:                                   │
│  ┌───────────────────────────────────────────┐     │
│  │  ABC123  📋 Copy  🔄 Regenerate          │     │
│  └───────────────────────────────────────────┘     │
│                                                     │
│  Group Name: Marketing Team                         │
│  Members: 12                                        │
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │  Search: [________________] 🔍          │       │
│  │  Filter: [All Departments ▼]            │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │  👤 John Doe                            │       │
│  │     john@example.com                    │       │
│  │     Marketing                      [❌] │       │
│  ├─────────────────────────────────────────┤       │
│  │  👤 Jane Smith                          │       │
│  │     jane@example.com                    │       │
│  │     Sales                          [❌] │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
│  [Load More]                                        │
└─────────────────────────────────────────────────────┘
```

### User Group Info Page

```
┌─────────────────────────────────────────────────────┐
│  ← Back          My Group                           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │  Group Code: ABC123                     │       │
│  │  Group Name: Marketing Team             │       │
│  │  Admin: Admin User                      │       │
│  │  Email: admin@example.com               │       │
│  │  Members: 12                            │       │
│  │  Joined: Nov 1, 2025                    │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
│  ℹ️ Contact your admin to leave the group          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Join Group Page

```
┌─────────────────────────────────────────────────────┐
│  ← Back          Join Group                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Enter the 6-character group code provided         │
│  by your admin to join their group.                │
│                                                     │
│  Group Code:                                        │
│  [______]                                           │
│                                                     │
│  [      Join Group      ]                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Localization

### New Translation Keys

```yaml
# English (en)
admin_group:
  group_code: "Group Code"
  group_name: "Group Name"
  members_count: "Members"
  copy_code: "Copy"
  regenerate_code: "Regenerate"
  remove_member: "Remove"
  join_group: "Join Group"
  my_group: "My Group"
  group_management: "Group Management"
  enter_group_code: "Enter group code"
  group_code_hint: "6 characters"
  get_from_admin: "Get this from your admin"
  share_with_team: "Share this code with your team members"
  confirm_remove: "Are you sure you want to remove this member?"
  confirm_regenerate: "Regenerating will invalidate the old code. Continue?"
  joined_at: "Joined"
  admin_contact: "Admin"
  contact_admin_to_leave: "Contact your admin to leave the group"
  
  # Success messages
  code_copied: "Group code copied to clipboard"
  member_removed: "Member removed successfully"
  code_regenerated: "Group code regenerated successfully"
  joined_group: "Successfully joined the group"
  
  # Error messages
  invalid_code: "The selected group code is invalid"
  code_required: "The group code field is required"
  already_in_group: "You are already in a group"
  admin_cannot_join: "Admins cannot join other groups"
  member_not_found: "User not found or not in your group"
  cannot_remove_self: "You cannot remove yourself from the group"

# Arabic (ar)
admin_group:
  group_code: "رمز المجموعة"
  group_name: "اسم المجموعة"
  members_count: "الأعضاء"
  copy_code: "نسخ"
  regenerate_code: "إعادة إنشاء"
  remove_member: "إزالة"
  join_group: "الانضمام للمجموعة"
  my_group: "مجموعتي"
  group_management: "إدارة المجموعة"
  enter_group_code: "أدخل رمز المجموعة"
  group_code_hint: "6 أحرف"
  get_from_admin: "احصل على هذا من المسؤول"
  share_with_team: "شارك هذا الرمز مع أعضاء فريقك"
  confirm_remove: "هل أنت متأكد من إزالة هذا العضو؟"
  confirm_regenerate: "إعادة الإنشاء ستلغي الرمز القديم. هل تريد المتابعة؟"
  joined_at: "انضم في"
  admin_contact: "المسؤول"
  contact_admin_to_leave: "اتصل بالمسؤول لمغادرة المجموعة"
  
  # Success messages
  code_copied: "تم نسخ رمز المجموعة"
  member_removed: "تمت إزالة العضو بنجاح"
  code_regenerated: "تم إعادة إنشاء رمز المجموعة بنجاح"
  joined_group: "تم الانضمام للمجموعة بنجاح"
  
  # Error messages
  invalid_code: "رمز المجموعة المحدد غير صالح"
  code_required: "حقل رمز المجموعة مطلوب"
  already_in_group: "أنت بالفعل في مجموعة"
  admin_cannot_join: "لا يمكن للمسؤولين الانضمام لمجموعات أخرى"
  member_not_found: "المستخدم غير موجود أو ليس في مجموعتك"
  cannot_remove_self: "لا يمكنك إزالة نفسك من المجموعة"
```

## Performance Considerations

### Caching Strategy

1. **Admin Group Information**
   - Cache admin group data for 5 minutes
   - Invalidate on regenerate code
   - Refresh on app resume

2. **Group Members List**
   - Cache member list for 2 minutes
   - Invalidate on member removal
   - Support pagination for large groups

3. **User Group Info**
   - Cache user group info for 10 minutes
   - Invalidate on join group
   - Refresh on app resume

### Optimization

1. **Lazy Loading**
   - Load member list on demand
   - Implement pagination for member list
   - Use infinite scroll for large lists

2. **Network Efficiency**
   - Batch API calls where possible
   - Use debouncing for search functionality
   - Implement retry logic for failed requests

3. **UI Performance**
   - Use const constructors where possible
   - Implement list view builders for member lists
   - Optimize widget rebuilds with keys

## Security Considerations

### Data Protection

1. **Group Code Security**
   - Validate group code format on client side
   - Never store group codes in plain text logs
   - Clear clipboard after 60 seconds when copying codes

2. **Authorization**
   - Verify user role before showing admin features
   - Check permissions before API calls
   - Handle 403 errors gracefully

3. **Data Scoping**
   - Filter all financial data by admin_group_id
   - Validate group membership on data access
   - Handle cross-group data access attempts

## Migration Strategy

### Phase 1: Add New Fields (Week 1)
- Update User model with new fields
- Add backward compatibility handling
- Update API client to handle both old and new formats

### Phase 2: Update Registration (Week 2)
- Modify registration page UI
- Implement group code input
- Add success dialog for admin registration
- Test registration flows

### Phase 3: Add Group Management (Week 3)
- Create group management pages
- Implement member management
- Add group info display
- Test group operations

### Phase 4: Testing & Polish (Week 4)
- Complete integration testing
- Fix bugs and edge cases
- Polish UI/UX
- Update documentation

## Rollback Plan

### If Issues Arise

1. **Immediate Actions**
   - Revert to previous app version
   - Disable group management features via feature flag
   - Switch back to organization/department dropdowns

2. **Data Handling**
   - Keep old organization_id and department_id fields
   - Maintain backward compatibility
   - No data loss during rollback

3. **Communication**
   - Notify users of temporary issues
   - Provide timeline for resolution
   - Offer support channels
