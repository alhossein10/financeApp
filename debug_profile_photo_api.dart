import 'dart:convert';
import 'package:http/http.dart' as http;

/// Debug script to check what the API is actually returning for profile photos
/// Run this to see the exact field names in the API response
void main() async {
  print('🔍 Debugging Profile Photo API Response\n');
  
  // Replace with your actual API URL and token
  const apiUrl = 'YOUR_API_URL_HERE';
  const token = 'YOUR_TOKEN_HERE';
  
  print('Testing endpoints:');
  print('1. /api/superadmin/group/members');
  print('2. /api/admin/group/members');
  print('3. /api/profile\n');
  
  // Test SuperAdmin Group Members endpoint
  try {
    print('📡 Testing: GET /api/superadmin/group/members');
    final response = await http.get(
      Uri.parse('$apiUrl/api/superadmin/group/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Response structure: ${data.keys.toList()}');
      
      // Try to find the members array
      dynamic members;
      if (data['data'] != null) {
        if (data['data']['data'] is List) {
          members = data['data']['data'];
        } else if (data['data'] is List) {
          members = data['data'];
        }
      } else if (data['members'] != null) {
        if (data['members']['data'] is List) {
          members = data['members']['data'];
        } else if (data['members'] is List) {
          members = data['members'];
        }
      }
      
      if (members != null && members.isNotEmpty) {
        print('\n✅ Found ${members.length} members');
        print('First member fields: ${members[0].keys.toList()}');
        print('\nProfile photo fields in first member:');
        final member = members[0];
        if (member['profile_photo_url'] != null) {
          print('  ✓ profile_photo_url: ${member['profile_photo_url']}');
        }
        if (member['profile_image_url'] != null) {
          print('  ✓ profile_image_url: ${member['profile_image_url']}');
        }
        if (member['profile_photo'] != null) {
          print('  ✓ profile_photo: ${member['profile_photo']}');
        }
        if (member['avatar'] != null) {
          print('  ✓ avatar: ${member['avatar']}');
        }
        if (member['profile_photo_url'] == null && 
            member['profile_image_url'] == null && 
            member['profile_photo'] == null && 
            member['avatar'] == null) {
          print('  ❌ NO PROFILE PHOTO FIELD FOUND!');
        }
      } else {
        print('⚠️ No members found in response');
      }
    } else {
      print('❌ Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
  
  print('\n' + '='*60 + '\n');
  
  // Test Admin Group Members endpoint
  try {
    print('📡 Testing: GET /api/admin/group/members');
    final response = await http.get(
      Uri.parse('$apiUrl/api/admin/group/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Response structure: ${data.keys.toList()}');
      
      // Try to find the members array
      dynamic members;
      if (data['data'] != null) {
        if (data['data']['members'] != null) {
          if (data['data']['members']['data'] is List) {
            members = data['data']['members']['data'];
          } else if (data['data']['members'] is List) {
            members = data['data']['members'];
          }
        } else if (data['data']['data'] is List) {
          members = data['data']['data'];
        } else if (data['data'] is List) {
          members = data['data'];
        }
      }
      
      if (members != null && members.isNotEmpty) {
        print('\n✅ Found ${members.length} members');
        print('First member fields: ${members[0].keys.toList()}');
        print('\nProfile photo fields in first member:');
        final member = members[0];
        if (member['profile_photo_url'] != null) {
          print('  ✓ profile_photo_url: ${member['profile_photo_url']}');
        }
        if (member['profile_image_url'] != null) {
          print('  ✓ profile_image_url: ${member['profile_image_url']}');
        }
        if (member['profile_photo'] != null) {
          print('  ✓ profile_photo: ${member['profile_photo']}');
        }
        if (member['avatar'] != null) {
          print('  ✓ avatar: ${member['avatar']}');
        }
        if (member['profile_photo_url'] == null && 
            member['profile_image_url'] == null && 
            member['profile_photo'] == null && 
            member['avatar'] == null) {
          print('  ❌ NO PROFILE PHOTO FIELD FOUND!');
        }
      } else {
        print('⚠️ No members found in response');
      }
    } else {
      print('❌ Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
  
  print('\n' + '='*60 + '\n');
  
  // Test Profile endpoint
  try {
    print('📡 Testing: GET /api/profile');
    final response = await http.get(
      Uri.parse('$apiUrl/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Response structure: ${data.keys.toList()}');
      
      final user = data['data'] ?? data['user'] ?? data;
      print('\nProfile photo fields:');
      if (user['profile_photo_url'] != null) {
        print('  ✓ profile_photo_url: ${user['profile_photo_url']}');
      }
      if (user['profile_image_url'] != null) {
        print('  ✓ profile_image_url: ${user['profile_image_url']}');
      }
      if (user['profile_photo'] != null) {
        print('  ✓ profile_photo: ${user['profile_photo']}');
      }
      if (user['avatar'] != null) {
        print('  ✓ avatar: ${user['avatar']}');
      }
      if (user['profile_photo_url'] == null && 
          user['profile_image_url'] == null && 
          user['profile_photo'] == null && 
          user['avatar'] == null) {
        print('  ❌ NO PROFILE PHOTO FIELD FOUND!');
      }
    } else {
      print('❌ Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
  
  print('\n' + '='*60);
  print('\n📋 SUMMARY:');
  print('Check the output above to see which field name the backend is using.');
  print('Common field names: profile_photo_url, profile_image_url, profile_photo, avatar');
  print('\nIf the field is missing entirely, the backend needs to be updated to include it.');
}
