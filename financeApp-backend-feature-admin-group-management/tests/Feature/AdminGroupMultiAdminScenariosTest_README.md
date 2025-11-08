# Admin Group Multi-Admin Scenarios Test Suite

## Overview

This test suite provides comprehensive feature tests for multi-admin scenarios in the Admin Group Management system. It validates that multiple admins can coexist within the same organization while maintaining proper data isolation and group management capabilities.

## Requirements Coverage

This test suite covers the following requirements from the Admin Group Management specification:

- **Requirement 9.1**: Multiple admins in same organization with separate groups
- **Requirement 9.2**: Each admin has unique group code
- **Requirement 9.3**: Data isolation between different admin groups
- **Requirement 9.4**: Users can only join one group at a time
- **Requirement 9.5**: Complex multi-admin scenarios

## Test Cases

### Requirement 9.1: Multiple Admins in Same Organization

1. **test_multiple_admins_can_exist_in_same_organization**
   - Verifies that multiple admins can be created in the same organization
   - Ensures each admin gets their own unique group
   - Validates that groups are properly separated

2. **test_admins_in_same_organization_have_separate_member_lists**
   - Creates two admins in the same organization with separate groups
   - Adds members to each group
   - Verifies that each admin only sees their own group members

### Requirement 9.2: Unique Group Codes

3. **test_each_admin_gets_unique_group_code**
   - Creates 10 admins and verifies all receive unique group codes
   - Validates group code format (4-6 digits)
   - Ensures no duplicate codes are generated

4. **test_group_code_uniqueness_across_different_organizations**
   - Creates admins in different organizations
   - Verifies group codes are unique across all organizations

5. **test_regenerated_group_codes_remain_unique**
   - Tests that regenerated group codes don't conflict with existing codes
   - Validates uniqueness after code regeneration

### Requirement 9.3: Data Isolation Between Admin Groups

6. **test_complete_data_isolation_between_admin_groups_in_same_organization**
   - Creates two admins in the same organization
   - Creates members and financial data for each group
   - Verifies complete isolation of expenses, transfers, and incoming transactions
   - Ensures Admin A cannot see Admin B's data and vice versa

7. **test_admin_cannot_access_another_admins_group_members**
   - Verifies that admins cannot remove members from other admins' groups
   - Tests authorization checks for cross-group operations

8. **test_data_isolation_with_five_admins_in_same_organization**
   - Stress test with 5 admins in the same organization
   - Each admin has 2 members with expenses
   - Verifies complete data isolation across all 5 groups

9. **test_admin_group_isolation_with_mixed_departments**
   - Tests isolation when users from different departments join different groups
   - Validates that department differences don't affect group isolation

### Requirement 9.4: Users Can Only Join One Group

10. **test_user_cannot_join_second_group_in_same_organization**
    - User joins first group successfully
    - Attempts to join second group fail with 409 status
    - Verifies user remains in first group only

11. **test_user_cannot_join_second_group_during_registration**
    - User registers with group code and joins first group
    - Attempts to join second group after registration fail
    - Validates single group membership constraint

12. **test_user_can_join_different_group_after_being_removed**
    - User is removed from first group by admin
    - User successfully joins second group
    - Validates that removal allows joining another group

13. **test_multiple_users_can_join_same_group_but_not_multiple_groups**
    - 5 users successfully join the same group
    - First user attempts to join second group and fails
    - Validates many-to-one relationship (many users, one group)

### Requirement 9.5: Complex Multi-Admin Scenarios

14. **test_users_choose_which_admin_group_to_join_by_code**
    - Creates 3 admins in same organization
    - 3 users each choose different groups using group codes
    - Verifies each admin sees only their chosen member

15. **test_group_code_regeneration_does_not_affect_existing_members**
    - Admin regenerates group code
    - Existing members remain in the group
    - New users cannot join with old code
    - New users can join with new code

16. **test_complete_multi_admin_workflow**
    - End-to-end scenario with 3 team leads (admins)
    - Team members register and join respective teams
    - Creates financial data for each team
    - Tests member removal and re-joining different team
    - Validates complete workflow from registration to data isolation

## Running the Tests

### Run all multi-admin scenario tests:
```bash
php artisan test --filter=AdminGroupMultiAdminScenariosTest
```

### Run a specific test:
```bash
php artisan test --filter=AdminGroupMultiAdminScenariosTest::test_complete_data_isolation_between_admin_groups_in_same_organization
```

### Run with coverage:
```bash
php artisan test --filter=AdminGroupMultiAdminScenariosTest --coverage
```

## Test Data

The tests use Laravel factories to create:
- Admin users with role='admin'
- Regular users with role='user'
- Admin groups with unique codes
- Financial data (expenses, transfers, incoming transactions)

All tests use `RefreshDatabase` trait to ensure a clean database state for each test.

## Key Assertions

- **Group Code Uniqueness**: Validates 4-6 digit numeric codes are unique
- **Data Isolation**: Ensures admins only see their group's data
- **Authorization**: Verifies admins cannot access other groups
- **Single Group Membership**: Confirms users can only belong to one group
- **Organization Matching**: Tests case-insensitive organization name matching

## Dependencies

- Laravel Testing Framework
- RefreshDatabase trait
- User, AdminGroup, Expense, Transfer, Incoming models
- Factory classes for test data generation

## Notes

- All tests are independent and can run in any order
- Tests use Sanctum authentication for API requests
- Tests validate both success and failure scenarios
- Tests cover edge cases like code regeneration and member removal
