import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app language preferences
class LanguageService {
  static const String _languageKey = 'app_language';
  
  final SharedPreferences _prefs;
  
  LanguageService(this._prefs);
  
  /// Get the saved language code, or null if not set
  String? getSavedLanguageCode() {
    return _prefs.getString(_languageKey);
  }
  
  /// Get the saved locale, or device locale if not set
  Locale getSavedLocale() {
    final languageCode = getSavedLanguageCode();
    if (languageCode != null) {
      return Locale(languageCode);
    }
    // Default to Arabic as per the app's default
    return const Locale('ar');
  }
  
  /// Save the selected language
  Future<bool> saveLanguage(String languageCode) async {
    return await _prefs.setString(_languageKey, languageCode);
  }
  
  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    return ['en', 'ar'].contains(languageCode);
  }
  
  /// Get list of supported languages
  List<LanguageOption> getSupportedLanguages() {
    return [
      LanguageOption(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        flag: '🇬🇧',
      ),
      LanguageOption(
        code: 'ar',
        name: 'Arabic',
        nativeName: 'العربية',
        flag: '🇸🇦',
      ),
    ];
  }
}

/// Model for language options
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  
  LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
