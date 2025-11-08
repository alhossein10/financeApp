# Download Prettier Arabic Font Instructions

## Recommended Font: Tajawal

Tajawal is a modern, clean Arabic font that looks professional and beautiful. It's available for free.

### Download Steps:

1. **Visit Google Fonts:**
   - Go to: https://fonts.google.com/specimen/Tajawal
   - Click "Download family" button

2. **Or Download Directly:**
   - Regular: https://github.com/google/fonts/raw/main/ofl/tajawal/Tajawal-Regular.ttf
   - Bold: https://github.com/google/fonts/raw/main/ofl/tajawal/Tajawal-Bold.ttf
   - Medium: https://github.com/google/fonts/raw/main/ofl/tajawal/Tajawal-Medium.ttf (optional)

3. **Place Fonts in Project:**
   - Copy `Tajawal-Regular.ttf` to `assets/fonts/`
   - Copy `Tajawal-Bold.ttf` to `assets/fonts/`

4. **Alternative: Cairo Font**
   - If you prefer Cairo: https://fonts.google.com/specimen/Cairo
   - Same download process

### After Download:

The code is already updated to use Tajawal. Just replace the font files and run:
```bash
flutter pub get
flutter clean
flutter run
```

### Current Status:

- Code is ready to use Tajawal-Regular.ttf and Tajawal-Bold.ttf
- If Tajawal is not found, it will fallback to Amiri
- All exports now support Arabic translations

