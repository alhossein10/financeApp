@echo off
echo ========================================
echo Cleaning Build Artifacts
echo ========================================
echo.

echo Stopping any running Gradle daemons...
cd android
call gradlew --stop 2>nul
cd ..
echo.

echo Running Flutter clean...
call flutter clean
echo.

echo Cleaning Android build cache...
if exist "android\.gradle" (
    echo Removing android\.gradle...
    rmdir /s /q "android\.gradle" 2>nul
)
if exist "android\app\build" (
    echo Removing android\app\build...
    rmdir /s /q "android\app\build" 2>nul
)
if exist "android\build" (
    echo Removing android\build...
    rmdir /s /q "android\build" 2>nul
)
echo.

echo Cleaning build directory...
if exist "build" (
    echo Removing build directory...
    rmdir /s /q "build" 2>nul
    if exist "build" (
        echo Some files are locked, attempting force delete...
        timeout /t 2 /nobreak >nul
        rmdir /s /q "build" 2>nul
    )
)
echo.

echo Cleaning releases directory...
if exist "releases" (
    echo Removing releases directory...
    rmdir /s /q "releases" 2>nul
)
echo.

echo ========================================
echo Clean Complete!
echo ========================================
echo.
echo You can now run:
echo   - build_releases.bat (for production builds)
echo   - build_dev.bat (for development builds)
echo   - flutter run --flavor admin -t lib/main_admin.dart
echo   - flutter run --flavor user -t lib/main_user.dart
echo.
pause
