# Splash Screen Fix - Important Steps

## Problem
The splash screen still shows the Flutter icon instead of `splash_full.png`.

## Root Cause
1. ✅ Theme error fixed - removed conflicting `colorSchemeSeed`
2. ✅ Splash image copied to Android drawable folder
3. ✅ Android XML configuration updated
4. ⚠️ **App needs a complete clean rebuild** - Android caches native resources

## Solution - Follow These Steps:

### Step 1: Clean Build (REQUIRED)
```bash
flutter clean
flutter pub get
```

### Step 2: Verify Splash Image Location
Make sure `splash_full.png` exists at:
```
android/app/src/main/res/drawable/splash_full.png
```

### Step 3: Completely Rebuild
**DO NOT use hot reload or hot restart!**

You need a full rebuild because splash screens are native Android resources:

```bash
# For Android APK
flutter build apk

# Or for development
flutter run --release
```

### Step 4: Uninstall Old App
**IMPORTANT:** Before installing the new build:
1. Completely uninstall the app from your device/emulator
2. This clears the cached splash screen resources

```bash
# On connected device/emulator
adb uninstall com.example.finance_app
```

### Step 5: Install Fresh Build
```bash
# Install the new build
flutter install

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Alternative: Use the Rebuild Script
Run the provided script:
```bash
rebuild_splash.bat
```

## Verification
After rebuilding and installing:
1. Close the app completely if it's running
2. Click the app icon (launcher icon) - this is the icon in the mipmap folders
3. **The splash screen** (launch screen) appears AFTER clicking the icon
4. You should see `splash_full.png` with dark teal background (#1A3631)

## Troubleshooting

### Still seeing Flutter icon?
1. **Did you completely uninstall the old app?** - This is critical!
2. **Did you run `flutter clean`?** - Clears build cache
3. **Check the file exists:**
   ```bash
   dir android\app\src\main\res\drawable\splash_full.png
   ```
4. **Check AndroidManifest.xml** - Should reference `@style/LaunchTheme`
5. **Try a different device/emulator** - Cache might persist

### Image not showing?
- Verify the image file is valid PNG
- Check image size - very large images might cause issues
- Try a smaller test image first

## Configuration Files Updated
- ✅ `android/app/src/main/res/drawable/launch_background.xml`
- ✅ `android/app/src/main/res/drawable-v21/launch_background.xml`
- ✅ `android/app/src/main/res/values/styles.xml`
- ✅ `android/app/src/main/res/values-night/styles.xml`
- ✅ `lib/main.dart` (theme fixed)

## Note on App Icon vs Splash Screen
- **App Icon (Launcher Icon)**: The icon you click in the app drawer (mipmap folders)
- **Splash Screen**: The screen that appears AFTER clicking the app icon (drawable/launch_background.xml)

If you want to change the app icon too, you need to replace the files in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

