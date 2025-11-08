@echo off
REM Script to copy splash_full.png to Android and iOS resources

echo Copying splash_full.png to Android drawable resources...

REM Copy to Android drawable folder
copy /Y "assets\images\splash_full.png" "android\app\src\main\res\drawable\splash_full.png"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Copied to Android drawable folder
) else (
    echo [ERROR] Failed to copy to Android drawable folder
)

echo.
echo For iOS, you need to manually copy splash_full.png to:
echo - ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png (1x)
echo - ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png (2x - scale 2x)
echo - ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png (3x - scale 3x)
echo.
echo Or use Xcode to set the LaunchImage asset.
echo.
pause

