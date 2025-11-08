/// Quick test script to check if Laravel API is reachable
/// Run with: dart run test_api_connection.dart

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Testing Laravel API Connection ===\n');
  
  // Your API URL
  const apiUrl = 'http://192.168.6.18:8000';
  
  print('Testing connection to: $apiUrl');
  print('');
  
  try {
    // Test 1: Basic connectivity
    print('Test 1: Basic HTTP GET...');
    final response = await http.get(
      Uri.parse(apiUrl),
    ).timeout(const Duration(seconds: 5));
    
    print('✅ Connection successful!');
    print('   Status: ${response.statusCode}');
    print('   Response length: ${response.body.length} bytes');
    print('');
    
    // Test 2: API health check
    print('Test 2: API health endpoint...');
    try {
      final healthResponse = await http.get(
        Uri.parse('$apiUrl/api/v1/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('✅ Health check successful!');
      print('   Status: ${healthResponse.statusCode}');
      print('   Response: ${healthResponse.body}');
    } catch (e) {
      print('⚠️  Health endpoint not available (this is OK if not implemented)');
      print('   Error: $e');
    }
    print('');
    
    // Test 3: Register endpoint
    print('Test 3: Register endpoint POST...');
    try {
      final registerResponse = await http.post(
        Uri.parse('$apiUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name":"Test","email":"test@test.com","password":"Test123!","password_confirmation":"Test123!"}',
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Register endpoint responded!');
      print('   Status: ${registerResponse.statusCode}');
      print('   Response: ${registerResponse.body.substring(0, 200)}...');
    } catch (e) {
      print('❌ Register endpoint failed');
      print('   Error: $e');
    }
    print('');
    
    print('=== Summary ===');
    print('✅ Laravel backend is reachable');
    print('✅ You can proceed with the Flutter app');
    
  } on SocketException catch (e) {
    print('❌ Connection failed: Cannot reach server');
    print('   Error: $e');
    print('');
    print('Possible causes:');
    print('1. Laravel is not running');
    print('2. Wrong IP address');
    print('3. Firewall blocking connection');
    print('4. Not on same network');
    print('');
    print('Solutions:');
    print('1. Start Laravel: cd financeApp-backend-main && php artisan serve --host=0.0.0.0');
    print('2. Check IP: ipconfig (Windows) or ifconfig (Mac/Linux)');
    print('3. Disable firewall temporarily');
    print('4. Connect to same WiFi network');
    
  } on TimeoutException catch (e) {
    print('❌ Connection timeout: Server not responding');
    print('   Error: $e');
    print('');
    print('Possible causes:');
    print('1. Laravel is slow or hung');
    print('2. Network is very slow');
    print('3. Server is overloaded');
    print('');
    print('Solutions:');
    print('1. Restart Laravel');
    print('2. Check Laravel logs: storage/logs/laravel.log');
    print('3. Check system resources');
    
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}

