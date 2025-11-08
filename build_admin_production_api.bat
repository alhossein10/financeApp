@echo off
REM Build Flutter Admin App with Production API (Optimized)
REM Replace 'yourdomain.com' with your actual Hostinger domain

echo ========================================
echo Building Admin App with Production API
echo Optimized Build (Split APKs)
echo ========================================
echo.

REM ============================================
REM IMPORTANT: Update this URL with your domain
REM ============================================
set API_BASE_URL=https://yourdomain.com
set ENVIRONMENT=production

echo Configuration:
echo   API URL: %API_BASE_URL%
echo   Environment: %ENVIRONMENT%
echo   Build Type: Split APKs (optimized)
echo.

REM Verify Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo Step 1: Clean previous builds
flutter clean

echo.
echo Step 2: Get dependencies
flutter pub get

echo.
echo Step 3: Build Admin APKs with production API
echo (This creates separate APKs for different architectures)
flutter build apk --release ^
  --dart-define=API_BASE_URL=%API_BASE_URL% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --split-per-abi ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin-prod ^
  --flavor admin ^
  -t lib/main_admin.dart

if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo Step 4: Copy to releases folder
if not exist releases mkdir releases
copy build\app\outputs\flutter-apk\app-admin-arm64-v8a-release.apk releases\finance-admin-arm64-production.apk
copy build\app\outputs\flutter-apk\app-admin-armeabi-v7a-release.apk releases\finance-admin-arm32-production.apk
copy build\app\outputs\flutter-apk\app-admin-x86_64-release.apk releases\finance-admin-x64-production.apk

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APKs created in 'releases' folder:
dir releases\finance-admin-*-production.apk | find "finance-admin"
echo.
echo API URL: %API_BASE_URL%
echo.
echo Distribution:
echo - ARM64 (Modern phones): finance-admin-arm64-production.apk (~30 MB)
echo - ARM32 (Older phones): finance-admin-arm32-production.apk (~28 MB)
echo - x64 (Emulators): finance-admin-x64-production.apk (~32 MB)
echo.
echo Next Steps:
echo 1. Test ARM64 APK on device
echo 2. Verify API calls go to %API_BASE_URL%
echo 3. Distribute to admin users
echo.

pause
