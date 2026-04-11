@echo off
REM SuperAdmin Flavor Build Script
REM Builds the SuperAdmin flavor APK for Finance App

echo ========================================
echo Finance App - SuperAdmin Build
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and try again
    pause
    exit /b 1
)

echo Select build type:
echo 1. Debug (for testing)
echo 2. Release (for distribution)
echo.
set /p choice="Enter choice (1-2): "

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
echo Invalid choice
pause
exit /b 1

:build_debug
echo.
echo Building SuperAdmin APK (debug)...
echo.
call flutter build apk --debug --flavor superAdmin -t lib/main_superadmin.dart
if errorlevel 1 (
    echo.
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location:
echo   build\app\outputs\flutter-apk\app-superAdmin-debug.apk
echo.
echo App Name: الإدارة المالية (سوبر)
echo Package: com.app.finance.superadmin
echo.
echo You can install this APK on your device for testing
echo.
pause
exit /b 0

:build_release
echo.
echo Building SuperAdmin APK (release)...
echo.
call flutter build apk --release --flavor superAdmin -t lib/main_superadmin.dart
if errorlevel 1 (
    echo.
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location:
echo   build\app\outputs\flutter-apk\app-superAdmin-release.apk
echo.
echo App Name: الإدارة المالية (سوبر)
echo Package: com.app.finance.superadmin
echo.
echo This APK is ready for distribution
echo.
pause
exit /b 0
