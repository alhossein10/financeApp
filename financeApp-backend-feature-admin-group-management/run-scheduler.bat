@echo off
REM Finance Backend Scheduler
REM This script simulates the cron scheduler for development on Windows
REM It runs the scheduler every minute

echo Starting Finance Backend Scheduler...
echo.
echo This will run scheduled tasks every minute
echo Press Ctrl+C to stop
echo.

:loop
php artisan schedule:run
timeout /t 60 /nobreak > nul
goto loop
