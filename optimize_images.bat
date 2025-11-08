@echo off
REM Image Optimization Helper
REM Provides instructions for compressing images

echo ========================================
echo Image Optimization Guide
echo ========================================
echo.
echo Current large images found:
echo - Picture5.png: 1.29 MB (splash screen)
echo.
echo ========================================
echo Option 1: Online Compression (EASIEST)
echo ========================================
echo.
echo 1. Go to: https://tinypng.com
echo 2. Upload: assets\images\Picture5.png
echo 3. Download compressed version
echo 4. Replace original file
echo.
echo Expected result: 1.29 MB → ~100-200 KB
echo Savings: ~1 MB
echo.
echo ========================================
echo Option 2: Use ImageMagick (if installed)
echo ========================================
echo.
echo If you have ImageMagick installed:
echo.
echo magick convert assets/images/Picture5.png -quality 85 -resize 1024x1024 assets/images/Picture5_optimized.png
echo.
echo Then replace Picture5.png with Picture5_optimized.png
echo.
echo ========================================
echo Option 3: Convert to WebP (Advanced)
echo ========================================
echo.
echo WebP format is 25-35%% smaller than PNG
echo.
echo 1. Convert PNG to WebP using online tool
echo 2. Update pubspec.yaml to reference .webp file
echo 3. Update flutter_native_splash config
echo.
echo ========================================
echo Recommendation
echo ========================================
echo.
echo For quickest results:
echo 1. Use TinyPNG.com to compress Picture5.png
echo 2. This alone saves ~1 MB
echo 3. Combined with split APKs = 60%% total reduction
echo.
echo After compressing images, rebuild:
echo   build_admin_optimized.bat
echo.

pause
