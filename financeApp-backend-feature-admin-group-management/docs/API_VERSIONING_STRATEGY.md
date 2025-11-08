# API Versioning Strategy

## Overview

The Finance Management API uses URL-based versioning to ensure backward compatibility and smooth transitions between API versions. This document outlines the versioning strategy, deprecation policy, and migration guidelines.

## Versioning Scheme

### URL-Based Versioning

All API endpoints are versioned using URL path prefixes:

```
https://api.example.com/api/v1/expenses
https://api.example.com/api/v2/expenses
```

**Format**: `/api/v{major_version}/{resource}`

### Version Format

- **Major Version**: Incremented for breaking changes (v1, v2, v3, etc.)
- **Minor/Patch Updates**: Handled within the same major version without URL changes
- **Current Version**: v1

## Supported Versions

### Active Versions

| Version | Status | Release Date | End of Life | Documentation |
|---------|--------|--------------|-------------|---------------|
| v1      | Stable | 2025-10-22   | TBD         | [API Docs](/api/documentation) |

### Deprecated Versions

Currently, no versions are deprecated.

## Version Negotiation

### Automatic Version Detection

The API automatically detects the requested version from the URL path:

```http
GET /api/v1/expenses HTTP/1.1
Host: api.example.com
Authorization: Bearer {token}
```

### Unsupported Version Response

When requesting an unsupported version, the API returns a 404 response with helpful information:

```json
{
  "success": false,
  "message": "API version 'v2' is not supported.",
  "error_code": "UNSUPPORTED_API_VERSION",
  "requested_version": "v2",
  "current_version": "v1",
  "supported_versions": ["v1"],
  "documentation": "https://api.example.com/api/documentation",
  "endpoints": {
    "v1": "https://api.example.com/api/v1"
  }
}
```

### Version Discovery

To discover available API versions, make a request to the base API endpoint:

```http
GET /api HTTP/1.1
Host: api.example.com
```

Response:

```json
{
  "name": "Finance Management API",
  "current_version": "v1",
  "supported_versions": ["v1"],
  "documentation": "https://api.example.com/api/documentation",
  "endpoints": {
    "v1": "https://api.example.com/api/v1"
  }
}
```

## Deprecation Policy

### Deprecation Timeline

When a new major version is released:

1. **Announcement**: Deprecation is announced 6 months before end-of-life
2. **Warning Period**: Deprecated version continues to work with warning headers
3. **End of Life**: Version is removed after 6-month grace period

### Deprecation Headers

When using a deprecated API version, responses include warning headers:

```http
HTTP/1.1 200 OK
X-API-Deprecation-Warning: API version v1 is deprecated and will be removed on 2026-04-22. Please migrate to v2.
X-API-Deprecation-EOL: 2026-04-22
X-API-Current-Version: v2
Content-Type: application/json
```

### Deprecation Notifications

Clients using deprecated versions will receive:

- **Response Headers**: Every API response includes deprecation warnings
- **Email Notifications**: Registered users receive email alerts
- **Dashboard Alerts**: Admin dashboard shows deprecation warnings
- **Documentation Updates**: Migration guides published in advance

## Breaking Changes

### What Constitutes a Breaking Change

Breaking changes require a new major version:

- Removing or renaming endpoints
- Removing or renaming request/response fields
- Changing field data types
- Changing authentication mechanisms
- Changing error response formats
- Removing support for previously supported features

### Non-Breaking Changes

These changes can be made within the same major version:

- Adding new endpoints
- Adding new optional request parameters
- Adding new response fields
- Adding new error codes
- Performance improvements
- Bug fixes
- Security patches

## Backward Compatibility

### Guarantees

Within a major version, we guarantee:

1. **Endpoint Stability**: Existing endpoints remain functional
2. **Field Stability**: Existing fields maintain their data types and meanings
3. **Authentication**: Authentication mechanisms remain unchanged
4. **Error Codes**: Existing error codes maintain their meanings

### Best Practices for Clients

To ensure smooth version transitions:

1. **Ignore Unknown Fields**: Clients should ignore new fields they don't recognize
2. **Handle New Error Codes**: Implement graceful handling for unknown error codes
3. **Version Pinning**: Always specify the API version in requests
4. **Monitor Headers**: Check for deprecation warning headers
5. **Test Early**: Test against new versions during the deprecation period

## Migration Guide

### Preparing for Version Migration

