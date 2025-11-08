@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Finance App - Development Builder
echo ========================================
echo.

echo Select flavor to build:
echo 1. Admin (debug)
echo 2. User (debug)
echo 3. Both (debug)
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" goto build_admin
if "%choice%"=="2" goto build_user
if "%choice%"=="3" goto build_both
echo Invalid choice
pause
exit /b 1

:build_admin
echo.
echo Building ADMIN flavor (debug)...
call flutter build apk --debug --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo.
echo Build complete!
echo APK: build\app\outputs\flutter-apk\app-admin-debug.apk
echo.
pause
exit /b 0

:build_user
echo.
echo Building USER flavor (debug)...
call flutter build apk --debug --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo.
echo Build complete!
echo APK: build\app\outputs\flutter-apk\app-user-debug.apk
echo.
pause
exit /b 0

:build_both
echo.
echo Building USER flavor (debug)...
call flutter build apk --debug --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo ERROR: USER build failed
    pause
    exit /b 1
)
echo.
echo Building ADMIN flavor (debug)...
call flutter build apk --debug --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo ERROR: ADMIN build failed
    pause
    exit /b 1
)
echo.
echo Both builds complete!
echo USER APK:  build\app\outputs\flutter-apk\app-user-debug.apk
echo ADMIN APK: build\app\outputs\flutter-apk\app-admin-debug.apk
echo.
pause
exit /b 0
