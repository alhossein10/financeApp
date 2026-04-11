@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Finance App - Build Testing Script
echo Task 28.3: Test Builds
echo ========================================
echo.

REM Create test_builds directory if it doesn't exist
if not exist "test_builds" mkdir test_builds

REM Clean old test builds
echo Cleaning old test builds...
if exist "test_builds\*.apk" del /q "test_builds\*.apk"
echo.

echo Cleaning Flutter build cache...
call flutter clean
echo.

echo Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo.

REM Test SuperAdmin flavor build
echo ========================================
echo TEST 1: Building SuperAdmin Flavor
echo ========================================
echo.
echo Application ID: com.app.finance.superadmin
echo Entry Point: lib/main_superadmin.dart
echo.

call flutter build apk --release --flavor superAdmin -t lib/main_superadmin.dart
if errorlevel 1 (
    echo [FAIL] SuperAdmin APK build failed
    set SUPERADMIN_BUILD=FAIL
) else (
    if exist "build\app\outputs\flutter-apk\app-superAdmin-release.apk" (
        copy "build\app\outputs\flutter-apk\app-superAdmin-release.apk" "test_builds\finance-superadmin-test.apk"
        echo [PASS] SuperAdmin APK created successfully
        set SUPERADMIN_BUILD=PASS
    ) else (
        echo [FAIL] SuperAdmin APK not found
        set SUPERADMIN_BUILD=FAIL
    )
)
echo.

REM Test Admin flavor build
echo ========================================
echo TEST 2: Building Admin Flavor
echo ========================================
echo.
echo Application ID: com.app.finance.admin
echo Entry Point: lib/main_admin.dart
echo.

call flutter build apk --release --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo [FAIL] Admin APK build failed
    set ADMIN_BUILD=FAIL
) else (
    if exist "build\app\outputs\flutter-apk\app-admin-release.apk" (
        copy "build\app\outputs\flutter-apk\app-admin-release.apk" "test_builds\finance-admin-test.apk"
        echo [PASS] Admin APK created successfully
        set ADMIN_BUILD=PASS
    ) else (
        echo [FAIL] Admin APK not found
        set ADMIN_BUILD=FAIL
    )
)
echo.

REM Test User flavor build
echo ========================================
echo TEST 3: Building User Flavor
echo ========================================
echo.
echo Application ID: com.app.finance.user
echo Entry Point: lib/main_user.dart
echo.

call flutter build apk --release --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo [FAIL] User APK build failed
    set USER_BUILD=FAIL
) else (
    if exist "build\app\outputs\flutter-apk\app-user-release.apk" (
        copy "build\app\outputs\flutter-apk\app-user-release.apk" "test_builds\finance-user-test.apk"
        echo [PASS] User APK created successfully
        set USER_BUILD=PASS
    ) else (
        echo [FAIL] User APK not found
        set USER_BUILD=FAIL
    )
)
echo.

REM Test Summary
echo ========================================
echo Build Test Summary
echo ========================================
echo.
echo SuperAdmin Build: %SUPERADMIN_BUILD%
echo Admin Build:      %ADMIN_BUILD%
echo User Build:       %USER_BUILD%
echo.

if exist "test_builds\finance-superadmin-test.apk" (
    echo [OK] test_builds\finance-superadmin-test.apk
) else (
    echo [MISSING] test_builds\finance-superadmin-test.apk
)

if exist "test_builds\finance-admin-test.apk" (
    echo [OK] test_builds\finance-admin-test.apk
) else (
    echo [MISSING] test_builds\finance-admin-test.apk
)

if exist "test_builds\finance-user-test.apk" (
    echo [OK] test_builds\finance-user-test.apk
) else (
    echo [MISSING] test_builds\finance-user-test.apk
)
echo.

REM Check if all builds passed
if "%SUPERADMIN_BUILD%"=="PASS" if "%ADMIN_BUILD%"=="PASS" if "%USER_BUILD%"=="PASS" (
    echo ========================================
    echo ALL BUILDS PASSED!
    echo ========================================
    echo.
    echo Next Steps:
    echo 1. Install APKs on Android device to verify separate app identifiers
    echo 2. Verify each flavor shows correct app name
    echo 3. Verify each flavor has correct navigation structure
    echo 4. Verify flavors can be installed simultaneously
    echo.
) else (
    echo ========================================
    echo SOME BUILDS FAILED!
    echo ========================================
    echo.
    echo Please check the error messages above and fix any issues.
    echo.
)

pause
