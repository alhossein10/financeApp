@echo off
REM Optimized Admin Build Script - Maximum Size Reduction
REM Target: Reduce from 72MB to ~20-30MB
REM
REM Optimization strategies:
REM 1. Split APKs per architecture (saves ~30-40MB)
REM 2. Code obfuscation and shrinking (saves ~10-15MB)
REM 3. Resource shrinking (saves ~2-5MB)
REM 4. Debug symbols separated (saves ~5-10MB)

echo ========================================
echo Finance App - Optimized Admin Build
echo Target: Reduce size from 72MB to ~20-30MB
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

echo Step 2: Build Optimized Split APKs
echo ========================================
echo Building optimized APKs (one per architecture)...
echo This creates smaller APKs - users download only what they need
echo.
echo Optimizations enabled:
echo   - Code obfuscation
echo   - Resource shrinking
echo   - Split by architecture
echo   - Debug symbols separated
echo.

flutter build apk --release ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin ^
  --flavor admin ^
  -t lib/main_admin.dart

if errorlevel 1 (
    echo ERROR: Build failed
    echo.
    echo Troubleshooting:
    echo 1. Make sure ProGuard rules are correct
    echo 2. Check for any compilation errors
    echo 3. Try building without --obfuscate first
    pause
    exit /b 1
)

echo.
echo Step 3: Copy to Releases
echo ========================================

if not exist releases mkdir releases

if exist build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk (
    copy build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk releases\finance-admin-arm32-release.apk
    echo ✓ ARM32 APK copied
)

if exist build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk (
    copy build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk releases\finance-admin-arm64-release.apk
    echo ✓ ARM64 APK copied
)

if exist build\app\outputs\flutter-apk\app-admin-x86_64-release.apk (
    copy build\app\outputs\flutter-apk\app-admin-x86_64-release.apk releases\finance-admin-x64-release.apk
    echo ✓ x64 APK copied
)

echo.
echo Step 4: Build App Bundle (for Play Store)
echo ========================================
echo Building optimized App Bundle...
echo.

flutter build appbundle --release ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin ^
  --flavor admin ^
  -t lib/main_admin.dart

if errorlevel 1 (
    echo WARNING: App Bundle build failed
    echo Continuing with APKs only...
) else (
    copy build\app\outputs\bundle\adminRelease\app-admin-release.aab releases\finance-admin-release.aab
    echo ✓ App Bundle copied
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Optimized APKs created in 'releases' folder:
echo.

dir releases\finance-admin-*.apk | find "finance-admin"
if exist releases\finance-admin-release.aab (
    dir releases\finance-admin-release.aab | find "finance-admin"
)
echo.
echo Distribution Guide:
echo ========================================
echo.
echo For Google Play Store:
echo   - Use: finance-admin-release.aab
echo   - Play Store automatically splits by architecture
echo   - Users download only what they need (~20-30MB)
echo.
echo For Direct Distribution:
echo   - ARM64 (arm64-v8a): Modern phones (2019+) - RECOMMENDED
echo     File: finance-admin-arm64-release.apk (~20-30MB)
echo   - ARM32 (armeabi-v7a): Older phones (pre-2019)
echo     File: finance-admin-arm32-release.apk (~20-30MB)
echo   - x64 (x86_64): Emulators and some tablets
echo     File: finance-admin-x64-release.apk (~20-30MB)
echo.
echo Most users need: finance-admin-arm64-release.apk
echo.
echo Debug symbols saved to: build/debug-info-admin
echo (Keep these for crash report analysis)
echo.
echo Size Reduction Summary:
echo ========================================
echo Before: ~72MB (universal APK)
echo After:  ~20-30MB per architecture (split APKs)
echo Savings: ~40-50MB per user download
echo.
echo Note: App Bundle (AAB) is recommended for Play Store
echo       as it automatically optimizes for each device.
echo.

pause

