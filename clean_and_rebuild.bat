@echo off
echo ========================================
echo Clean and Rebuild Flutter App
echo ========================================
echo.

echo Step 1: Flutter clean...
call flutter clean

echo.
echo Step 2: Delete build folders...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

echo.
echo Step 3: Get dependencies...
call flutter pub get

echo.
echo Step 4: Build for debug...
call flutter build apk --debug

echo.
echo ========================================
echo Clean and rebuild complete!
echo Now run: flutter run
echo ========================================
pause
