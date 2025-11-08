# Splash Screen Setup Instructions

## Current Status
✅ App colors updated to match Ministry of Defense branding (dark teal #0D4D4D and gold #C4A962)
✅ Flutter splash screen configured to use custom logo
✅ Register page updated to show eagle logo only
⚠️ Need to add splash logo image file

## Required Steps

### 1. Add Splash Logo to Assets
Place your eagle logo image in the following location:
- **Path:** `assets/images/splash_logo.png`
- **Format:** PNG with transparent background
- **Recommended Size:** 512x512 pixels or larger
- **Content:** The gold eagle with three stars (from your uploaded image)

### 2. Add Logo to Android Native Splash (Optional but Recommended)
For a better native splash screen experience on Android:

1. Save your logo as `splash_logo.png` (512x512 px)
2. Copy it to: `android/app/src/main/res/drawable/splash_logo.png`
3. The launch_background.xml is already configured to use it

Alternatively, you can use Android Studio's Image Asset tool:
- Right-click on `android/app/src/main/res`
- Select `New > Image Asset`
- Choose `Launcher Icons` type
- Select your splash_logo.png file
- Generate icons for all densities

### 3. Test the Changes
After adding the image:

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run the app
flutter run --dart-define=FLAVOR=admin
```

## What's Already Done

### Flutter App
- ✅ Splash page shows dark teal background with logo
- ✅ App logo widget loads custom image with fallback
- ✅ Register page shows eagle logo only (no text/icons)
- ✅ Theme colors match Ministry branding

### Android Native
- ✅ Launch background set to dark teal (#0D4D4D)
- ✅ Status bar and navigation bar colors set
- ✅ Configured to show centered logo (once image is added)

### Colors Used
- **Primary (Dark Teal):** `#0D4D4D`
- **Secondary (Gold):** `#C4A962`
- **Background:** Dark teal for splash, white for main app
- **Text:** White on dark backgrounds, dark on light backgrounds

## Current Behavior

### With Image
Once you add `assets/images/splash_logo.png`:
- Splash screen will show your eagle logo on dark teal background
- Register page will show the eagle logo
- Welcome/login pages will show the eagle logo

### Without Image (Current)
- Splash screen shows fallback shield icon in gold on dark teal
- Register page shows fallback shield icon
- App still works perfectly, just uses fallback icon

## File Locations
- Flutter assets: `assets/images/splash_logo.png`
- Android drawable: `android/app/src/main/res/drawable/splash_logo.png` (optional)
- Splash page: `lib/features/auth/presentation/pages/splash_page.dart`
- App logo widget: `lib/features/auth/presentation/widgets/app_logo.dart`
- Register page: `lib/features/auth/presentation/pages/register_page.dart`
