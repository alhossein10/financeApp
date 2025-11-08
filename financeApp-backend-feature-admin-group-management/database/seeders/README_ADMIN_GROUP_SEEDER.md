# Admin Group Seeder Documentation

## Overview

The `AdminGroupSeeder` creates comprehensive test data for the Admin Group Management feature. It sets up multiple admin users with their groups, regular users assigned to different groups, and financial data (expenses, transfers, incoming transactions) to test data isolation.

## What Gets Created

### Organization 1: TechCorp

#### Admin 1 - Engineering Team
- **Admin User**: Alice Johnson (alice.admin@techcorp.com)
- **Group Code**: 123456
- **Group Name**: TechCorp Engineering Team
- **Members**:
  - Bob Smith (bob.user@techcorp.com)
    - 10 expenses
    - 5 transfers
    - 6 incoming transactions
  - Carol Davis (carol.user@techcorp.com)
    - 8 expenses
    - 4 transfers
    - 5 incoming transactions

#### Admin 2 - Marketing Team
- **Admin User**: David Wilson (david.admin@techcorp.com)
- **Group Code**: 789012
- **Group Name**: TechCorp Marketing Team
- **Members**:
  - Emma Brown (emma.user@techcorp.com)
    - 12 expenses
    - 6 transfers
    - 7 incoming transactions
  - Frank Miller (frank.user@techcorp.com)
    - 9 expenses
    - 3 transfers
    - 4 incoming transactions

### Organization 2: GlobalFinance

#### Admin 3 - Operations Team
- **Admin User**: Grace Lee (grace.admin@globalfinance.com)
- **Group Code**: 345678
- **Group Name**: GlobalFinance Operations Team
- **Members**:
  - Henry Taylor (henry.user@globalfinance.com)
    - 15 expenses
    - 7 transfers
    - 8 incoming transactions
  - Iris Chen (iris.user@globalfinance.com)
    - 11 expenses
    - 5 transfers
    - 6 incoming transactions

### Unassigned Users

- **Jack Robinson** (jack.user@techcorp.com)
  - Organization: TechCorp
  - Department: Sales
  - **No group assignment** (for testing unassigned user scenarios)
  - 5 expenses
  - 2 transfers
  - 3 incoming transactions

## Usage

### Run All Seeders (Including Admin Group Seeder)

```bash
php artisan db:seed
```

This will run all seeders including the AdminGroupSeeder in non-production environments.

### Run Only Admin Group Seeder

```bash
php artisan db:seed --class=AdminGroupSeeder
```

### Fresh Migration with Seeding

```bash
php artisan migrate:fresh --seed
```

## Test Scenarios

The seeder data supports testing the following scenarios:

### 1. Multiple Admins in Same Organization (Requirements 9.1, 9.2)
- TechCorp has two admins (Alice and David) with separate groups
- Each admin manages different teams (Engineering vs Marketing)
- Tests that multiple admins can coexist in the same organization

### 2. Data Isolation Between Groups (Requirements 9.3, 9.4)
- Alice's group has Bob and Carol
- David's group has Emma and Frank
- Grace's group has Henry and Iris
- Each group has distinct financial data
- Tests that admins only see their group's data

### 3. Cross-Organization Isolation
- TechCorp admins should not see GlobalFinance data
- GlobalFinance admin should not see TechCorp data
- Tests organization-level data isolation

### 4. Unassigned User Scenario
- Jack is not assigned to any group
- Tests behavior of users without group membership
- Tests that unassigned users can only see their own data

### 5. Group Code Uniqueness
- Each admin has a unique group code
- Tests that group codes are unique across all admins

## Login Credentials

All users have the same password: **password123**

### Admin Accounts
- alice.admin@techcorp.com / password123
- david.admin@techcorp.com / password123
- grace.admin@globalfinance.com / password123

### Regular User Accounts
- bob.user@techcorp.com / password123
- carol.user@techcorp.com / password123
- emma.user@techcorp.com / password123
- frank.user@techcorp.com / password123
- henry.user@globalfinance.com / password123
- iris.user@globalfinance.com / password123
- jack.user@techcorp.com / password123

## Testing Data Isolation

### Test Admin 1 (Alice) Can Only See Her Group's Data

1. Login as alice.admin@techcorp.com
2. Get expenses - should see Bob's and Carol's expenses only (18 total)
3. Get transfers - should see Bob's and Carol's transfers only (9 total)
4. Get incoming - should see Bob's and Carol's incoming only (11 total)
5. Should NOT see Emma's, Frank's, Henry's, or Iris's data

### Test Admin 2 (David) Can Only See His Group's Data

1. Login as david.admin@techcorp.com
2. Get expenses - should see Emma's and Frank's expenses only (21 total)
3. Get transfers - should see Emma's and Frank's transfers only (9 total)
4. Get incoming - should see Emma's and Frank's incoming only (11 total)
5. Should NOT see Bob's, Carol's, Henry's, or Iris's data

### Test Admin 3 (Grace) Can Only See Her Group's Data

1. Login as grace.admin@globalfinance.com
2. Get expenses - should see Henry's and Iris's expenses only (26 total)
3. Get transfers - should see Henry's and Iris's transfers only (12 total)
4. Get incoming - should see Henry's and Iris's incoming only (14 total)
5. Should NOT see any TechCorp users' data

### Test Regular User Can Only See Own Data

1. Login as bob.user@techcorp.com
2. Get expenses - should see only Bob's expenses (10 total)
3. Get transfers - should see only Bob's transfers (5 total)
4. Get incoming - should see only Bob's incoming (6 total)
5. Should NOT see Carol's, Emma's, or any other user's data

### Test Unassigned User

1. Login as jack.user@techcorp.com
2. Get expenses - should see only Jack's expenses (5 total)
3. Get transfers - should see only Jack's transfers (2 total)
4. Get incoming - should see only Jack's incoming (3 total)
5. Should NOT be able to join a group without a valid group code

## Group Management Testing

### Test Group Member Management

1. Login as alice.admin@techcorp.com
2. GET /api/admin/group - should return group info with code 123456
3. GET /api/admin/group/members - should return Bob and Carol
4. DELETE /api/admin/group/members/{bob_id} - should remove Bob from group
5. GET /api/admin/group/members - should now return only Carol

### Test Group Code Regeneration

1. Login as alice.admin@techcorp.com
2. GET /api/admin/group - note the current group code (123456)
3. POST /api/admin/group/regenerate - should return new unique code
4. GET /api/admin/group - should show the new code

### Test User Joining Group

1. Create a new user without group assignment
2. POST /api/user/join-group with group_code=123456
3. Verify user is now part of Alice's group
4. Verify user's organization matches Alice's organization

## Cleanup

To remove all seeded data and start fresh:

```bash
php artisan migrate:fresh
```

To reseed after cleanup:

```bash
php artisan db:seed
```

## Notes

- The seeder uses Laravel factories for generating financial data (expenses, transfers, incoming)
- All timestamps are set to the current time when seeding
- Group codes are hardcoded for predictable testing (123456, 789012, 345678)
- In production, group codes would be randomly generated
- The seeder only runs in non-production environments (controlled by DatabaseSeeder)
