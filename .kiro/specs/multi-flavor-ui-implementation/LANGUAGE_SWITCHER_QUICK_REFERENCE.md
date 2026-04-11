# Language Switcher - Quick Reference Guide

## Overview
The language switcher allows users to change the app language between English and Arabic.

## How to Access

### From Profile Page
1. Open the app
2. Navigate to **Profile** tab
3. Tap **Language Settings** button (with 🌐 icon)

## Supported Languages

| Language | Native Name | Flag | Code |
|----------|-------------|------|------|
| English  | English     | 🇬🇧   | en   |
| Arabic   | العربية     | 🇸🇦   | ar   |

## How to Change Language

### Step-by-Step
1. **Open Language Settings**
   - Go to Profile → Language Settings

2. **Select Language**
   - Tap on your preferred language card
   - Current language is marked with ✓

3. **Confirm Change**
   - A confirmation dialog will appear
   - Tap "Confirm" to proceed
   - Or tap "Cancel" to keep current language

4. **Apply Changes**
   - Success message will appear
   - You'll be automatically returned to Profile
   - App UI will update to new language

## Visual Guide

```
Profile Page
    ↓
[Language Settings] Button
    ↓
Language Settings Page
    ↓
┌─────────────────────────────┐
│ 🇬🇧 English                  │
│    English              ○   │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 🇸🇦 العربية                 │
│    Arabic               ✓   │ ← Currently Selected
└─────────────────────────────┘
    ↓
[Tap Different Language]
    ↓
Confirmation Dialog
    ↓
[Confirm] → Language Changed!
```

## Features

### Current Language Indicator
- ✓ Checkmark shows selected language
- Highlighted card border
- Elevated appearance

### Confirmation Dialog
- Prevents accidental changes
- Clear messaging
- Cancel option available

### Persistence
- Language choice is saved
- Persists across app restarts
- No need to change again

## Technical Details

### Default Language
- **Default**: Arabic (ar)
- Set on first app launch
- Can be changed anytime

### Language Codes
- English: `en`
- Arabic: `ar`

### Storage
- Saved in SharedPreferences
- Key: `app_language`

## Troubleshooting

### Language Not Changing
1. Ensure you confirmed the change
2. Check if success message appeared
3. Try restarting the app

### UI Not Updating
1. Language change requires app rebuild
2. Navigate away and back to see changes
3. Some cached screens may need refresh

### Language Reset to Default
1. Check if app data was cleared
2. Verify SharedPreferences is working
3. Re-select your preferred language

## For Developers

### Adding New Language

1. **Add ARB File**
   ```
   lib/l10n/app_[code].arb
   ```

2. **Update LanguageService**
   ```dart
   LanguageOption(
     code: 'fr',
     name: 'French',
     nativeName: 'Français',
     flag: '🇫🇷',
   )
   ```

3. **Update MaterialApp**
   ```dart
   supportedLocales: const [
     Locale('ar'),
     Locale('en'),
     Locale('fr'), // Add new locale
   ],
   ```

### Using Language in Code

```dart
// Get localized string
final text = AppLocalizations.of(context)?.translate('key') ?? 'Default';

// Get current locale
final locale = Localizations.localeOf(context);

// Check current language
if (locale.languageCode == 'ar') {
  // Arabic-specific logic
}
```

### Listening to Language Changes

```dart
BlocBuilder<LanguageBloc, LanguageState>(
  builder: (context, state) {
    if (state is LanguageLoaded) {
      final currentLocale = state.locale;
      // Use locale
    }
    return YourWidget();
  },
)
```

## Best Practices

### For Users
1. Choose language on first use
2. Restart app if UI doesn't update
3. Report any translation issues

### For Developers
1. Always use localization keys
2. Provide fallback text
3. Test both languages
4. Check RTL layout for Arabic
5. Verify all screens update

## Related Files

### Implementation
- `lib/features/settings/presentation/pages/language_settings_page.dart`
- `lib/core/services/language_service.dart`
- `lib/core/bloc/language_bloc.dart`

### Localization
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ar.arb`
- `lib/l10n/app_localizations.dart`

### Configuration
- `lib/main.dart` (MaterialApp setup)
- `lib/injection_container.dart` (DI setup)

## Localization Keys

### Language Settings
```json
{
  "languageSettings": "Language Settings",
  "appLanguage": "App Language",
  "selectLanguage": "Select Language",
  "changeLanguage": "Change Language",
  "languageChanged": "Language changed successfully"
}
```

### Language Names
```json
{
  "english": "English",
  "arabic": "Arabic"
}
```

## FAQ

**Q: Can I add more languages?**
A: Yes, follow the "Adding New Language" guide above.

**Q: Why does the app need to restart?**
A: Flutter rebuilds the widget tree to apply the new locale.

**Q: Is my language choice saved?**
A: Yes, it's saved in SharedPreferences and persists across restarts.

**Q: Can I change language without confirmation?**
A: No, confirmation prevents accidental changes.

**Q: What's the default language?**
A: Arabic (ar) is the default language.

**Q: Does RTL work for Arabic?**
A: Yes, the app supports RTL layout for Arabic.

## Support

For issues or questions:
1. Check this guide first
2. Review implementation files
3. Test in both languages
4. Report bugs with screenshots

---

**Last Updated**: Implementation of Task 19.4
**Version**: 1.0
**Status**: ✅ Complete
