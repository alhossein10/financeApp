@echo off
echo ========================================
echo Finance App - Admin Version with Backend
echo ========================================
echo.
echo Backend URL: http://127.0.0.1:8000/api/v1
echo.
echo Starting app...
echo.

flutter run -d windows --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

pause
