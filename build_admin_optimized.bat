@echo off
REM Optimized Admin Build Script - Reduces APK size by ~50%%
REM Creates separate APKs for different device architectures

echo ========================================
echo Finance App - Optimized Admin Build
echo Target: Reduce size from 72MB to ~30MB
echo ========================================
echo.

REM Check Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo Step 1: Clean Build
echo ========================================
flutter clean
flutter pub get
echo.

echo Step 2: Build Split APKs
echo ========================================
echo Building optimized APKs (one per architecture)...
echo This creates smaller APKs - users download only what they need
echo.

flutter build apk --release ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin ^
  --flavor admin ^
  -t lib/main_admin.dart

if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo Step 3: Copy to Releases
echo ========================================

if not exist releases mkdir releases

copy build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk releases\finance-admin-arm32-release.apk
copy build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk releases\finance-admin-arm64-release.apk
copy build\app\outputs\flutter-apk\app-admin-x86_64-release.apk releases\finance-admin-x64-release.apk

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Optimized APKs created in 'releases' folder:
echo.
dir releases\finance-admin-*.apk | find "finance-admin"
echo.
echo Distribution Guide:
echo - ARM64 (arm64-v8a): Modern phones (2019+) - RECOMMENDED
echo - ARM32 (armeabi-v7a): Older phones (pre-2019)
echo - x64 (x86_64): Emulators and some tablets
echo.
echo Most users need: finance-admin-arm64-release.apk
echo.
echo Debug symbols saved to: build/debug-info-admin
echo (Keep these for crash report analysis)
echo.

pause
