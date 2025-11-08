@echo off
echo ====================================
echo Rebuilding App with New Splash Screen
echo ====================================
echo.
echo Step 1: Cleaning build cache...
flutter clean
echo.
echo Step 2: Getting dependencies...
flutter pub get
echo.
echo Step 3: Verifying splash image is in place...
if exist "android\app\src\main\res\drawable\splash_full.png" (
    echo [OK] splash_full.png found
) else (
    echo [ERROR] splash_full.png NOT found!
    echo Copying from assets...
    copy /Y "assets\images\splash_full.png" "android\app\src\main\res\drawable\splash_full.png"
)
echo.
echo Step 4: Building app (this may take a while)...
echo.
echo IMPORTANT: After build completes, you MUST:
echo 1. Completely stop/uninstall the old app from your device/emulator
echo 2. Install the new build
echo 3. Launch the app fresh
echo.
echo Starting build...
flutter build apk
echo.
echo ====================================
echo Build complete!
echo ====================================
echo.
echo To install on connected device:
echo   flutter install
echo.
echo Or manually install:
echo   adb install build\app\outputs\flutter-apk\app-release.apk
echo.
pause

