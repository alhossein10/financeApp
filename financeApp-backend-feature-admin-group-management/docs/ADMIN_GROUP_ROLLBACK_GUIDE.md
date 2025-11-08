# Admin Group Management - Rollback Guide

## Overview

This document provides comprehensive instructions for rolling back the Admin Group Management feature and reverting to the previous organization/department system. Use this guide if you need to undo the admin group implementation.

## Table of Contents

1. [Pre-Rollback Checklist](#pre-rollback-checklist)
2. [Data Backup](#data-backup)
3. [Rollback Steps](#rollback-steps)
4. [Post-Rollback Verification](#post-rollback-verification)
5. [Troubleshooting](#troubleshooting)

---

## Pre-Rollback Checklist

Before proceeding with the rollback, ensure you have:

- [ ] **Full database backup** - Critical for data recovery
- [ ] **Code repository backup** - Tag current version in Git
- [ ] **Documented reason for rollback** - For future reference
- [ ] **Maintenance window scheduled** - Notify users of downtime
- [ ] **Tested rollback in staging environment** - Verify process works
- [ ] **Admin approval** - Get stakeholder sign-off

### Important Warnings

⚠️ **Data Loss Warning**: Rolling back will result in the following data loss:
- All admin group assignments will be removed
- Group codes will be deleted
- Users will lose their group memberships
- Organization and department names will revert to foreign key references

⚠️ **Compatibility Warning**: After rollback:
- Mobile apps using the new API structure will break
- Any integrations expecting `organization_name` fields will fail
- Users must be reassigned to organizations/departments manually

---

## Data Backup

### 1. Backup Database

```bash
# Full database backup
php artisan db:backup

# Or using mysqldump
mysqldump -u [username] -p [database_name] > backup_before_rollback_$(date +%Y%m%d_%H%M%S).sql
```

### 2. Export Admin Group Data

Before rolling back, export admin group data for reference:

```sql
-- Export admin groups
SELECT * FROM admin_groups INTO OUTFILE '/tmp/admin_groups_backup.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Export user group assignments
SELECT id, name, email, organization_name, department_name, admin_group_id, role
FROM users
WHERE admin_group_id IS NOT NULL
INTO OUTFILE '/tmp/user_group_assignments_backup.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

### 3. Backup Code

```bash
# Create a Git tag for current state
git tag -a admin-group-v1.0 -m "Admin Group Management before rollback"
git push origin admin-group-v1.0

# Create a backup branch
git checkout -b backup/admin-group-implementation
git push origin backup/admin-group-implementation
git checkout main
```

---

## Rollback Steps

### Step 1: Put Application in Maintenance Mode

```bash
php artisan down --message="System maintenance in progress" --retry=60
```

### Step 2: Rollback Database Migrations

The migrations must be rolled back in reverse order:

```bash
# Check current migration status
php artisan migrate:status

# Rollback the admin group migrations
php artisan migrate:rollback --step=2

# This will rollback:
# 1. 2025_11_01_000002_add_group_and_text_org_fields_to_users_table
# 2. 2025_11_01_000001_create_admin_groups_table
```

**What happens during rollback:**

1. **Migration 2025_11_01_000002** (users table changes):
   - Drops `admin_group_id` foreign key constraint
   - Drops indexes on `organization_name` and `admin_group_id`
   - Removes columns: `organization_name`, `department_name`, `admin_group_id`
   - Note: `organization_id` and `department_id` remain nullable

2. **Migration 2025_11_01_000001** (admin_groups table):
   - Drops `admin_groups` table completely
   - All group codes and group data are permanently deleted

### Step 3: Restore Organization/Department Foreign Keys

After rollback, you need to restore the NOT NULL constraints on organization_id and department_id:

```bash
# Create a new migration to restore constraints
php artisan make:migration restore_organization_department_constraints
```

Edit the migration file:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Make organization_id and department_id NOT NULL again
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('organization_id')->nullable(false)->change();
            $table->unsignedBigInteger('department_id')->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('organization_id')->nullable()->change();
            $table->unsignedBigInteger('department_id')->nullable()->change();
        });
    }
};
```

**Important**: Before running this migration, ensure all users have valid `organization_id` and `department_id` values.

### Step 4: Revert Code Changes

Remove or revert the following files and changes:

#### Files to Delete:

```bash
# Models
rm app/Models/AdminGroup.php

# Services
rm app/Services/AdminGroupService.php

# Repositories
rm app/Repositories/AdminGroupRepository.php

# Controllers
rm app/Http/Controllers/AdminGroupController.php

# Tests
rm tests/Feature/AdminGroupManagementTest.php
rm tests/Feature/AdminGroupDataScopingTest.php
rm tests/Feature/AdminGroupTransferRestrictionsTest.php
rm tests/Feature/AdminGroupMultiAdminScenariosTest.php
rm tests/Unit/AdminGroupTest.php
rm tests/Unit/AdminGroupServiceTest.php

# Seeders
rm database/seeders/AdminGroupSeeder.php

# Documentation
rm docs/ADMIN_GROUP_MANAGEMENT.md
rm docs/ADMIN_GROUP_QUICK_REFERENCE.md
```

#### Files to Revert:

Use Git to revert these files to their pre-admin-group state:

```bash
# Revert User model
git checkout [commit-before-admin-group] app/Models/User.php

# Revert AuthService
git checkout [commit-before-admin-group] app/Services/AuthService.php

# Revert RegisterRequest
git checkout [commit-before-admin-group] app/Http/Requests/Auth/RegisterRequest.php

# Revert Repositories
git checkout [commit-before-admin-group] app/Repositories/ExpenseRepository.php
git checkout [commit-before-admin-group] app/Repositories/TransferRepository.php
git checkout [commit-before-admin-group] app/Repositories/IncomingRepository.php
git checkout [commit-before-admin-group] app/Repositories/FundBoxRepository.php

# Revert Services
git checkout [commit-before-admin-group] app/Services/ExpenseService.php
git checkout [commit-before-admin-group] app/Services/TransferService.php
git checkout [commit-before-admin-group] app/Services/IncomingService.php
git checkout [commit-before-admin-group] app/Services/FundBoxService.php

# Revert Controllers
git checkout [commit-before-admin-group] app/Http/Controllers/ExpenseController.php
git checkout [commit-before-admin-group] app/Http/Controllers/TransferController.php
git checkout [commit-before-admin-group] app/Http/Controllers/IncomingController.php
git checkout [commit-before-admin-group] app/Http/Controllers/FundBoxController.php

# Revert Routes
git checkout [commit-before-admin-group] routes/api_v1.php
```

### Step 5: Remove Admin Group Routes

Edit `routes/api_v1.php` and remove all admin group routes:

```php
// Remove these routes:
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
    Route::get('/group', [AdminGroupController::class, 'getAdminGroup']);
    Route::post('/group/regenerate', [AdminGroupController::class, 'regenerateGroupCode']);
    Route::get('/group/members', [AdminGroupController::class, 'getGroupMembers']);
    Route::delete('/group/members/{id}', [AdminGroupController::class, 'removeMember']);
});

Route::middleware(['auth:sanctum'])->prefix('user')->group(function () {
    Route::post('/join-group', [AdminGroupController::class, 'joinGroup']);
    Route::get('/group-info', [AdminGroupController::class, 'getGroupInfo']);
});
```

### Step 6: Update API Documentation

Remove admin group endpoints from OpenAPI documentation:

```bash
# Edit the OpenAPI schema file
# Remove all admin group endpoint definitions
```

### Step 7: Clear Application Cache

```bash
# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Regenerate optimized files
php artisan config:cache
php artisan route:cache
```

### Step 8: Bring Application Back Online

```bash
php artisan up
```

---

## Post-Rollback Verification

### 1. Database Verification

```sql
-- Verify admin_groups table is gone
SHOW TABLES LIKE 'admin_groups';
-- Should return empty result

-- Verify users table structure
DESCRIBE users;
-- Should NOT have: organization_name, department_name, admin_group_id
-- Should have: organization_id, department_id

-- Check for orphaned data
SELECT COUNT(*) FROM users WHERE organization_id IS NULL;
SELECT COUNT(*) FROM users WHERE department_id IS NULL;
-- Both should return 0 if constraints are restored
```

### 2. Application Verification

Test the following functionality:

- [ ] User registration works with organization/department dropdowns
- [ ] Admin login successful
- [ ] Regular user login successful
- [ ] Expense listing shows correct data
- [ ] Transfer creation works
- [ ] Data scoping works (users see only their data)
- [ ] Admin dashboard displays correctly

### 3. API Endpoint Testing

```bash
# Test registration endpoint
curl -X POST http://your-api.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "user",
    "organization_id": 1,
    "department_id": 1
  }'

# Should succeed without group_code field
```

### 4. Run Test Suite

```bash
# Run all tests
php artisan test

# Specifically test authentication and data scoping
php artisan test --filter=Auth
php artisan test --filter=Expense
php artisan test --filter=Transfer
```

---

## Troubleshooting

### Issue 1: Migration Rollback Fails

**Error**: Foreign key constraint fails during rollback

**Solution**:
```sql
-- Manually drop foreign keys
ALTER TABLE users DROP FOREIGN KEY users_admin_group_id_foreign;

-- Then retry rollback
php artisan migrate:rollback --step=2
```

### Issue 2: Users Have NULL organization_id

**Error**: Users cannot be assigned to organizations after rollback

**Solution**:
```sql
-- Manually assign users to default organization
UPDATE users 
SET organization_id = 1, department_id = 1 
WHERE organization_id IS NULL;

-- Then restore NOT NULL constraints
```

### Issue 3: API Returns 404 for Group Endpoints

**Error**: Old mobile apps still calling group endpoints

**Solution**:
- Deploy updated mobile app versions
- Add temporary redirect or error message for deprecated endpoints
- Communicate with users about required app update

### Issue 4: Data Loss After Rollback

**Error**: Cannot recover group assignments

**Solution**:
```sql
-- Restore from backup CSV files
LOAD DATA INFILE '/tmp/user_group_assignments_backup.csv'
INTO TABLE temp_group_assignments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- Manually reassign users based on backup data
-- This requires custom SQL based on your business logic
```

### Issue 5: Tests Failing After Rollback

**Error**: Tests reference AdminGroup classes

**Solution**:
```bash
# Search for remaining references
grep -r "AdminGroup" tests/
grep -r "admin_group" tests/

# Remove or update test files
# Ensure all admin group test files are deleted
```

---

## Alternative: Partial Rollback

If you want to keep some functionality, consider a partial rollback:

### Option A: Keep Text-Based Organization Fields

Keep `organization_name` and `department_name` but remove group functionality:

1. Only rollback the admin_groups table migration
2. Keep the users table changes
3. Remove AdminGroup model and related code
4. Update registration to use text fields without group codes

### Option B: Keep Groups, Remove Text Fields

Keep admin groups but revert to foreign key organizations:

1. Keep admin_groups table
2. Rollback users table changes for organization_name/department_name
3. Update AdminGroupService to use organization_id instead of organization_name

---

## Recovery Plan

If rollback causes critical issues:

### Emergency Recovery Steps

1. **Restore from backup**:
```bash
mysql -u [username] -p [database_name] < backup_before_rollback_[timestamp].sql
```

2. **Revert code changes**:
```bash
git checkout backup/admin-group-implementation
```

3. **Re-run migrations**:
```bash
php artisan migrate
```

4. **Clear caches and restart**:
```bash
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan up
```

---

## Support and Documentation

### Related Documentation

- [Admin Group Management Guide](./ADMIN_GROUP_MANAGEMENT.md)
- [API Documentation](../API_ENDPOINTS_REFERENCE.md)
- [Migration Guide](../MIGRATION_GUIDE.md)

### Contact Information

For assistance with rollback:
- Technical Lead: [contact info]
- Database Administrator: [contact info]
- DevOps Team: [contact info]

---

## Rollback Checklist Summary

Use this checklist when performing rollback:

- [ ] Create full database backup
- [ ] Export admin group data for reference
- [ ] Tag current code version in Git
- [ ] Put application in maintenance mode
- [ ] Rollback migrations (step=2)
- [ ] Restore organization/department constraints
- [ ] Delete admin group files
- [ ] Revert modified files using Git
- [ ] Remove admin group routes
- [ ] Update API documentation
- [ ] Clear application caches
- [ ] Bring application back online
- [ ] Verify database structure
- [ ] Test core functionality
- [ ] Run test suite
- [ ] Monitor for errors
- [ ] Document any issues encountered
- [ ] Notify stakeholders of completion

---

**Last Updated**: 2025-11-01
**Version**: 1.0
**Maintained By**: Development Team
