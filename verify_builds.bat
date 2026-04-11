@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Build Verification Script
echo Task 28.3: Verify Build Outputs
echo ========================================
echo.

set PASS_COUNT=0
set FAIL_COUNT=0

REM Check if test_builds directory exists
if not exist "test_builds" (
    echo [ERROR] test_builds directory not found
    echo Please run test_builds.bat first
    pause
    exit /b 1
)

echo Checking build outputs...
echo.

REM Check SuperAdmin APK
echo [1/3] Verifying SuperAdmin APK...
if exist "test_builds\finance-superadmin-test.apk" (
    echo [PASS] SuperAdmin APK exists
    set /a PASS_COUNT+=1
    
    REM Get file size
    for %%A in ("test_builds\finance-superadmin-test.apk") do (
        set SIZE=%%~zA
        set /a SIZE_MB=!SIZE! / 1048576
        echo       Size: !SIZE_MB! MB
    )
) else (
    echo [FAIL] SuperAdmin APK not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check Admin APK
echo [2/3] Verifying Admin APK...
if exist "test_builds\finance-admin-test.apk" (
    echo [PASS] Admin APK exists
    set /a PASS_COUNT+=1
    
    REM Get file size
    for %%A in ("test_builds\finance-admin-test.apk") do (
        set SIZE=%%~zA
        set /a SIZE_MB=!SIZE! / 1048576
        echo       Size: !SIZE_MB! MB
    )
) else (
    echo [FAIL] Admin APK not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check User APK
echo [3/3] Verifying User APK...
if exist "test_builds\finance-user-test.apk" (
    echo [PASS] User APK exists
    set /a PASS_COUNT+=1
    
    REM Get file size
    for %%A in ("test_builds\finance-user-test.apk") do (
        set SIZE=%%~zA
        set /a SIZE_MB=!SIZE! / 1048576
        echo       Size: !SIZE_MB! MB
    )
) else (
    echo [FAIL] User APK not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check if ADB is available
echo Checking for ADB...
where adb >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] ADB is available
    echo.
    
    echo Checking for connected devices...
    adb devices | findstr "device$" >nul
    if %errorlevel% equ 0 (
        echo [OK] Android device connected
        echo.
        
        echo Checking installed Finance apps...
        adb shell pm list packages | findstr "finance" >nul
        if %errorlevel% equ 0 (
            echo.
            echo Installed Finance apps:
            adb shell pm list packages | findstr "finance"
            echo.
        ) else (
            echo [INFO] No Finance apps currently installed
            echo.
        )
        
        echo To install the test builds, run:
        echo   adb install test_builds\finance-superadmin-test.apk
        echo   adb install test_builds\finance-admin-test.apk
        echo   adb install test_builds\finance-user-test.apk
        echo.
    ) else (
        echo [INFO] No Android device connected
        echo Connect a device to test installation
        echo.
    )
) else (
    echo [INFO] ADB not found in PATH
    echo Install Android SDK Platform Tools to enable device testing
    echo.
)

REM Summary
echo ========================================
echo Verification Summary
echo ========================================
echo.
echo Tests Passed: %PASS_COUNT%/3
echo Tests Failed: %FAIL_COUNT%/3
echo.

if %FAIL_COUNT% equ 0 (
    echo [SUCCESS] All build outputs verified!
    echo.
    echo Next steps:
    echo 1. Install APKs on Android device
    echo 2. Verify separate app identifiers
    echo 3. Test each flavor's functionality
    echo 4. Complete the manual testing checklist
    echo.
    echo See BUILD_TESTING_GUIDE.md for detailed instructions
) else (
    echo [FAILURE] Some build outputs are missing
    echo Please run test_builds.bat to generate all APKs
)
echo.

pause
