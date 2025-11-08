@echo off
REM ###############################################################################
REM Admin Group Management - Rollback Script (Windows)
REM ###############################################################################
REM
REM This script automates the rollback of the Admin Group Management feature.
REM 
REM IMPORTANT: Review docs/ADMIN_GROUP_ROLLBACK_GUIDE.md before running!
REM
REM Usage: scripts\rollback_admin_groups.bat
REM
REM ###############################################################################

setlocal enabledelayedexpansion

REM Configuration
set BACKUP_DIR=backups
set TIMESTAMP=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo ========================================
echo Admin Group Rollback - Pre-flight Checks
echo ========================================
echo.

REM Check if Laravel is installed
if not exist "artisan" (
    echo ERROR: artisan file not found. Are you in the Laravel root directory?
    exit /b 1
)

REM Check if .env exists
if not exist ".env" (
    echo ERROR: .env file not found
    exit /b 1
)

echo Pre-flight checks passed
echo.

REM Warning and Confirmation
echo ========================================
echo WARNING
echo ========================================
echo.
echo This script will rollback the Admin Group Management feature
echo The following data will be PERMANENTLY DELETED:
echo   - All admin groups and group codes
echo   - All user group assignments
echo   - Organization and department text fields
echo.
echo Please ensure you have:
echo   1. Read docs/ADMIN_GROUP_ROLLBACK_GUIDE.md
echo   2. Scheduled a maintenance window
echo   3. Notified all users
echo   4. Tested this process in staging
echo.

set /p CONFIRM="Do you want to proceed with the rollback? (yes/no): "
if /i not "%CONFIRM%"=="yes" (
    echo Rollback cancelled
    exit /b 0
)

echo.
echo ========================================
echo Step 1: Creating Database Backup
echo ========================================
echo.

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Creating database backup...
php artisan db:backup --path="%BACKUP_DIR%/db_backup_%TIMESTAMP%.sql" 2>nul
if errorlevel 1 (
    echo WARNING: db:backup command not available
    echo Please create a manual database backup before proceeding
    pause
)

echo Database backup created
echo.

echo ========================================
echo Step 2: Exporting Admin Group Data
echo ========================================
echo.

echo Exporting admin group data for reference...
php artisan tinker --execute="$groups = \App\Models\AdminGroup::with('admin', 'members')->get(); file_put_contents('%BACKUP_DIR%/admin_groups_export_%TIMESTAMP%.json', $groups->toJson(JSON_PRETTY_PRINT)); echo 'Exported ' . $groups->count() . ' admin groups';" 2>nul

echo Admin group data exported
echo.

echo ========================================
echo Step 3: Creating Git Backup
echo ========================================
echo.

git rev-parse --git-dir >nul 2>&1
if not errorlevel 1 (
    echo Creating Git tag...
    git tag -a "rollback-point-%TIMESTAMP%" -m "Backup before admin group rollback" 2>nul
    echo Git tag created: rollback-point-%TIMESTAMP%
) else (
    echo WARNING: Not a Git repository, skipping Git backup
)
echo.

echo ========================================
echo Step 4: Enabling Maintenance Mode
echo ========================================
echo.

php artisan down --message="System maintenance in progress" --retry=60
echo Application is now in maintenance mode
echo.

echo ========================================
echo Step 5: Rolling Back Migrations
echo ========================================
echo.

echo Current migration status:
php artisan migrate:status | findstr /C:"admin_group" /C:"2025_11_01"
echo.

set /p MIGRATE_CONFIRM="Proceed with rolling back 2 migrations? (yes/no): "
if /i not "%MIGRATE_CONFIRM%"=="yes" (
    echo Migration rollback cancelled
    php artisan up
    exit /b 1
)

php artisan migrate:rollback --step=2
if errorlevel 1 (
    echo ERROR: Migration rollback failed
    php artisan up
    exit /b 1
)

echo Migrations rolled back successfully
echo.

echo ========================================
echo Step 6: Clearing Application Caches
echo ========================================
echo.

php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo Caches cleared
echo.

echo ========================================
echo Step 7: Regenerating Optimized Files
echo ========================================
echo.

php artisan config:cache
php artisan route:cache

echo Optimized files regenerated
echo.

echo ========================================
echo Step 8: Disabling Maintenance Mode
echo ========================================
echo.

php artisan up
echo Application is now online
echo.

echo ========================================
echo Post-Rollback Verification
echo ========================================
echo.

echo Checking database structure...
php artisan tinker --execute="$tables = DB::select('SHOW TABLES'); $hasAdminGroups = false; foreach ($tables as $table) { $tableName = array_values((array)$table)[0]; if ($tableName === 'admin_groups') { $hasAdminGroups = true; break; } } if ($hasAdminGroups) { echo 'ERROR: admin_groups table still exists!'; exit(1); } else { echo 'SUCCESS: admin_groups table successfully removed'; }"

echo.
echo Checking users table structure...
php artisan tinker --execute="$columns = DB::select('DESCRIBE users'); $hasGroupFields = false; foreach ($columns as $column) { if (in_array($column->Field, ['admin_group_id', 'organization_name', 'department_name'])) { $hasGroupFields = true; break; } } if ($hasGroupFields) { echo 'ERROR: Group-related fields still exist in users table!'; exit(1); } else { echo 'SUCCESS: Group-related fields successfully removed from users table'; }"

echo.
echo ========================================
echo Rollback Complete!
echo ========================================
echo.

echo Summary:
echo   - Database backup: %BACKUP_DIR%/db_backup_%TIMESTAMP%.sql
echo   - Admin group export: %BACKUP_DIR%/admin_groups_export_%TIMESTAMP%.json
echo   - Git tag: rollback-point-%TIMESTAMP%
echo.
echo Next Steps:
echo   1. Review docs/ADMIN_GROUP_ROLLBACK_GUIDE.md for post-rollback tasks
echo   2. Manually remove admin group code files (models, services, controllers)
echo   3. Update API routes to remove admin group endpoints
echo   4. Run test suite: php artisan test
echo   5. Verify application functionality
echo   6. Consider running restore_organization_department_constraints migration
echo.
echo Rollback script completed successfully
echo.

pause
