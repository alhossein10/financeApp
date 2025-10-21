import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }
  
  /// Get platform-specific Firebase options
  /// This will be configured after Firebase project setup is complete
  static FirebaseOptions? _getFirebaseOptions() {
    // Firebase options will be automatically loaded from:
    // - Android: google-services.json
    // - iOS: GoogleService-Info.plist
    // - Web: firebase-config.js
    
    // For now, return null to use default configuration files
    return null;
  }
  
  /// Check if Firebase is initialized
  static bool get isInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
}
