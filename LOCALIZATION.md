# Localization Guide

## Overview
This app now supports full Arabic localization with RTL (Right-to-Left) support.

## Current Setup
- **Default Language**: Arabic (ar)
- **Supported Languages**: Arabic (ar), English (en)
- **Text Direction**: Automatically handled by Flutter based on locale

## How It Works

### 1. Localization System
The app uses Flutter's built-in localization system with a custom `AppLocalizations` class located in `lib/l10n/app_localizations.dart`.

### 2. Switching Languages
To change the app language, modify the `locale` parameter in `lib/main.dart`:

```dart
// For Arabic (current default)
locale: const Locale('ar'),

// For English
locale: const Locale('en'),
```

### 3. Adding New Translations
To add new text strings:

1. Open `lib/l10n/app_localizations.dart`
2. Add the key-value pair to both 'ar' and 'en' maps:

```dart
'en': {
  'your_key': 'Your English Text',
  // ... other translations
},
'ar': {
  'your_key': 'النص العربي',
  // ... other translations
},
```

3. Use it in your code:
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.translate('your_key'))
```

### 4. PDF and Excel Exports
- PDF exports use Arabic fonts (Amiri) embedded in the assets
- Excel exports display Arabic text (requires Arabic font support on the viewing device)
- Both maintain RTL text direction for Arabic content

## Features
✅ All UI text translated to Arabic
✅ RTL layout support
✅ Arabic number formatting
✅ Date pickers in Arabic
✅ PDF exports with Arabic fonts
✅ Excel exports with Arabic text

## Notes
- The app automatically adjusts text direction based on the selected locale
- Material Design widgets handle RTL automatically
- Custom fonts (Amiri) are used for PDF generation to ensure proper Arabic rendering
