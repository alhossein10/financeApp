@echo off
REM Finance Backend Queue Worker
REM This script runs the Laravel queue worker for development on Windows

echo Starting Finance Backend Queue Worker...
echo.
echo Press Ctrl+C to stop the worker
echo.

php artisan queue:work database --sleep=3 --tries=3 --timeout=60 --verbose

pause
