# Admin Group Management Integration Tests

## Overview
This test suite provides comprehensive integration tests for the Admin Group Management feature, covering all aspects of group creation, user assignment, member management, and data isolation.

## Test File
- **Location**: `tests/Feature/AdminGroupManagementTest.php`
- **Factory**: `database/factories/AdminGroupFactory.php`

## Test Coverage

### 1. Admin Registration and Group Creation (Requirements 2.1, 2.2, 2.3)
- ✅ `test_admin_registration_creates_group_with_unique_code()` - Verifies that when an admin registers, a unique group code is automatically generated
- ✅ `test_multiple_admins_get_unique_group_codes()` - Ensures each admin gets a different group code

### 2. User Registration with Group Code (Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6)
- ✅ `test_user_registration_with_valid_group_code_joins_group()` - Users can join a group using a valid code
- ✅ `test_user_registration_with_invalid_group_code_fails()` - Invalid codes are rejected
- ✅ `test_organization_mismatch_prevents_group_joining()` - Users from different organizations cannot join
- ✅ `test_organization_matching_is_case_insensitive()` - Organization matching ignores case
- ✅ `test_different_departments_can_join_same_group()` - Department differences are allowed

### 3. Admin Group Member Management (Requirements 4.1, 4.2, 4.3, 4.4, 4.5)
- ✅ `test_admin_can_view_group_members()` - Admins can see their group members
- ✅ `test_admin_can_remove_group_member()` - Admins can remove members from their group
- ✅ `test_admin_cannot_remove_non_group_member()` - Admins cannot remove users from other groups
- ✅ `test_admin_can_regenerate_group_code()` - Admins can generate a new group code
- ✅ `test_admin_can_get_group_info()` - Admins can retrieve their group information

### 4. User Group Joining (Requirements 3.1, 3.6)
- ✅ `test_user_can_join_group_after_registration()` - Users can join groups after initial registration
- ✅ `test_user_cannot_join_multiple_groups()` - Users are restricted to one group
- ✅ `test_user_can_view_their_group_info()` - Users can see their group details

### 5. Authorization Tests (Requirements 4.5, 8.1, 8.2, 8.3, 8.4, 8.5)
- ✅ `test_regular_user_cannot_access_admin_group_endpoints()` - Regular users cannot access admin endpoints
- ✅ `test_unauthenticated_user_cannot_access_group_endpoints()` - Authentication is required

### 6. Multi-Admin Scenarios (Requirements 9.1, 9.2, 9.3, 9.4, 9.5)
- ✅ `test_multiple_admins_in_same_organization_have_separate_groups()` - Data isolation between admin groups
- ✅ `test_admin_cannot_remove_member_from_another_admins_group()` - Cross-group access prevention

### 7. Validation Tests (Requirements 10.1, 10.2, 10.3, 10.4, 1.1, 1.2, 1.3, 1.4)
- ✅ `test_group_code_validation_requires_4_to_6_digits()` - Group code format validation
- ✅ `test_organization_name_validation_during_registration()` - Organization name requirements
- ✅ `test_department_name_is_optional_during_registration()` - Department is optional

## Running the Tests

### Run all admin group management tests:
```bash
php artisan test --filter=AdminGroupManagementTest
```

### Run a specific test:
```bash
php artisan test --filter=test_admin_registration_creates_group_with_unique_code
```

### Run with coverage:
```bash
php artisan test --filter=AdminGroupManagementTest --coverage
```

## Test Database
Tests use the in-memory SQLite database configured in `phpunit.xml`:
- `DB_CONNECTION=sqlite`
- `DB_DATABASE=:memory:`

The `RefreshDatabase` trait ensures a clean database state for each test.

## Dependencies
- Laravel Testing Framework
- PHPUnit
- Sanctum (for authentication)
- AdminGroup Model and Factory
- User Model and Factory

## API Endpoints Tested

### Admin Endpoints (require admin role):
- `GET /api/v1/admin/group` - Get admin's group info
- `POST /api/v1/admin/group/regenerate` - Regenerate group code
- `GET /api/v1/admin/group/members` - List group members
- `DELETE /api/v1/admin/group/members/{id}` - Remove member

### User Endpoints (require authentication):
- `POST /api/v1/user/join-group` - Join a group using code
- `GET /api/v1/user/group-info` - Get user's group info

### Auth Endpoints:
- `POST /api/v1/auth/register` - Register with optional group code

## Test Data Patterns

### Admin User:
```php
[
    'role' => 'admin',
    'organization_name' => 'Test Organization',
    'department_name' => 'IT Department',
]
```

### Regular User:
```php
[
    'role' => 'user',
    'organization_name' => 'Test Organization',
    'admin_group_id' => $adminGroup->id,
]
```

### Admin Group:
```php
[
    'admin_user_id' => $admin->id,
    'group_code' => '123456',
    'is_active' => true,
]
```

## Notes
- All tests use the `RefreshDatabase` trait to ensure isolation
- Tests verify both successful operations and error conditions
- Authorization checks are thoroughly tested
- Organization name matching is case-insensitive
- Group codes must be 4-6 digits numeric
- Users can only belong to one group at a time
