@echo off
echo ========================================
echo Running Flutter App (Fresh Start)
echo ========================================
echo.

echo Killing any running Flutter processes...
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul

echo.
echo Starting app...
flutter run

pause
