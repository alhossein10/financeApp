# Admin Group Management - Rollback Documentation

This directory contains comprehensive documentation and tools for rolling back the Admin Group Management feature.

## 📚 Documentation Files

### 1. [ADMIN_GROUP_ROLLBACK_GUIDE.md](./ADMIN_GROUP_ROLLBACK_GUIDE.md)
**Primary rollback documentation** - Complete guide with detailed instructions, troubleshooting, and recovery procedures.

**Use this when:**
- Planning a rollback
- Understanding the rollback process
- Troubleshooting rollback issues
- Need detailed explanations

**Contents:**
- Pre-rollback checklist
- Step-by-step rollback instructions
- Database verification procedures
- Troubleshooting common issues
- Emergency recovery procedures

### 2. [ADMIN_GROUP_ROLLBACK_CHECKLIST.md](./ADMIN_GROUP_ROLLBACK_CHECKLIST.md)
**Quick reference checklist** - Printable checklist for executing the rollback.

**Use this when:**
- Performing the actual rollback
- Need a quick reference during execution
- Want to track progress
- Need sign-off documentation

**Contents:**
- Pre-rollback tasks
- Execution steps
- Verification procedures
- Success criteria
- Sign-off section

## 🛠️ Rollback Tools

### 1. Automated Rollback Scripts

#### Linux/Mac: `scripts/rollback_admin_groups.sh`
```bash
# Make executable
chmod +x scripts/rollback_admin_groups.sh

# Run with backup
./scripts/rollback_admin_groups.sh

# Run without backup (NOT RECOMMENDED)
./scripts/rollback_admin_groups.sh --skip-backup

# Run without prompts
./scripts/rollback_admin_groups.sh --force
```

#### Windows: `scripts/rollback_admin_groups.bat`
```cmd
# Run from project root
scripts\rollback_admin_groups.bat
```

**What the scripts do:**
1. ✅ Create database backup
2. ✅ Export admin group data
3. ✅ Create Git tag
4. ✅ Enable maintenance mode
5. ✅ Rollback migrations
6. ✅ Clear caches
7. ✅ Disable maintenance mode
8. ✅ Verify rollback success

### 2. Helper Migration

**File**: `database/migrations/ROLLBACK_restore_organization_department_constraints.php.example`

**Purpose**: Restore NOT NULL constraints on organization_id and department_id after rollback.

**Usage**:
```bash
# 1. Ensure all users have valid organization/department IDs
# 2. Rename the file
cp database/migrations/ROLLBACK_restore_organization_department_constraints.php.example \
   database/migrations/$(date +%Y_%m_%d_%H%M%S)_restore_organization_department_constraints.php

# 3. Run migration
php artisan migrate
```

## 🚀 Quick Start

### For First-Time Rollback

1. **Read the full guide first**
   ```bash
   cat docs/ADMIN_GROUP_ROLLBACK_GUIDE.md
   ```

2. **Test in staging environment**
   - Never perform rollback in production first
   - Document any issues encountered

3. **Use the checklist**
   ```bash
   # Print or open in editor
   cat docs/ADMIN_GROUP_ROLLBACK_CHECKLIST.md
   ```

4. **Run the automated script**
   ```bash
   ./scripts/rollback_admin_groups.sh
   ```

5. **Perform manual cleanup**
   - Remove admin group code files
   - Update routes
   - Update documentation

6. **Verify and test**
   - Run test suite
   - Test core functionality
   - Monitor for issues

### For Emergency Rollback

If you need to rollback immediately due to critical issues:

