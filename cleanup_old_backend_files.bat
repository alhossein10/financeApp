@echo off
REM Cleanup script for old backend files (PocketBase, Supabase, SQLite)
REM Run this to remove obsolete documentation and test files

echo ========================================
echo Cleaning up old backend files...
echo ========================================
echo.

REM Create backup directory
if not exist "backup_old_files" mkdir backup_old_files
echo Created backup directory: backup_old_files
echo.

REM Backup and delete PocketBase files
echo [1/4] Removing PocketBase files...
if exist "pocketbase-backend-files" (
    xcopy /E /I /Y "pocketbase-backend-files" "backup_old_files\pocketbase-backend-files" >nul
    rmdir /S /Q "pocketbase-backend-files"
    echo   - Removed pocketbase-backend-files/
)

REM Backup and delete PocketBase documentation
for %%f in (
    POCKETBASE_README.md
    POCKETBASE_COMPLETE_SETUP_GUIDE.md
    POCKETBASE_SETUP_CHECKLIST.md
    POCKETBASE_FRESH_START.md
    TASK_1_POCKETBASE_SETUP_SUMMARY.md
    RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md
    RENDER_DEPLOYMENT_FIX.md
    FIX_GITHUB_REPO.md
    MANUAL_COLLECTION_SETUP.md
    SETUP_LOCAL_POCKETBASE_SERVER.md
) do (
    if exist "%%f" (
        copy "%%f" "backup_old_files\" >nul
        del "%%f"
        echo   - Removed %%f
    )
)

REM Backup and delete Supabase files
echo.
echo [2/4] Removing Supabase files...
for %%f in (
    SUPABASE_README.md
    SUPABASE_MIGRATION_GUIDE.md
    SUPABASE_QUICK_SETUP.md
    SUPABASE_PROGRESS_STATUS.md
    SUPABASE_DEVELOPMENT_ROADMAP.md
    SUPABASE_INTEGRATION_PHASE3.md
    SUPABASE_INTEGRATION_TEST.md
    SUPABASE_PHASE_4_PRODUCTION_READY.md
    SUPABASE_RLS_OPTIMIZATION.md
    SUPABASE_RLS_POLICY_FIX.md
    SUPABASE_RATE_LIMIT_ERROR.md
    SUPABASE_PROJECT_NOT_FOUND.md
    SUPABASE_FIX_CHECKLIST.md
    SUPABASE_SYNC_FLOW.md
    SUPABASE_SYNC_FIX.md
    SUPABASE_SYNC_QUICK_FIX.md
    START_HERE_SUPABASE_FIX.md
    CHECK_SUPABASE_PROJECT.md
    QUICK_FIX_REGISTRATION_ERROR.md
    REGISTRATION_NETWORK_ERROR_FIX.md
) do (
    if exist "%%f" (
        copy "%%f" "backup_old_files\" >nul
        del "%%f"
        echo   - Removed %%f
    )
)

REM Backup and delete old sync/deployment files
echo.
echo [3/4] Removing old sync and deployment files...
for %%f in (
    SYNC_TROUBLESHOOTING_GUIDE.md
    WHY_SYNC_DOESNT_WORK.md
    CRITICAL_SYNC_AND_LOGOUT_FIXES.md
    FLYIO_QUICK_DEPLOY.md
    GITHUB_UPLOAD_GUIDE.md
    GITHUB_UPLOAD_CHECKLIST.md
    GITHUB_QUICK_START.md
    START_HERE_GITHUB.md
    VISUAL_SYNC_GUIDE.md
    IMMEDIATE_ACTION_REQUIRED.md
) do (
    if exist "%%f" (
        copy "%%f" "backup_old_files\" >nul
        del "%%f"
        echo   - Removed %%f
    )
)

REM Backup and delete old test files
echo.
echo [4/4] Removing obsolete test files...
for %%f in (
    test\core\services\cloud_sync_service_test.dart
    test\core\services\pocketbase_storage_service_test.dart
    test\integration\sync_flow_integration_test.dart
) do (
    if exist "%%f" (
        copy "%%f" "backup_old_files\" >nul
        del "%%f"
        echo   - Removed %%f
    )
)

REM Delete Firebase files (not used with Laravel)
if exist "firebase" (
    xcopy /E /I /Y "firebase" "backup_old_files\firebase" >nul
    rmdir /S /Q "firebase"
    echo   - Removed firebase/
)

for %%f in (
    FIREBASE_SETUP_GUIDE.md
    FIREBASE_SETUP_CHECKLIST.md
    FIREBASE_FREE_TIER_APPROACH.md
    TASK_1_FIREBASE_SETUP_SUMMARY.md
) do (
    if exist "%%f" (
        copy "%%f" "backup_old_files\" >nul
        del "%%f"
        echo   - Removed %%f
    )
)

echo.
echo ========================================
echo Cleanup complete!
echo ========================================
echo.
echo All removed files have been backed up to: backup_old_files\
echo.
echo If you need to restore any files, copy them from the backup directory.
echo To permanently delete the backup, run: rmdir /S /Q backup_old_files
echo.
echo Next steps:
echo 1. Review LARAVEL_BACKEND_CLEANUP.md for details
echo 2. Read LARAVEL_QUICK_START.md to get started
echo 3. Start your Laravel backend: cd financeApp-backend-main ^&^& php artisan serve
echo 4. Run your Flutter app: flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
echo.
pause
