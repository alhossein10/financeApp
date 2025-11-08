# Image Setup Instructions

## Required Images

You need to add TWO images to this folder:

### 1. splash_full.png (Splash Screen - First Image)
- **Filename:** `splash_full.png`
- **Content:** The FIRST image you uploaded - eagle with text below:
  - Eagle logo with 3 stars
  - Text: "وزارة الدفاع"
  - Text: "هيئة الاتصالات والتكنولوجيا"
- **Background:** Dark teal (#0D4D4D) or transparent
- **Recommended Size:** 512x768 pixels (portrait orientation to include text)
- **Used in:** Splash screen when app opens

### 2. eagle_only.png (Register Page - Second Image)
- **Filename:** `eagle_only.png`
- **Content:** The SECOND image you uploaded - ONLY the eagle:
  - Eagle logo with 3 stars
  - NO text
- **Background:** Transparent or black
- **Recommended Size:** 512x512 pixels (square)
- **Used in:** Register page logo

## How to Add

1. Save the first image (with text) as `splash_full.png`
2. Save the second image (eagle only) as `eagle_only.png`
3. Copy both files to this folder: `assets/images/`
4. Run:
   ```bash
   flutter clean
   flutter pub get
   flutter run --dart-define=FLAVOR=admin
   ```

## Current Behavior

### Without Images (Fallback)
- Splash screen shows fallback icon with text
- Register page shows fallback shield icon
- App works perfectly

### With Images (After you add them)
- Splash screen shows your full image with eagle + text
- Register page shows only the eagle logo
- Perfect branding!

## File Locations
- Splash full image: `assets/images/splash_full.png`
- Eagle only image: `assets/images/eagle_only.png`
