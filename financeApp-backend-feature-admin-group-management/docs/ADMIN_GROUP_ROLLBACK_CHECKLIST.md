# Admin Group Rollback - Quick Checklist

Use this checklist when performing a rollback of the Admin Group Management feature.

## Pre-Rollback (Do NOT skip these!)

- [ ] **Read full rollback guide**: `docs/ADMIN_GROUP_ROLLBACK_GUIDE.md`
- [ ] **Test in staging environment first**
- [ ] **Schedule maintenance window** (estimated: 30-60 minutes)
- [ ] **Notify all users** about downtime
- [ ] **Get stakeholder approval** for rollback
- [ ] **Document reason** for rollback

## Backup Phase

- [ ] **Create full database backup**
  ```bash
  php artisan db:backup
  # OR
  mysqldump -u [user] -p [database] > backup_$(date +%Y%m%d_%H%M%S).sql
  ```

- [ ] **Export admin group data**
  ```sql
  SELECT * FROM admin_groups INTO OUTFILE '/tmp/admin_groups_backup.csv';
  SELECT id, name, email, organization_name, department_name, admin_group_id 
  FROM users WHERE admin_group_id IS NOT NULL 
  INTO OUTFILE '/tmp/user_assignments_backup.csv';
  ```

- [ ] **Create Git tag**
  ```bash
  git tag -a admin-group-rollback-point -m "Before rollback"
  git push origin admin-group-rollback-point
  ```

- [ ] **Verify backups are accessible and complete**

## Rollback Execution

- [ ] **Put application in maintenance mode**
  ```bash
  php artisan down --message="System maintenance" --retry=60
  ```

- [ ] **Check current migration status**
  ```bash
  php artisan migrate:status
  ```

- [ ] **Rollback migrations (2 steps)**
  ```bash
  php artisan migrate:rollback --step=2
  ```

- [ ] **Verify migrations rolled back**
  ```bash
  php artisan migrate:status
  ```

## Code Cleanup

- [ ] **Delete admin group files**
  - [ ] `app/Models/AdminGroup.php`
  - [ ] `app/Services/AdminGroupService.php`
  - [ ] `app/Repositories/AdminGroupRepository.php`
  - [ ] `app/Http/Controllers/AdminGroupController.php`
  - [ ] `database/seeders/AdminGroupSeeder.php`
  - [ ] All admin group test files

- [ ] **Revert modified files** (use Git)
  - [ ] `app/Models/User.php`
  - [ ] `app/Services/AuthService.php`
  - [ ] `app/Http/Requests/Auth/RegisterRequest.php`
  - [ ] All repository files (Expense, Transfer, Incoming, FundBox)
  - [ ] All service files
  - [ ] All controller files

- [ ] **Remove admin group routes** from `routes/api_v1.php`

- [ ] **Update API documentation** (remove admin group endpoints)

## Cache and Optimization

- [ ] **Clear all caches**
  ```bash
  php artisan cache:clear
  php artisan config:clear
  php artisan route:clear
  php artisan view:clear
  ```

- [ ] **Regenerate optimized files**
  ```bash
  php artisan config:cache
  php artisan route:cache
  ```

## Bring Back Online

- [ ] **Disable maintenance mode**
  ```bash
  php artisan up
  ```

## Post-Rollback Verification

### Database Verification

- [ ] **Verify admin_groups table is gone**
  ```sql
  SHOW TABLES LIKE 'admin_groups';
  -- Should return empty
  ```

- [ ] **Verify users table structure**
  ```sql
  DESCRIBE users;
  -- Should NOT have: organization_name, department_name, admin_group_id
  ```

- [ ] **Check for NULL organization/department values**
  ```sql
  SELECT COUNT(*) FROM users WHERE organization_id IS NULL;
  SELECT COUNT(*) FROM users WHERE department_id IS NULL;
  ```

- [ ] **If NULLs found, assign default values before restoring constraints**

### Application Testing

- [ ] **Test user registration** (with organization/department dropdowns)
- [ ] **Test admin login**
- [ ] **Test regular user login**
- [ ] **Test expense listing** (verify data scoping)
- [ ] **Test transfer creation**
- [ ] **Test incoming transactions**
- [ ] **Test fund box operations**
- [ ] **Test admin dashboard**

### API Testing

- [ ] **Test registration endpoint**
  ```bash
  curl -X POST http://api.local/api/v1/auth/register \
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
  ```

- [ ] **Verify group endpoints return 404**
  ```bash
  curl -X GET http://api.local/api/v1/admin/group
  # Should return 404
  ```

### Test Suite

- [ ] **Run full test suite**
  ```bash
  php artisan test
  ```

- [ ] **Run specific test categories**
  ```bash
  php artisan test --filter=Auth
  php artisan test --filter=Expense
  php artisan test --filter=Transfer
  ```

- [ ] **All tests passing** (no admin group references)

## Optional: Restore Constraints

If all users have valid organization_id and department_id:

- [ ] **Rename constraint restoration migration**
  ```bash
  cp database/migrations/ROLLBACK_restore_organization_department_constraints.php.example \
     database/migrations/$(date +%Y_%m_%d_%H%M%S)_restore_organization_department_constraints.php
  ```

- [ ] **Run constraint restoration**
  ```bash
  php artisan migrate
  ```

- [ ] **Verify constraints applied**
  ```sql
  DESCRIBE users;
  -- organization_id and department_id should be NOT NULL
  ```

## Documentation and Communication

- [ ] **Update internal documentation** (remove admin group references)
- [ ] **Notify development team** of rollback completion
- [ ] **Notify users** that system is back online
- [ ] **Document any issues encountered** during rollback
- [ ] **Update mobile app** (if needed to remove group features)
- [ ] **Schedule post-mortem** to discuss rollback reasons

## Monitoring (First 24 Hours)

- [ ] **Monitor error logs** for any issues
  ```bash
  tail -f storage/logs/laravel.log
  ```

- [ ] **Monitor database performance**
- [ ] **Check for user-reported issues**
- [ ] **Verify data integrity** (spot checks)
- [ ] **Monitor API response times**

## Rollback Success Criteria

All of the following must be true:

- [ ] ✅ Application is online and accessible
- [ ] ✅ No admin_groups table exists
- [ ] ✅ No admin group fields in users table
- [ ] ✅ All tests passing
- [ ] ✅ User registration works with organization/department
- [ ] ✅ Data scoping works correctly
- [ ] ✅ No errors in logs
- [ ] ✅ Users can perform all core functions

## Emergency Recovery

If rollback fails critically:

- [ ] **Restore from database backup**
  ```bash
  mysql -u [user] -p [database] < backup_[timestamp].sql
  ```

- [ ] **Revert code to backup branch**
  ```bash
  git checkout backup/admin-group-implementation
  ```

- [ ] **Re-run migrations**
  ```bash
  php artisan migrate
  ```

- [ ] **Clear caches and restart**

- [ ] **Contact technical lead immediately**

## Sign-Off

- [ ] **Technical Lead Approval**: _________________ Date: _______
- [ ] **Database Admin Approval**: _________________ Date: _______
- [ ] **Product Owner Approval**: _________________ Date: _______

---

**Rollback Completed By**: _______________________

**Date**: _______________________

**Time**: _______________________

**Duration**: _______ minutes

**Issues Encountered**: 

_________________________________________________________________

_________________________________________________________________

**Notes**:

_________________________________________________________________

_________________________________________________________________
