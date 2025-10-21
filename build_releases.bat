@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Finance App - Release Builder
echo ========================================
echo.

REM Create releases directory if it doesn't exist
if not exist "releases" mkdir releases

REM Clean old releases
echo Cleaning old releases...
if exist "releases\*.apk" del /q "releases\*.apk"
if exist "releases\*.aab" del /q "releases\*.aab"
echo.

echo Cleaning Flutter build cache...
call flutter clean
echo.

echo Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo.

REM Build USER flavor
echo ========================================
echo Building USER Flavor
echo ========================================
echo.

echo [1/4] Building USER APK (Release)...
call flutter build apk --release --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo ERROR: USER APK build failed
    pause
    exit /b 1
)
if exist "build\app\outputs\flutter-apk\app-user-release.apk" (
    copy "build\app\outputs\flutter-apk\app-user-release.apk" "releases\finance-user-release.apk"
    echo SUCCESS: USER APK created
) else (
    echo WARNING: USER APK not found
)
echo.

echo [2/4] Building USER App Bundle (Release)...
call flutter build appbundle --release --flavor user -t lib/main_user.dart
if errorlevel 1 (
    echo WARNING: USER App Bundle build failed
) else (
    if exist "build\app\outputs\bundle\userRelease\app-user-release.aab" (
        copy "build\app\outputs\bundle\userRelease\app-user-release.aab" "releases\finance-user-release.aab"
        echo SUCCESS: USER App Bundle created
    )
)
echo.

REM Build ADMIN flavor
echo ========================================
echo Building ADMIN Flavor
echo ========================================
echo.

echo [3/4] Building ADMIN APK (Release)...
call flutter build apk --release --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo ERROR: ADMIN APK build failed
    pause
    exit /b 1
)
if exist "build\app\outputs\flutter-apk\app-admin-release.apk" (
    copy "build\app\outputs\flutter-apk\app-admin-release.apk" "releases\finance-admin-release.apk"
    echo SUCCESS: ADMIN APK created
) else (
    echo WARNING: ADMIN APK not found
)
echo.

echo [4/4] Building ADMIN App Bundle (Release)...
call flutter build appbundle --release --flavor admin -t lib/main_admin.dart
if errorlevel 1 (
    echo WARNING: ADMIN App Bundle build failed
) else (
    if exist "build\app\outputs\bundle\adminRelease\app-admin-release.aab" (
        copy "build\app\outputs\bundle\adminRelease\app-admin-release.aab" "releases\finance-admin-release.aab"
        echo SUCCESS: ADMIN App Bundle created
    )
)
echo.

REM Summary
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Release files are in the 'releases' folder:
echo.
if exist "releases\finance-user-release.apk" (
    echo [OK] finance-user-release.apk
) else (
    echo [MISSING] finance-user-release.apk
)
if exist "releases\finance-user-release.aab" (
    echo [OK] finance-user-release.aab
) else (
    echo [MISSING] finance-user-release.aab
)
if exist "releases\finance-admin-release.apk" (
    echo [OK] finance-admin-release.apk
) else (
    echo [MISSING] finance-admin-release.apk
)
if exist "releases\finance-admin-release.aab" (
    echo [OK] finance-admin-release.aab
) else (
    echo [MISSING] finance-admin-release.aab
)
echo.
echo APK files can be installed directly on Android devices
echo AAB files are for Google Play Store distribution
echo.
pause
