@echo off
echo ========================================
echo Finance App - User Version on Mobile
echo ========================================
echo.
echo IMPORTANT: Update YOUR_COMPUTER_IP with your actual IP address!
echo.
echo Step 1: Find your IP address
echo    Run: ipconfig
echo    Look for: IPv4 Address (e.g., 192.168.1.100)
echo.
echo Step 2: Edit this file and replace YOUR_COMPUTER_IP
echo.
echo Step 3: Make sure your mobile and computer are on the same WiFi
echo.
pause
echo.
echo Starting app on mobile...
echo.

flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000/api/v1

pause
