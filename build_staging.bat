@echo off
echo Building Finance App - Staging
echo.
flutter build apk --flavor staging --dart-define=API_BASE_URL=https://staging-api.example.com/api/v1 --dart-define=ENVIRONMENT=staging --dart-define=DEBUG_MODE=false --dart-define=ENABLE_LOGGING=true --dart-define=ANALYTICS_ENABLED=true
echo.
echo Build complete! APK location:
echo build\app\outputs\flutter-apk\app-staging-release.apk
echo.
pause
