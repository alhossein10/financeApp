# Splash Screen Image

## Required Image
Place your Ministry of Defense splash screen image here as:
- **Filename:** `splash_logo.png`
- **Format:** PNG with transparent or dark teal background
- **Recommended Size:** 512x512 pixels or larger
- **Content:** The eagle logo with Arabic text that you uploaded

## Current Status
The app will work without this image and will show a default fallback logo.
Once you add the image, it will automatically be used on the splash screen.

## How to Add
1. Save your uploaded image as `splash_logo.png`
2. Copy it to this folder: `assets/images/`
3. Run `flutter clean && flutter pub get`
4. Build and run the app

The image will appear on:
- App splash screen (when app starts)
- Login/welcome pages
- Any place where the AppLogo widget is used
