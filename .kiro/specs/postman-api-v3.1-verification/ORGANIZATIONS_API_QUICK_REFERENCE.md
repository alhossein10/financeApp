# Organizations API Quick Reference

## Overview

Public API endpoints for fetching organizations and departments during user registration. These endpoints do NOT require authentication.

## API Endpoints

### Get All Organizations
```
GET /api/v1/organizations
```
- **Authentication:** None (public endpoint)
- **Returns:** List of organizations
- **Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Organization Name",
      "description": "Optional description",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### Get Departments for Organization
```
GET /api/v1/organizations/{id}/departments
```
- **Authentication:** None (public endpoint)
- **Parameters:** `{id}` - Organization ID
- **Returns:** List of departments
- **Response:**
```json
{
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "Department Name",
      "description": "Optional description",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Usage in Flutter

### Fetch Organizations
```dart
final organizationsApi = sl<OrganizationsApiDatasource>();
final organizations = await organizationsApi.getOrganizations();
```

### Fetch Departments
```dart
final organizationsApi = sl<OrganizationsApiDatasource>();
final departments = await organizationsApi.getDepartments(organizationId);
```

### With Caching
```dart
final organizationsCache = sl<OrganizationsCacheDatasource>();

// Try cache first
var organizations = await organizationsCache.getCachedOrganizations();

if (organizations == null) {
  // Fetch from API
  organizations = await organizationsApi.getOrganizations();
  
  // Cache the results
  await organizationsCache.cacheOrganizations(organizations);
}
```

## Cache Behavior

### Organizations Cache
- **Duration:** 24 hours
- **Key:** `cached_organizations`
- **Time Key:** `organizations_cache_time`
- **Behavior:** Expires after 24 hours, requires fresh fetch

### Departments Cache
- **Duration:** Indefinite
- **Key:** `cached_departments_{organizationId}`
- **Behavior:** Cached per organization, no expiration

### Clear Cache
```dart
await organizationsCache.clearCache();
```

## Registration UI Integration

### Organization Selection
1. Page loads → Fetch organizations (cache-first)
2. Display dropdown with organizations
3. User selects organization
4. Organization name stored in `organizationNameController`

### Department Selection
1. Organization selected → Fetch departments (cache-first)
2. Display dropdown with departments (if available)
3. User selects department (optional)
4. Department name stored in `departmentNameController`

### Fallback Behavior
- If API fails → Show error with retry button
- If no organizations → Show text input field
- If no departments → Show optional text input field

## Error Handling

### Network Errors
```dart
try {
  final organizations = await organizationsApi.getOrganizations();
} catch (e) {
  // Show error message
  // Offer retry button
  // Fall back to cached data if available
}
```

### Empty Results
```dart
if (organizations.isEmpty) {
  // Show text input field as fallback
  // Allow manual entry
}
```

## Testing

### Test Organizations Endpoint
```bash
curl http://localhost:8000/api/v1/organizations
```

### Test Departments Endpoint
```bash
curl http://localhost:8000/api/v1/organizations/1/departments
```

### Expected Responses
- **200 OK:** Success with data
- **404 Not Found:** Organization doesn't exist (departments endpoint)
- **500 Server Error:** Server error

## Bearer Token Behavior

These endpoints are PUBLIC and do NOT require Bearer token:
- BearerTokenInterceptor automatically skips token injection
- No Authorization header added
- Works without authentication

## Key Files

### DTOs
- `lib/features/organizations/data/models/organization_dto.dart`
- `lib/features/organizations/data/models/department_dto.dart`

### Datasources
- `lib/features/organizations/data/datasources/organizations_api_datasource.dart`
- `lib/features/organizations/data/datasources/organizations_cache_datasource.dart`

### UI
- `lib/features/auth/presentation/pages/register_page.dart`

### Dependency Injection
- `lib/injection_container.dart`

## Common Issues

### Issue: Organizations not loading
**Solution:** Check API endpoint is accessible and returns valid JSON

### Issue: Cache not working
**Solution:** Verify SharedPreferences is registered in injection container

### Issue: Bearer token error on public endpoints
**Solution:** Verify BearerTokenInterceptor correctly identifies public endpoints

### Issue: Departments not loading after organization selection
**Solution:** Check organization ID is valid and departments endpoint returns data

## Best Practices

1. **Always try cache first** for better performance
2. **Handle empty results gracefully** with fallback UI
3. **Show loading indicators** during API calls
4. **Provide retry buttons** on errors
5. **Cache API responses** to reduce network calls
6. **Support offline mode** with cached data
