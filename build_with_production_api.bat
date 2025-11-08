@echo off
REM Build Flutter User App with Production API
REM Replace 'yourdomain.com' with your actual Hostinger domain

echo ========================================
echo Building User App with Production API
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
echo Step 3: Build User APK with production API
flutter build apk --release ^
  --dart-define=API_BASE_URL=%API_BASE_URL% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --flavor user ^
  -t lib/main_user.dart

if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-user-release.apk
echo API URL: %API_BASE_URL%
echo.
echo Next Steps:
echo 1. Install APK on device: adb install build\app\outputs\flutter-apk\app-user-release.apk
echo 2. Test registration and login
echo 3. Verify API calls go to %API_BASE_URL%
echo.

pause
