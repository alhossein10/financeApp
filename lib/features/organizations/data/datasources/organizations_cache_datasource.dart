import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/organization_dto.dart';
import '../models/department_dto.dart';

/// Organizations Cache Datasource
/// 
/// Handles local caching of organizations and departments data.
/// This allows the app to work offline and reduces API calls.
class OrganizationsCacheDatasource {
  static const String _organizationsKey = 'cached_organizations';
  static const String _departmentsKeyPrefix = 'cached_departments_';
  static const String _organizationsCacheTimeKey = 'organizations_cache_time';
  static const Duration _cacheDuration = Duration(hours: 24);

  final SharedPreferences _prefs;

  OrganizationsCacheDatasource({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  /// Cache organizations
  Future<void> cacheOrganizations(List<OrganizationDto> organizations) async {
    try {
      final jsonList = organizations.map((org) => org.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await _prefs.setString(_organizationsKey, jsonString);
      await _prefs.setInt(_organizationsCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      print('[OrganizationsCacheDatasource] ✅ Cached ${organizations.length} organizations');
    } catch (e) {
      print('[OrganizationsCacheDatasource] 🔴 Error caching organizations: $e');
    }
  }

  /// Get cached organizations
  Future<List<OrganizationDto>?> getCachedOrganizations() async {
    try {
      // Check if cache exists
      final jsonString = _prefs.getString(_organizationsKey);
      if (jsonString == null) {
        print('[OrganizationsCacheDatasource] ⚠️ No cached organizations found');
        return null;
      }

      // Check if cache is expired
      final cacheTime = _prefs.getInt(_organizationsCacheTimeKey);
      if (cacheTime != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();
        
        if (now.difference(cacheDate) > _cacheDuration) {
          print('[OrganizationsCacheDatasource] ⚠️ Organizations cache expired');
          return null;
        }
      }

      // Parse cached data
      final jsonList = jsonDecode(jsonString) as List;
      final organizations = jsonList
          .map((json) => OrganizationDto.fromJson(json as Map<String, dynamic>))
          .toList();

      print('[OrganizationsCacheDatasource] ✅ Retrieved ${organizations.length} cached organizations');
      return organizations;
    } catch (e) {
      print('[OrganizationsCacheDatasource] 🔴 Error retrieving cached organizations: $e');
      return null;
    }
  }

  /// Cache departments for a specific organization
  Future<void> cacheDepartments(int organizationId, List<DepartmentDto> departments) async {
    try {
      final key = '$_departmentsKeyPrefix$organizationId';
      final jsonList = departments.map((dept) => dept.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await _prefs.setString(key, jsonString);
      
      print('[OrganizationsCacheDatasource] ✅ Cached ${departments.length} departments for organization $organizationId');
    } catch (e) {
      print('[OrganizationsCacheDatasource] 🔴 Error caching departments: $e');
    }
  }

  /// Get cached departments for a specific organization
  Future<List<DepartmentDto>?> getCachedDepartments(int organizationId) async {
    try {
      final key = '$_departmentsKeyPrefix$organizationId';
      final jsonString = _prefs.getString(key);
      
      if (jsonString == null) {
        print('[OrganizationsCacheDatasource] ⚠️ No cached departments found for organization $organizationId');
        return null;
      }

      // Parse cached data
      final jsonList = jsonDecode(jsonString) as List;
      final departments = jsonList
          .map((json) => DepartmentDto.fromJson(json as Map<String, dynamic>))
          .toList();

      print('[OrganizationsCacheDatasource] ✅ Retrieved ${departments.length} cached departments for organization $organizationId');
      return departments;
    } catch (e) {
      print('[OrganizationsCacheDatasource] 🔴 Error retrieving cached departments: $e');
      return null;
    }
  }

  /// Clear all cached organizations and departments
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_organizationsKey);
      await _prefs.remove(_organizationsCacheTimeKey);
      
      // Remove all department caches
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_departmentsKeyPrefix)) {
          await _prefs.remove(key);
        }
      }
      
      print('[OrganizationsCacheDatasource] ✅ Cache cleared');
    } catch (e) {
      print('[OrganizationsCacheDatasource] 🔴 Error clearing cache: $e');
    }
  }
}
