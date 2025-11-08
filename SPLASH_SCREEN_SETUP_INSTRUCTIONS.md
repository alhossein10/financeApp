# Splash Screen Setup Instructions

This document provides instructions for setting up the splash screen images for Android and iOS.

## Changes Made

1. **Android Splash Screen Configuration**
   - Updated `android/app/src/main/res/drawable/launch_background.xml` to reference `splash_full.png`
   - Updated `android/app/src/main/res/drawable-v21/launch_background.xml` to reference `splash_full.png`
   - Updated background colors to match splash screen theme (#1A3631)

2. **iOS Splash Screen Configuration**
   - Updated `ios/Runner/Base.lproj/LaunchScreen.storyboard` with dark teal background (#1A3631)
   - Configured LaunchImage to display centered

3. **Flutter App Updates**
   - Updated theme colors to match splash screen (dark teal #1A3631 and gold #B8A170)
   - Updated welcome, login, and register pages to display `eagle_with_text.png`
   - Enhanced watermark to use `eagle_with_text.png` on all pages

## Required Manual Steps

### Android

You need to copy `splash_full.png` to the Android drawable folder:

1. **Option 1: Use the provided batch script**
   ```bash
   copy_splash_images.bat
   ```

2. **Option 2: Manual copy**
   - Copy `assets/images/splash_full.png` to `android/app/src/main/res/drawable/splash_full.png`

### iOS

For iOS, you need to replace the LaunchImage assets:

1. **Option 1: Using Xcode**
   - Open the project in Xcode
   - Navigate to `Runner/Assets.xcassets/LaunchImage.imageset`
   - Replace the existing LaunchImage files with `splash_full.png` scaled versions:
     - `LaunchImage.png` (1x - original size)
     - `LaunchImage@2x.png` (2x - double the dimensions)
     - `LaunchImage@3x.png` (3x - triple the dimensions)

2. **Option 2: Manual copy**
   - Copy and scale `assets/images/splash_full.png` to:
     - `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (1x)
     - `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` (2x)
     - `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` (3x)

## Theme Colors

The app theme has been updated to match the splash screen:
- **Primary Color (Dark Teal)**: #1A3631
- **Secondary Color (Gold)**: #B8A170
- **App Bar Background**: #1A3631
- **App Bar Foreground**: #B8A170

## Watermark

The `eagle_with_text.png` image is now used as a watermark on all pages with 5% opacity (adjustable via `WatermarkBackground` widget's `opacity` parameter).

## Testing

After copying the images:
1. **Android**: Rebuild the app with `flutter build apk` or run `flutter run`
2. **iOS**: Rebuild the app with `flutter build ios` or run `flutter run`

The splash screen should display `splash_full.png` instead of the default Flutter icon.

