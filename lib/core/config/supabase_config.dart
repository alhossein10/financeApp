/// Supabase configuration
/// 
/// Update these values with your Supabase project credentials
class SupabaseConfig {
  // TODO: Replace with your Supabase project URL
  // Get this from: https://supabase.com/dashboard/project/your-project/settings/api
  static const String supabaseUrl = 'https://adstyqccpfkcvbkxyoah.supabase.co';
  
  // TODO: Replace with your Supabase anon key
  // Get this from: https://supabase.com/dashboard/project/your-project/settings/api
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkc3R5cWNjcGZrY3Zia3h5b2FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NTg2MDIsImV4cCI6MjA3NjIzNDYwMn0.94PdvbIPiNo-u_KFRjyOnzF0ksclGBsoKbPxSaYQ9fE';
  
  // For admin operations (keep secure!)
  // Only use this for server-side operations or admin functions
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