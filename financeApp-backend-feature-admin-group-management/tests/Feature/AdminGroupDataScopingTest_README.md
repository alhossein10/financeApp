# Admin Group Data Scoping Tests

## Overview

This test file (`AdminGroupDataScopingTest.php`) contains comprehensive integration tests for data scoping functionality in the Admin Group Management system. These tests verify that data isolation works correctly between admin groups and that users can only access data they're authorized to see.

## Test Coverage

### Admin Data Scoping Tests

1. **test_admin_sees_only_group_member_expenses**
   - Verifies that admins can only see expenses from users in their group
   - Tests that expenses from users outside the group are not visible
   - Requirements: 6.1

2. **test_admin_sees_only_group_member_transfers**
   - Verifies that admins can only see transfers from users in their group
   - Tests that transfers from users outside the group are not visible
   - Requirements: 6.2

3. **test_admin_sees_only_group_member_incoming_transactions**
   - Verifies that admins can only see incoming transactions from users in their group
   - Tests that incoming transactions from users outside the group are not visible
   - Requirements: 6.3

### Regular User Data Scoping Tests

4. **test_regular_user_sees_only_own_expenses**
   - Verifies that regular users can only see their own expenses
   - Tests that expenses from other users in the same group are not visible
   - Requirements: 5.1

5. **test_regular_user_sees_only_own_transfers**
   - Verifies that regular users can only see their own transfers
   - Tests that transfers from other users in the same group are not visible
   - Requirements: 5.2

6. **test_regular_user_sees_only_own_incoming_transactions**
   - Verifies that regular users can only see their own incoming transactions
   - Tests that incoming transactions from other users in the same group are not visible
   - Requirements: 5.3

### Cross-Group Data Isolation Tests

7. **test_admin_a_cannot_see_admin_b_group_expenses**
   - Verifies complete data isolation between different admin groups
   - Tests that Admin A cannot see expenses from Admin B's group members
   - Tests that Admin B cannot see expenses from Admin A's group members
   - Requirements: 9.3

8. **test_admin_a_cannot_see_admin_b_group_transfers**
   - Verifies transfer data isolation between different admin groups
   - Tests that Admin A cannot see transfers from Admin B's group members
   - Tests that Admin B cannot see transfers from Admin A's group members
   - Requirements: 9.3

9. **test_admin_a_cannot_see_admin_b_group_incoming_transactions**
   - Verifies incoming transaction data isolation between different admin groups
   - Tests that Admin A cannot see incoming transactions from Admin B's group members
   - Tests that Admin B cannot see incoming transactions from Admin A's group members
   - Requirements: 9.3

10. **test_cross_group_isolation_in_same_organization**
    - Comprehensive test for data isolation when multiple admins exist in the same organization
    - Verifies that even within the same organization, different admin groups maintain complete data isolation
    - Tests all financial data types (expenses, transfers, incoming transactions)
    - Requirements: 9.1, 9.2, 9.3

## Running the Tests

To run these tests, use one of the following commands:

```bash
# Run all admin group data scoping tests
php artisan test --filter=AdminGroupDataScopingTest

# Run a specific test
php artisan test --filter=test_admin_sees_only_group_member_expenses

# Run all feature tests
php artisan test tests/Feature
```

## Test Data Setup

Each test creates the following test data structure:

1. **Admin users** with their respective admin groups
2. **Regular users** assigned to specific admin groups
3. **Financial data** (expenses, transfers, incoming transactions) for each user
4. **Users outside groups** to test isolation

## Expected Behavior

### For Admin Users:
- Can see all financial data from users in their group
- Cannot see financial data from users in other groups
- Cannot see financial data from users not in any group (unless they're the admin themselves)

### For Regular Users:
- Can only see their own financial data
- Cannot see data from other users, even if they're in the same group
- Cannot see data from users in other groups

### Cross-Group Isolation:
- Complete data isolation between different admin groups
- Even within the same organization, different admin groups cannot see each other's data
- Each admin group operates as an independent data silo

## Requirements Covered

This test file covers the following requirements from the Admin Group Management specification:

- **5.1**: Regular users see only their own expenses
- **5.2**: Regular users see only their own transfers
- **5.3**: Regular users see only their own incoming transactions
- **5.4**: Regular users see only their own fund box data
- **5.5**: Regular users cannot access other users' financial data
- **6.1**: Admins see expenses for all users in their group
- **6.2**: Admins see transfers for all users in their group
- **6.3**: Admins see incoming transactions for all users in their group
- **6.4**: Admins see fund box data for all users in their group
- **6.5**: Admins cannot access data from users outside their group
- **9.3**: Data isolation between different admin groups

## Notes

- All tests use Laravel's `RefreshDatabase` trait to ensure a clean database state for each test
- Tests use factories to create test data, ensuring consistency and maintainability
- Each test is independent and can be run in isolation
- Tests verify both positive cases (correct data is returned) and negative cases (unauthorized data is not returned)