1. **Review Changelog**: Check the version changelog for breaking changes
2. **Update Dependencies**: Ensure SDKs and libraries support the new version
3. **Test in Staging**: Test your integration against the new version
4. **Update Documentation**: Update internal documentation and code comments
5. **Deploy Gradually**: Use feature flags for gradual rollout

### Migration Checklist

- [ ] Review breaking changes in new version
- [ ] Update API base URL to new version
- [ ] Update request/response models
- [ ] Update error handling for new error codes
- [ ] Test all API integrations
- [ ] Update monitoring and logging
- [ ] Deploy to staging environment
- [ ] Perform integration testing
- [ ] Deploy to production
- [ ] Monitor for errors

### Example Migration

**Before (v1):**
```javascript
const response = await fetch('https://api.example.com/api/v1/expenses', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

**After (v2):**
```javascript
const response = await fetch('https://api.example.com/api/v2/expenses', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

## Version Lifecycle

### Development Phase

- New features developed in feature branches
- Breaking changes tracked in changelog
- Beta testing with selected partners

### Release Phase

- Version announced with migration guide
- Documentation published
- SDKs updated and released

### Maintenance Phase

- Bug fixes and security patches
- Performance improvements
- Non-breaking feature additions

### Deprecation Phase

- Deprecation announced 6 months in advance
- Warning headers added to responses
- Migration support provided

### End of Life

- Version removed from production
- Requests return 404 with supported versions
- Historical documentation archived

## Technical Implementation

### Middleware

The `ApiVersionNegotiation` middleware handles version detection and validation:

```php
// bootstrap/app.php
$middleware->api(append: [
    \App\Http\Middleware\ApiVersionNegotiation::class,
]);
```

### Route Configuration

Versioned routes are defined in separate files:

```php
// bootstrap/app.php
Route::prefix('api/v1')
    ->middleware('api')
    ->group(base_path('routes/api_v1.php'));
```

### Adding a New Version

To add a new API version:

1. Create new route file: `routes/api_v{version}.php`
2. Update `ApiVersionNegotiation::SUPPORTED_VERSIONS`
3. Update `ApiVersionNegotiation::CURRENT_VERSION`
4. Register routes in `bootstrap/app.php`
5. Update API documentation
6. Announce the new version

### Deprecating a Version

To deprecate an API version:

1. Add version to `ApiVersionNegotiation::DEPRECATED_VERSIONS` with EOL date
2. Update documentation with migration guide
3. Send notifications to API users
4. Monitor usage metrics
5. Remove version after EOL date

## Monitoring and Analytics

### Version Usage Tracking

Track API version usage through:

- Request logs with version information
- Analytics dashboard showing version distribution
- Alerts for deprecated version usage spikes

### Metrics to Monitor

- Requests per version
- Error rates per version
- Response times per version
- Deprecated version usage trends
- Migration completion rates

## Support and Resources

### Documentation

- [API Documentation](/api/documentation)
- [OpenAPI Specification](/api/documentation)
- [Migration Guides](/docs/migrations)

### Support Channels

- GitHub Issues: Report bugs and request features
- Email Support: api-support@example.com
- Developer Forum: forum.example.com

### Changelog

All version changes are documented in the [CHANGELOG.md](../CHANGELOG.md) file.

## Frequently Asked Questions

### Q: Can I use multiple API versions simultaneously?

Yes, you can make requests to different versions in the same application. Each request specifies its version in the URL.

### Q: What happens if I don't specify a version?

Requests to `/api/` without a version will receive information about available versions. All functional endpoints require a version.

### Q: How long are deprecated versions supported?

Deprecated versions are supported for 6 months after deprecation announcement.

### Q: Will my authentication tokens work across versions?

Yes, authentication tokens are version-agnostic and work across all supported versions.

### Q: How do I know when a new version is released?

New versions are announced via:
- Email notifications to registered users
- API changelog updates
- Developer blog posts
- Response headers on deprecated versions

### Q: Can I request features to be backported to older versions?

Security fixes and critical bug fixes may be backported. New features are typically only added to the current version.

## Version History

### v1 (Current)

- **Release Date**: 2025-10-22
- **Status**: Stable
- **Features**: Complete finance management API with authentication, expenses, transfers, incoming funds, fund box, admin dashboard, sync, exports, and audit logging

## Contact

For questions about API versioning, contact:
- Email: api-support@example.com
- Documentation: https://api.example.com/api/documentation
