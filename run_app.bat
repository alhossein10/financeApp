@echo off
REM Quick run script for Flutter app with Laravel backend

echo ========================================
echo Flutter Finance App - Quick Run
echo ========================================
echo.
echo Select your target device:
echo 1. Android Emulator (10.0.2.2:8000)
echo 2. iOS Simulator (127.0.0.1:8000)
echo 3. Real Device (Enter IP manually)
echo 4. Admin Flavor (Android Emulator)
echo.

set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo Running on Android Emulator...
    flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
) else if "%choice%"=="2" (
    echo.
    echo Running on iOS Simulator...
    flutter run --flavor user --dart-define=API_BASE_URL=http://127.0.0.1:8000
) else if "%choice%"=="3" (
    echo.
    set /p ip="Enter your computer's IP address: "
    echo Running on Real Device with IP: %ip%
    flutter run --flavor user --dart-define=API_BASE_URL=http://%ip%:8000
) else if "%choice%"=="4" (
    echo.
    echo Running Admin Flavor on Android Emulator...
    flutter run --flavor admin --dart-define=API_BASE_URL=http://10.0.2.2:8000
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

pause
