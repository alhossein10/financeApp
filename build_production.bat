@echo off
REM Production Build Script for Admin Group Management Release
REM Version: 1.1.0
REM Date: November 1, 2025

echo ========================================
echo Finance App - Production Build
echo Admin Group Management Feature v1.1.0
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

echo Step 1: Pre-build Verification
echo ========================================
echo.

REM Run tests
echo Running tests...
flutter test
if errorlevel 1 (
    echo.
    echo ERROR: Tests failed!
    echo Please fix failing tests before building production release
    pause
    exit /b 1
)

echo.
echo ✓ All tests passed
echo.

REM Run analyzer
echo Running code analysis...
flutter analyze
if errorlevel 1 (
    echo.
    echo WARNING: Code analysis found issues
    echo Please review and fix critical issues
    pause
)

echo.
echo ✓ Code analysis complete
echo.

echo Step 2: Clean Build Environment
echo ========================================
echo.

REM Stop Gradle daemons
echo Stopping Gradle daemons...
cd android
call gradlew --stop >nul 2>&1
cd ..

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

echo Step 3: Get Dependencies
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

echo Step 4: Build Production Releases
echo ========================================
echo.

REM Create releases directory
mkdir releases

echo Building User APK (release with optimizations)...
echo Note: If this fails with R8 errors, try build_production_safe.bat instead
flutter build apk --release --flavor user -t lib/main_user.dart --obfuscate --split-debug-info=build/debug-info-user
if errorlevel 1 (
    echo.
    echo ERROR: User APK build failed with R8/ProGuard error
    echo.
    echo Try one of these solutions:
    echo 1. Run build_production_safe.bat (builds without obfuscation)
    echo 2. Check android/app/proguard-rules.pro for issues
    echo 3. Temporarily disable minification in android/app/build.gradle.kts
    echo.
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-user-release.apk releases\finance-user-release.apk
echo ✓ User APK built successfully

echo.
echo Building User App Bundle (release with optimizations)...
flutter build appbundle --release --flavor user -t lib/main_user.dart --obfuscate --split-debug-info=build/debug-info-user
if errorlevel 1 (
    echo ERROR: User AAB build failed
    pause
    exit /b 1
)
copy build\app\outputs\bundle\userRelease\app-user-release.aab releases\finance-user-release.aab
echo ✓ User AAB built successfully

echo.
echo Building Admin APK (release with optimizations)...
flutter build apk --release --flavor admin -t lib/main_admin.dart --obfuscate --split-debug-info=build/debug-info-admin
if errorlevel 1 (
    echo ERROR: Admin APK build failed
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-admin-release.apk releases\finance-admin-release.apk
echo ✓ Admin APK built successfully

echo.
echo Building Admin Split APKs (optimized per architecture)...
echo This creates smaller APKs - users download only what they need
flutter build apk --release --flavor admin -t lib/main_admin.dart --split-per-abi --obfuscate --split-debug-info=build/debug-info-admin
if errorlevel 1 (
    echo ERROR: Admin Split APK build failed
    pause
    exit /b 1
)
copy build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk releases\finance-admin-arm32-release.apk
copy build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk releases\finance-admin-arm64-release.apk
copy build\app\outputs\flutter-apk\app-admin-x86_64-release.apk releases\finance-admin-x64-release.apk
echo ✓ Admin Split APKs built successfully

echo.
echo Building Admin App Bundle (release with optimizations)...
flutter build appbundle --release --flavor admin -t lib/main_admin.dart --obfuscate --split-debug-info=build/debug-info-admin
if errorlevel 1 (
    echo ERROR: Admin AAB build failed
    pause
    exit /b 1
)
copy build\app\outputs\bundle\adminRelease\app-admin-release.aab releases\finance-admin-release.aab
echo ✓ Admin AAB built successfully

echo.
echo Step 5: Verify Build Outputs
echo ========================================
echo.

REM Check if all files exist
if not exist releases\finance-user-release.apk (
    echo ERROR: User APK not found
    pause
    exit /b 1
)

if not exist releases\finance-user-release.aab (
    echo ERROR: User AAB not found
    pause
    exit /b 1
)

if not exist releases\finance-admin-release.apk (
    echo ERROR: Admin APK not found
    pause
    exit /b 1
)

if not exist releases\finance-admin-release.aab (
    echo ERROR: Admin AAB not found
    pause
    exit /b 1
)

echo ✓ All build outputs verified
echo.

REM Display file sizes
echo Build Output Summary:
echo ========================================
dir releases\finance-*.apk | find "finance-"
dir releases\finance-*.aab | find "finance-"
echo.

echo ========================================
echo Production Build Complete!
echo ========================================
echo.
echo Build outputs are in the 'releases' folder:
echo.
echo For Google Play Store:
echo   - releases\finance-user-release.aab
echo   - releases\finance-admin-release.aab
echo.
echo For Direct Distribution:
echo   - releases\finance-user-release.apk
echo   - releases\finance-admin-release.apk
echo.
echo Next Steps:
echo 1. Test APKs on real devices
echo 2. Upload AAB files to Google Play Console
echo 3. Set phased rollout to 10%%
echo 4. Monitor crash reports and user feedback
echo.
echo See PRODUCTION_DEPLOYMENT_GUIDE.md for detailed instructions
echo.

pause
