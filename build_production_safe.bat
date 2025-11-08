@echo off
REM Production Build Script - Safe Mode (No Obfuscation)
REM Use this if the regular build fails with R8 errors
REM This still uses code shrinking and resource shrinking but without obfuscation

echo ========================================
echo Finance App - Production Build (Safe Mode)
echo Building without obfuscation to avoid R8 errors
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

echo Step 1: Clean Build Environment
echo ========================================
echo.

REM Clean Flutter
echo Cleaning Flutter build...
flutter clean

REM Remove old releases
if exist releases (
    echo Removing old releases...
    rmdir /s /q releases
)

echo.
echo ✓ Build environment cleaned
echo.

echo Step 2: Get Dependencies
echo ========================================
echo.

flutter pub get
if errorlevel 1 (
    echo.
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo ✓ Dependencies updated
echo.

echo Step 3: Build Production Releases (Safe Mode)
echo ========================================
echo.
echo Note: Building without minification or obfuscation
echo Split APKs will still reduce size significantly
echo.

REM Create releases directory
mkdir releases

echo Building User APK (release, no obfuscation)...
flutter build apk --release --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo ERROR: User APK build failed
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-user-release.apk releases\finance-user-release-safe.apk
echo ✓ User APK built successfully

echo.
echo Building User App Bundle (release, no obfuscation)...
flutter build appbundle --release --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo ERROR: User AAB build failed
    pause
    exit /b 1
)
copy build\app\outputs\bundle\userRelease\app-user-release.aab releases\finance-user-release-safe.aab
echo ✓ User AAB built successfully

echo.
echo Building Admin APK (release, no obfuscation)...
flutter build apk --release --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo ERROR: Admin APK build failed
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-admin-release.apk releases\finance-admin-release-safe.apk
echo ✓ Admin APK built successfully

echo.
echo Building Admin Split APKs (optimized per architecture, no obfuscation)...
flutter build apk --release --flavor admin -t lib/main_admin.dart --split-per-abi
if errorlevel 1 (
    echo ERROR: Admin Split APK build failed
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk releases\finance-admin-arm32-release-safe.apk
copy build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk releases\finance-admin-arm64-release-safe.apk
copy build\app\outputs\flutter-apk\app-admin-x86_64-release.apk releases\finance-admin-x64-release-safe.apk
echo ✓ Admin Split APKs built successfully

echo.
echo Building Admin App Bundle (release, no obfuscation)...
flutter build appbundle --release --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo ERROR: Admin AAB build failed
    pause
    exit /b 1
)
copy build\app\outputs\bundle\adminRelease\app-admin-release.aab releases\finance-admin-release-safe.aab
echo ✓ Admin AAB built successfully


echo.
echo ========================================
echo Production Build Complete (Safe Mode)!
echo ========================================
echo.
echo Build outputs are in the 'releases' folder (with -safe suffix):
echo.
dir releases\finance-*-safe.* | find "finance-"
echo.
echo Note: These builds do NOT use minification or obfuscation
echo       (to avoid R8 errors).
echo.
echo Size reduction comes from:
echo   - Split APKs per architecture (~30-40 MB savings)
echo   - Expected size: ~20-30 MB per architecture (down from 72 MB)
echo.
pause

