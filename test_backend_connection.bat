@echo off
echo ========================================
echo Testing Backend Connection
echo ========================================
echo.
echo Testing: http://127.0.0.1:8000/api/v1/organizations
echo.
echo Opening in browser...
echo.
start http://127.0.0.1:8000/api/v1/organizations
echo.
echo If you see JSON with 3 organizations, the backend is working!
echo If you see an error, make sure your Laravel backend is running.
echo.
pause
