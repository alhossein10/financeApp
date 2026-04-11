import 'package:dio/dio.dart';

/// Quick test script to verify SuperAdmin Analytics endpoint
/// Run with: dart run test_superadmin_analytics.dart
void main() async {
  print('🔵 Testing SuperAdmin Analytics Endpoint...\n');
  
  final dio = Dio();
  
  // Configure base URL - update this to match your backend
  final baseUrl = 'http://localhost:8000/api/v1';
  
  // Update this with a valid SuperAdmin token
  final token = 'YOUR_SUPERADMIN_TOKEN_HERE';
  
  try {
    print('📡 Making request to: $baseUrl/super-admin/analytics?period=all');
    print('🔑 Using Bearer token: ${token.substring(0, 20)}...\n');
    
    final response = await dio.get(
      '$baseUrl/super-admin/analytics',
      queryParameters: {'period': 'all'},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    print('✅ Response Status: ${response.statusCode}');
    print('📦 Response Data Type: ${response.data.runtimeType}');
    print('📦 Response Data:\n${response.data}\n');
    
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      print('🔍 Response Keys: ${data.keys.toList()}');
      
      if (data.containsKey('success')) {
        print('✅ Success: ${data['success']}');
      }
      
      if (data.containsKey('data')) {
        final analyticsData = data['data'];
        if (analyticsData is Map<String, dynamic>) {
          print('🔍 Analytics Data Keys: ${analyticsData.keys.toList()}');
          
          if (analyticsData.containsKey('admin_groups')) {
            final adminGroups = analyticsData['admin_groups'];
            if (adminGroups is List) {
              print('📊 Admin Groups Count: ${adminGroups.length}');
              
              if (adminGroups.isNotEmpty) {
                print('📊 First Admin Group: ${adminGroups[0]}');
              }
            }
          }
        }
      }
    }
    
    print('\n✅ Test completed successfully!');
    
  } on DioException catch (e) {
    print('❌ DioException occurred:');
    print('   Status Code: ${e.response?.statusCode}');
    print('   Message: ${e.message}');
    print('   Response Data: ${e.response?.data}');
  } catch (e, stackTrace) {
    print('❌ Error occurred: $e');
    print('   Stack Trace: $stackTrace');
  }
}
