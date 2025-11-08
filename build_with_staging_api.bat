@echo off
REM Build Flutter App with Staging API (for testing)
REM Replace 'staging.yourdomain.com' with your staging domain

echo ========================================
echo Building User App with Staging API
echo ========================================
echo.

REM ============================================
REM IMPORTANT: Update this URL with your staging domain
REM ============================================
set API_BASE_URL=https://staging.yourdomain.com
set ENVIRONMENT=staging

echo Configuration:
echo   API URL: %API_BASE_URL%
echo   Environment: %ENVIRONMENT%
echo.

flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo Cleaning and building...
flutter clean
flutter pub get

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
echo Staging Build Complete!
echo ========================================
echo.
echo APK: build\app\outputs\flutter-apk\app-user-release.apk
echo API: %API_BASE_URL%
echo.
echo Use this for testing before production deployment
echo.

pause
