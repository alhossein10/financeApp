@echo off
REM ============================================
REM Run All Flavors with Custom API Host
REM Host: 192.168.137.1:8000
REM ============================================

echo.
echo ========================================
echo Flutter Finance App - Test All Flavors
echo API Host: 192.168.137.1:8000
echo ========================================
echo.

REM Set API base URL
set API_BASE_URL=http://192.168.137.1:8000

echo Choose flavor to run:
echo.
echo 1. User Flavor
echo 2. Admin Flavor
echo 3. SuperAdmin Flavor
echo 4. Run All (Sequential)
echo.

set /p choice="Enter choice (1-4): "

if "%choice%"=="1" goto user
if "%choice%"=="2" goto admin
if "%choice%"=="3" goto superadmin
if "%choice%"=="4" goto all
goto end

:user
echo.
echo ========================================
echo Running USER Flavor
echo ========================================
echo.
flutter run --flavor user --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
goto end

:admin
echo.
echo ========================================
echo Running ADMIN Flavor
echo ========================================
echo.
flutter run --flavor admin --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
goto end

:superadmin
echo.
echo ========================================
echo Running SUPERADMIN Flavor
echo ========================================
echo.
flutter run --flavor superAdmin --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
goto end

:all
echo.
echo ========================================
echo Running All Flavors Sequentially
echo ========================================
echo.
echo Press Ctrl+C to stop current flavor and move to next
echo.

echo.
echo [1/3] Running USER Flavor...
echo.
flutter run --flavor user --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true

echo.
echo [2/3] Running ADMIN Flavor...
echo.
flutter run --flavor admin --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true

echo.
echo [3/3] Running SUPERADMIN Flavor...
echo.
flutter run --flavor superAdmin --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true

:end
echo.
echo ========================================
echo Done!
echo ========================================
pause
