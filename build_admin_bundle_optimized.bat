@echo off
REM Optimized Admin App Bundle for Google Play Store
REM App Bundles automatically optimize for each device

echo ========================================
echo Finance App - Optimized Admin Bundle
echo For Google Play Store Upload
echo ========================================
echo.

flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found
    pause
    exit /b 1
)

echo Cleaning and preparing...
flutter clean
flutter pub get

echo.
echo Building optimized App Bundle...
echo.

flutter build appbundle --release ^
  --obfuscate ^
  --split-debug-info=build/debug-info-admin-bundle ^
  --flavor admin ^
  -t lib/main_admin.dart

if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

if not exist releases mkdir releases
copy build\app\outputs\bundle\adminRelease\app-admin-release.aab releases\finance-admin-release.aab

echo.
echo ========================================
echo App Bundle Created!
echo ========================================
echo.
echo File: releases\finance-admin-release.aab
dir releases\finance-admin-release.aab | find "finance-admin"
echo.
echo Upload this to Google Play Console
echo Google Play will generate optimized APKs for each device
echo Users will download ~30-40MB instead of 72MB
echo.

pause
