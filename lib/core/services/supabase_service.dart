/// DEPRECATED: This file is kept for backward compatibility only
/// 
/// This app now uses Laravel backend instead of Supabase.
/// All authentication and data operations go through Laravel API.
/// 
/// This stub prevents compilation errors in old code that might
/// still reference SupabaseService. Remove this file once all
/// references are cleaned up.
library;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  @Deprecated('Use LaravelAuthService instead')
  Future<void> initialize() async {
    // No-op - Supabase not used in Laravel version
  }
  
  @Deprecated('Use LaravelAuthService.logout() instead')
  Future<void> signOut() async {
    // No-op - Supabase not used in Laravel version
  }
}
