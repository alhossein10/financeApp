/// Supabase configuration
/// 
/// ⚠️ IMPORTANT: The current Supabase project does not exist!
/// The app will work in OFFLINE MODE (local database only).
/// 
/// To enable cloud sync:
/// 1. Create new Supabase project at https://supabase.com
/// 2. Replace the values below with your new project credentials
/// 3. Run the SQL from SUPABASE_PROJECT_NOT_FOUND.md
/// 
/// See: SUPABASE_PROJECT_NOT_FOUND.md for complete setup guide
class SupabaseConfig {
  // TODO: Replace with your NEW Supabase project URL
  // Current project (adstyqccpfkcvbkxyoah) does not exist
  // Get new URL from: https://supabase.com/dashboard/project/your-project/settings/api
  static const String supabaseUrl = 'https://adstyqccpfkcvbkxyoah.supabase.co';
  
  // TODO: Replace with your NEW Supabase anon key
  // Get this from: https://supabase.com/dashboard/project/your-project/settings/api
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkc3R5cWNjcGZrY3Zia3h5b2FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NTg2MDIsImV4cCI6MjA3NjIzNDYwMn0.94PdvbIPiNo-u_KFRjyOnzF0ksclGBsoKbPxSaYQ9fE';
  
  // TODO: Replace with your NEW Supabase service key
  // For admin operations (keep secure!)
  static const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkc3R5cWNjcGZrY3Zia3h5b2FoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY1ODYwMiwiZXhwIjoyMDc2MjM0NjAyfQ.W7PCQQH05Jw9xBjZvYTkwVvMQNABnRzOt3GcqUp75ow';
  
  // Storage configuration
  static const String invoicesBucket = 'invoice-images';
  
  // Table names
  static const String userProfilesTable = 'user_profiles';
  static const String expensesTable = 'expenses';
  static const String incomingTable = 'incoming';
  static const String transfersTable = 'transfers';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Real-time configuration
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
}