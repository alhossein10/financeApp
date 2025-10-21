/// PocketBase configuration
/// 
/// IMPORTANT: Update [baseUrl] with your deployed PocketBase server URL
/// 
/// For sync to work between devices:
/// 1. Deploy PocketBase to a cloud server (Fly.io, Render, etc.)
/// 2. Update baseUrl with the deployed URL
/// 3. Ensure both User and Admin apps use the SAME URL
/// 
/// Local development (127.0.0.1) will ONLY work on the same device!
class PocketBaseConfig {
  // TODO: Replace with your deployed PocketBase URL
  // Examples:
  // - Fly.io: 'https://finance-app-backend.fly.dev'
  // - Render: 'https://finance-app-backend.onrender.com'
  // - Custom server: 'https://your-domain.com'
  
  static const String baseUrl = 'http://127.0.0.1:8090'; // ⚠️ LOCAL ONLY - Change this!
  
  static const String apiUrl = '$baseUrl/api';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