1. **Create backup** (CRITICAL - don't skip!)
   ```bash
   php artisan db:backup
   ```

2. **Run automated script with force flag**
   ```bash
   ./scripts/rollback_admin_groups.sh --force
   ```

3. **Verify application is functional**
   ```bash
   php artisan test
   ```

4. **Monitor logs**
   ```bash
   tail -f storage/logs/laravel.log
   ```

## 📋 Rollback Process Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    ROLLBACK PROCESS                          │
└─────────────────────────────────────────────────────────────┘

1. PRE-ROLLBACK
   ├── Read documentation
   ├── Test in staging
   ├── Schedule maintenance
   └── Get approvals

2. BACKUP
   ├── Database backup
   ├── Export admin group data
   └── Create Git tag

3. EXECUTE ROLLBACK
   ├── Enable maintenance mode
   ├── Rollback migrations (2 steps)
   ├── Clear caches
   └── Disable maintenance mode

4. CODE CLEANUP
   ├── Delete admin group files
   ├── Revert modified files
   └── Update routes

5. VERIFICATION
   ├── Database structure check
   ├── Application testing
   ├── API testing
   └── Run test suite

6. POST-ROLLBACK
   ├── Monitor for issues
   ├── Update documentation
   └── Notify stakeholders
```

## ⚠️ Important Warnings

### Data Loss

Rolling back will **permanently delete**:
- ❌ All admin groups and group codes
- ❌ All user group assignments
- ❌ Organization and department text fields
- ❌ Any data dependent on admin groups

### Breaking Changes

After rollback:
- ❌ Mobile apps using new API will break
- ❌ Integrations expecting `organization_name` will fail
- ❌ Users must be reassigned to organizations manually

### Cannot Be Undone

Once rollback is complete and data is deleted:
- ❌ Cannot restore group assignments without backup
- ❌ Cannot recover group codes
- ❌ Must re-implement feature from scratch to restore

## 🆘 Emergency Contacts

If rollback fails or causes critical issues:

1. **Stop immediately** - Don't make it worse
2. **Restore from backup** - See emergency recovery section
3. **Contact technical lead** - Get help immediately
4. **Document everything** - For post-mortem analysis

## 📊 Rollback Checklist Summary

- [ ] Read full documentation
- [ ] Test in staging
- [ ] Create backups
- [ ] Run rollback script
- [ ] Perform manual cleanup
- [ ] Verify database structure
- [ ] Test application
- [ ] Run test suite
- [ ] Monitor for issues
- [ ] Update documentation
- [ ] Notify stakeholders

## 🔍 Verification Commands

### Check Database Structure
```sql
-- Verify admin_groups table is gone
SHOW TABLES LIKE 'admin_groups';

-- Verify users table structure
DESCRIBE users;

-- Check for NULL values
SELECT COUNT(*) FROM users WHERE organization_id IS NULL;
```

### Test Application
```bash
# Run test suite
php artisan test

# Test specific features
php artisan test --filter=Auth
php artisan test --filter=Expense
```

### Monitor Logs
```bash
# Watch Laravel logs
tail -f storage/logs/laravel.log

# Check for errors
grep ERROR storage/logs/laravel.log
```

## 📝 Post-Rollback Tasks

After successful rollback:

1. **Update documentation**
   - Remove admin group references
   - Update API documentation
   - Update user guides

2. **Notify stakeholders**
   - Development team
   - Product owners
   - End users

3. **Monitor application**
   - Watch error logs
   - Check performance metrics
   - Verify data integrity

4. **Schedule post-mortem**
   - Discuss rollback reasons
   - Document lessons learned
   - Plan improvements

## 🔗 Related Documentation

- [Admin Group Management Guide](./ADMIN_GROUP_MANAGEMENT.md)
- [Admin Group Quick Reference](./ADMIN_GROUP_QUICK_REFERENCE.md)
- [API Documentation](../API_ENDPOINTS_REFERENCE.md)
- [Setup Guide](../SETUP_GUIDE.md)

## 📞 Support

For questions or issues with rollback:
- Review troubleshooting section in main guide
- Check emergency recovery procedures
- Contact technical lead
- Document issues for future reference

---

**Last Updated**: 2025-11-01  
**Version**: 1.0  
**Maintained By**: Development Team
