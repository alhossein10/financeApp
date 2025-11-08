# Admin Group Transfer Restrictions Test Suite

## Overview

This test suite validates the transfer restrictions implemented for the Admin Group Management feature. It ensures that admins can only transfer funds to users within their group, and regular users follow appropriate transfer restrictions based on their group membership.

## Test Coverage

### Requirements Covered

- **Requirement 7.1**: Admins can create transfers to users within their group
- **Requirement 7.2**: Admins cannot create transfers to users outside their group
- **Requirement 7.3**: Transfer validation returns appropriate error messages
- **Requirement 7.4**: Regular users can transfer to themselves and group members
- **Requirement 7.5**: Regular users without groups can only transfer to themselves

## Test Categories

### 1. Admin Transfer to Group Members Tests

**Purpose**: Verify that admins can successfully transfer funds to users in their group.

- `test_admin_can_transfer_to_group_member()`: Admin creates transfer to a single group member
- `test_admin_can_transfer_to_multiple_group_members()`: Admin creates transfers to multiple group members

**Expected Behavior**:
- Transfer is created successfully (HTTP 201)
- Transfer is stored in database with correct recipient information
- Admin can transfer to any user in their group

### 2. Admin Cannot Transfer to Non-Group Members Tests

**Purpose**: Verify that admins are restricted from transferring to users outside their group.

- `test_admin_cannot_transfer_to_non_group_member()`: Admin tries to transfer to user in different organization
- `test_admin_cannot_transfer_to_user_in_different_admin_group()`: Admin tries to transfer to user in another admin's group (same organization)
- `test_admin_cannot_transfer_to_user_without_group()`: Admin tries to transfer to user not assigned to any group

**Expected Behavior**:
- Transfer request is rejected (HTTP 422)
- Validation error message: "Cannot transfer to user outside your group."
- Transfer is not created in database

### 3. Transfer Validation Error Messages Tests

**Purpose**: Verify that appropriate error messages are returned for invalid transfer attempts.

- `test_transfer_validation_returns_appropriate_error_message()`: Validates error response structure and message
- `test_transfer_validation_with_invalid_recipient_user_id()`: Validates error for non-existent recipient

**Expected Behavior**:
- HTTP 422 status code
- JSON structure includes `message` and `errors.recipient_user_id`
- Clear, actionable error messages

### 4. Regular User Transfer Restrictions Tests

**Purpose**: Verify that regular users follow appropriate transfer restrictions.

- `test_regular_user_can_transfer_to_themselves()`: User creates transfer to themselves
- `test_regular_user_in_group_can_transfer_to_group_member()`: User in group transfers to another group member
- `test_regular_user_in_group_cannot_transfer_to_user_outside_group()`: User in group cannot transfer outside group
- `test_regular_user_without_group_can_only_transfer_to_themselves()`: User without group can only transfer to self
- `test_regular_user_without_group_can_transfer_to_themselves()`: User without group successfully transfers to self

**Expected Behavior**:
- Users can always transfer to themselves
- Users in groups can transfer to other group members
- Users in groups cannot transfer outside their group
- Users without groups can only transfer to themselves
- Error message: "You can only transfer to yourself." (for users without groups)

### 5. Transfer Without recipient_user_id Tests

**Purpose**: Verify that transfers to external recipients (without recipient_user_id) work correctly.

- `test_admin_can_create_transfer_without_recipient_user_id()`: Admin creates transfer to external recipient
- `test_regular_user_can_create_transfer_without_recipient_user_id()`: Regular user creates transfer to external recipient

**Expected Behavior**:
- Transfers without `recipient_user_id` are allowed (external recipients)
- No group validation is performed for external transfers
- Transfer is created successfully

### 6. Cross-Group Isolation Tests

**Purpose**: Verify data isolation between different admin groups.

- `test_admin_from_different_organization_cannot_transfer_to_user()`: Admin from Organization A cannot transfer to user in Organization B
- `test_data_isolation_between_admin_groups_in_same_organization()`: Two admins in same organization have separate groups with isolated transfer permissions

**Expected Behavior**:
- Admins can only transfer to users in their own group
- Even within the same organization, different admin groups are isolated
- Cross-group transfers are rejected with validation errors

## Running the Tests

### Run All Transfer Restriction Tests

```bash
php artisan test --filter=AdminGroupTransferRestrictionsTest
```

### Run Specific Test

```bash
php artisan test --filter=test_admin_can_transfer_to_group_member
```

### Run All Admin Group Tests

```bash
php artisan test tests/Feature/AdminGroupTransferRestrictionsTest.php
```

## Test Data Setup

Each test uses Laravel's `RefreshDatabase` trait to ensure a clean database state. Tests create:

1. **Admin users** with associated admin groups
2. **Regular users** assigned to admin groups
3. **Users without groups** for isolation testing
4. **Multiple organizations** for cross-organization testing

## Validation Rules Tested

### For Admins:
- `recipient_user_id` must belong to a user in the admin's group
- Error: "Cannot transfer to user outside your group."

### For Regular Users in Groups:
- `recipient_user_id` must be themselves or another user in the same group
- Error: "Cannot transfer to user outside your group."

### For Regular Users Without Groups:
- `recipient_user_id` must be themselves
- Error: "You can only transfer to yourself."

### For External Transfers:
- No `recipient_user_id` provided (external recipient)
- No group validation performed

## Integration with Other Features

This test suite integrates with:

1. **Admin Group Management**: Uses admin groups and membership
2. **Transfer Service**: Tests `TransferService::createTransfer()` validation
3. **Transfer Request Validation**: Tests `StoreTransferRequest` validation rules
4. **User Model**: Uses `isAdmin()`, `isUser()`, `isGroupMember()` methods
5. **AdminGroupService**: Uses `getAvailableTransferRecipients()` method

## Expected Test Results

All 23 tests should pass:

- ✅ 2 tests for admin transfers to group members
- ✅ 4 tests for admin restrictions on non-group transfers
- ✅ 2 tests for validation error messages
- ✅ 5 tests for regular user transfer restrictions
- ✅ 2 tests for transfers without recipient_user_id
- ✅ 2 tests for cross-group isolation
- ✅ 6 additional edge case tests

## Notes

- Tests use in-memory SQLite database for speed
- All tests are isolated and can run in any order
- Tests verify both successful operations and error conditions
- Tests ensure data integrity and security boundaries
