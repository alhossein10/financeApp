# Requirements Document

## Introduction

This feature migrates the Flutter finance application from its current SQLite/Supabase/PocketBase architecture to a Laravel-based REST API backend. The system will replace all local-only and cloud sync mechanisms with direct API communication to a centralized Laravel server, providing robust authentication, real-time data synchronization, role-based access control, and comprehensive financial data management.

## Glossary

- **Laravel Backend**: The RESTful API server built with Laravel 11 that handles all business logic, data persistence, and authentication
- **Flutter App**: The mobile/desktop application that consumes the Laravel API
- **Sanctum Token**: Laravel Sanctum authentication token used for API requests
- **Admin User**: User with role='admin' who has access to all system data and administrative features
- **Regular User**: User with role='user' who can only access their own data
- **Sync Status**: The synchronization state of a record (pending, syncing, synced, failed)
- **Batch Sync**: Synchronizing multiple records in a single API request
- **Audit Log**: System-generated log of all user actions for security and compliance

## Requirements

### Requirement 1: Laravel Backend Integration

**User Story:** As a developer, I want to integrate the Flutter app with the Laravel backend, so that all data operations are handled by a centralized API server.

#### Acceptance Criteria

1. WHEN the application initializes THEN the system SHALL configure the Laravel API base URL from environment configuration
2. WHEN making API requests THEN the system SHALL use HTTP client with proper headers (Content-Type, Accept, Authorization)
3. WHEN API requests fail THEN the system SHALL implement retry logic with exponential backoff
4. WHEN network is unavailable THEN the system SHALL queue requests locally and retry when connectivity is restored
5. WHEN API returns error responses THEN the system SHALL parse and display user-friendly error messages
6. WHEN the app starts THEN the system SHALL validate API connectivity and version compatibility
7. IF API version is incompatible THEN the system SHALL prompt user to update the application

### Requirement 2: Authentication with Laravel Sanctum

**User Story:** As a user, I want to authenticate with the Laravel backend using email and password, so that I can securely access my financial data.

#### Acceptance Criteria

1. WHEN a user registers THEN the system SHALL send POST request to /api/v1/auth/register with name, email, password
2. WHEN registration succeeds THEN the system SHALL store the Sanctum token securely in device storage
3. WHEN a user logs in THEN the system SHALL send POST request to /api/v1/auth/login with email and password
4. WHEN login succeeds THEN the system SHALL store user data and token locally
5. WHEN making authenticated requests THEN the system SHALL include "Bearer {token}" in Authorization header
6. WHEN token expires THEN the system SHALL automatically refresh the token using /api/v1/auth/refresh
7. WHEN a user logs out THEN the system SHALL revoke the token via /api/v1/auth/logout and clear local storage
8. IF authentication fails THEN the system SHALL display appropriate error messages and redirect to login

### Requirement 3: Remove SQLite Database

**User Story:** As a developer, I want to remove the SQLite database layer, so that all data is managed by the Laravel backend.

#### Acceptance Criteria

1. WHEN migrating to Laravel backend THEN the system SHALL remove all SQLite database files and dependencies
2. WHEN the app needs data THEN the system SHALL fetch it from Laravel API instead of local database
3. WHEN removing SQLite THEN the system SHALL delete lib/data/db.dart and related database files
4. WHEN removing SQLite THEN the system SHALL remove sqflite and drift packages from pubspec.yaml
5. WHEN removing SQLite THEN the system SHALL update all data sources to use API repositories
6. WHEN removing SQLite THEN the system SHALL remove database migration and initialization code
7. IF users have existing local data THEN the system SHALL provide migration tool to export and upload to Laravel

### Requirement 4: Remove Supabase Integration

**User Story:** As a developer, I want to remove Supabase integration, so that the app uses only the Laravel backend.

#### Acceptance Criteria

1. WHEN removing Supabase THEN the system SHALL delete lib/core/services/supabase_service.dart
2. WHEN removing Supabase THEN the system SHALL delete lib/core/services/supabase_sync_service.dart
3. WHEN removing Supabase THEN the system SHALL delete lib/core/config/supabase_config.dart
4. WHEN removing Supabase THEN the system SHALL remove supabase_flutter package from pubspec.yaml
5. WHEN removing Supabase THEN the system SHALL remove all Supabase-related environment variables
6. WHEN removing Supabase THEN the system SHALL update dependency injection to remove Supabase services
7. IF Supabase storage is used THEN the system SHALL migrate file storage to Laravel backend

### Requirement 5: Remove PocketBase Integration

**User Story:** As a developer, I want to remove PocketBase integration, so that the app uses only the Laravel backend.

#### Acceptance Criteria

1. WHEN removing PocketBase THEN the system SHALL delete lib/core/services/cloud_sync_service.dart
2. WHEN removing PocketBase THEN the system SHALL delete lib/core/services/pocketbase_storage_service.dart
3. WHEN removing PocketBase THEN the system SHALL remove pocketbase package from pubspec.yaml
4. WHEN removing PocketBase THEN the system SHALL remove all PocketBase-related configuration files
5. WHEN removing PocketBase THEN the system SHALL update dependency injection to remove PocketBase services
6. WHEN removing PocketBase THEN the system SHALL remove PocketBase deployment documentation
7. IF PocketBase collections exist THEN the system SHALL provide data migration guide to Laravel

### Requirement 6: Expense Management via API

**User Story:** As a user, I want to manage my expenses through the Laravel API, so that my data is centrally stored and accessible.

#### Acceptance Criteria

1. WHEN creating an expense THEN the system SHALL send POST request to /api/v1/expenses with expense data
2. WHEN fetching expenses THEN the system SHALL send GET request to /api/v1/expenses with pagination parameters
3. WHEN updating an expense THEN the system SHALL send PUT request to /api/v1/expenses/{id} with updated data
4. WHEN deleting an expense THEN the system SHALL send DELETE request to /api/v1/expenses/{id}
5. WHEN uploading invoice image THEN the system SHALL send multipart POST to /api/v1/expenses/{id}/invoice
6. WHEN downloading invoice THEN the system SHALL send GET request to /api/v1/expenses/{id}/invoice
7. WHEN filtering expenses THEN the system SHALL include query parameters (start_date, end_date, sync_status)
8. IF API request fails THEN the system SHALL retry with exponential backoff and show error to user

### Requirement 7: Transfer Management via API

**User Story:** As a user, I want to manage money transfers through the Laravel API, so that transfer records are synchronized across devices.

#### Acceptance Criteria

1. WHEN creating a transfer THEN the system SHALL send POST request to /api/v1/transfers with transfer data
2. WHEN fetching transfers THEN the system SHALL send GET request to /api/v1/transfers with pagination
3. WHEN updating a transfer THEN the system SHALL send PUT request to /api/v1/transfers/{id}
4. WHEN deleting a transfer THEN the system SHALL send DELETE request to /api/v1/transfers/{id}
5. WHEN adding exchange information THEN the system SHALL send POST to /api/v1/transfers/{id}/exchange
6. WHEN viewing transfer details THEN the system SHALL include exchange information in response
7. WHEN filtering transfers THEN the system SHALL support date range filtering
8. IF transfer has multiple exchanges THEN the system SHALL display all exchange records

### Requirement 8: Incoming Funds Management via API

**User Story:** As a user, I want to track incoming funds through the Laravel API, so that income records are properly managed.

#### Acceptance Criteria

1. WHEN creating incoming transaction THEN the system SHALL send POST request to /api/v1/incoming
2. WHEN fetching incoming transactions THEN the system SHALL send GET request to /api/v1/incoming
3. WHEN updating incoming transaction THEN the system SHALL send PUT request to /api/v1/incoming/{id}
4. WHEN deleting incoming transaction THEN the system SHALL send DELETE request to /api/v1/incoming/{id}
5. WHEN filtering incoming THEN the system SHALL support date range and pagination
6. WHEN displaying incoming list THEN the system SHALL show description, amount, and date
7. WHEN calculating totals THEN the system SHALL sum amounts from API response
8. IF API is unavailable THEN the system SHALL show cached data with sync indicator

### Requirement 9: Fund Box Management (Admin Only)

**User Story:** As an administrator, I want to manage the central fund box through the Laravel API, so that I can track overall balance.

#### Acceptance Criteria

1. WHEN admin views fund box THEN the system SHALL send GET request to /api/v1/fund-box
2. WHEN admin updates balance THEN the system SHALL send PUT request to /api/v1/fund-box with new balance
3. WHEN non-admin user accesses fund box THEN the system SHALL receive 403 Forbidden response
4. WHEN fund box is updated THEN the system SHALL display success message and updated balance
5. WHEN viewing fund box THEN the system SHALL show last calculated timestamp
6. WHEN fund box API fails THEN the system SHALL display error message
7. IF user is not admin THEN the system SHALL hide fund box UI elements

### Requirement 10: Admin Dashboard Integration

**User Story:** As an administrator, I want to view system-wide statistics through the Laravel API, so that I can monitor application usage.

#### Acceptance Criteria

1. WHEN admin opens dashboard THEN the system SHALL send GET request to /api/v1/admin/dashboard/stats
2. WHEN viewing user activity THEN the system SHALL send GET request to /api/v1/admin/dashboard/users
3. WHEN viewing expense summaries THEN the system SHALL send GET request to /api/v1/admin/dashboard/expenses
4. WHEN viewing analytics THEN the system SHALL send GET request to /api/v1/admin/dashboard/analytics with date range
5. WHEN dashboard loads THEN the system SHALL display total users, expenses, transfers, and fund box balance
6. WHEN viewing user list THEN the system SHALL show each user's expense count and last activity
7. WHEN filtering analytics THEN the system SHALL support custom date ranges
8. IF user is not admin THEN the system SHALL not display dashboard navigation

### Requirement 11: File Upload and Storage

**User Story:** As a user, I want to upload invoice images to the Laravel backend, so that my receipts are stored securely.

#### Acceptance Criteria

1. WHEN uploading invoice THEN the system SHALL compress image before upload to reduce bandwidth
2. WHEN sending file THEN the system SHALL use multipart/form-data content type
3. WHEN upload succeeds THEN the system SHALL store file path returned from API
4. WHEN downloading invoice THEN the system SHALL use encrypted file path from API
5. WHEN deleting invoice THEN the system SHALL send DELETE request to remove file from server
6. WHEN upload fails THEN the system SHALL retry up to 3 times with exponential backoff
7. WHEN displaying invoice THEN the system SHALL cache downloaded images locally
8. IF file size exceeds 10MB THEN the system SHALL compress further or show error

### Requirement 12: Data Export via API

**User Story:** As a user, I want to export my financial data through the Laravel API, so that I can generate reports.

#### Acceptance Criteria

1. WHEN requesting PDF export THEN the system SHALL send POST to /api/v1/export/expenses/pdf with date range
2. WHEN requesting Excel export THEN the system SHALL send POST to /api/v1/export/expenses/excel
3. WHEN export is queued THEN the system SHALL receive export_id and status "processing"
4. WHEN checking export status THEN the system SHALL poll GET /api/v1/export/{id}/status
5. WHEN export completes THEN the system SHALL download file from /api/v1/export/{id}/download
6. WHEN admin exports system-wide THEN the system SHALL use /api/v1/export/system-wide endpoint
7. WHEN export fails THEN the system SHALL display error message with retry option
8. IF export takes long THEN the system SHALL show progress indicator

### Requirement 13: Batch Synchronization

**User Story:** As a user, I want to synchronize multiple records in a single request, so that sync is efficient and fast.

#### Acceptance Criteria

1. WHEN app has pending changes THEN the system SHALL batch them into single /api/v1/sync/batch request
2. WHEN sending batch THEN the system SHALL include record type, action (create/update/delete), and data
3. WHEN batch succeeds THEN the system SHALL update local records with server IDs and timestamps
4. WHEN batch partially fails THEN the system SHALL retry failed records individually
5. WHEN receiving batch response THEN the system SHALL process results array and update sync status
6. WHEN conflict occurs THEN the system SHALL use /api/v1/sync/resolve endpoint
7. WHEN resolving conflict THEN the system SHALL apply server_wins or client_wins strategy
8. IF batch size exceeds limit THEN the system SHALL split into multiple requests

### Requirement 14: Offline Support and Queueing

**User Story:** As a user, I want the app to work offline and sync when online, so that I can use it without internet.

#### Acceptance Criteria

1. WHEN network is unavailable THEN the system SHALL queue all create/update/delete operations locally
2. WHEN network becomes available THEN the system SHALL automatically process queued operations
3. WHEN displaying data offline THEN the system SHALL show cached data with offline indicator
4. WHEN creating record offline THEN the system SHALL assign temporary local ID
5. WHEN syncing queued operations THEN the system SHALL replace temporary IDs with server IDs
6. WHEN sync fails THEN the system SHALL keep operation in queue and retry later
7. WHEN viewing sync status THEN the system SHALL show pending, syncing, synced, or failed
8. IF queue grows large THEN the system SHALL batch operations for efficiency

### Requirement 15: Error Handling and User Feedback

**User Story:** As a user, I want clear error messages when API requests fail, so that I understand what went wrong.

#### Acceptance Criteria

1. WHEN API returns 401 THEN the system SHALL redirect to login and clear stored token
2. WHEN API returns 403 THEN the system SHALL display "Access denied" message
3. WHEN API returns 404 THEN the system SHALL display "Resource not found" message
4. WHEN API returns 422 THEN the system SHALL display validation errors for each field
5. WHEN API returns 429 THEN the system SHALL wait for Retry-After duration before retrying
6. WHEN API returns 500 THEN the system SHALL display "Server error, please try again" message
7. WHEN network timeout occurs THEN the system SHALL display "Connection timeout" and retry option
8. IF error is unrecoverable THEN the system SHALL log error details for debugging

### Requirement 16: Role-Based Access Control

**User Story:** As a user, I want the app to respect my role permissions, so that I only see features I'm authorized to use.

#### Acceptance Criteria

1. WHEN user logs in THEN the system SHALL store user role from API response
2. WHEN user is admin THEN the system SHALL show admin dashboard, fund box, and audit logs
3. WHEN user is regular user THEN the system SHALL hide admin-only features
4. WHEN accessing admin endpoint THEN the system SHALL check role before making request
5. WHEN role check fails THEN the system SHALL display "Insufficient permissions" message
6. WHEN viewing data THEN the system SHALL only show user's own records (unless admin)
7. WHEN admin views data THEN the system SHALL show all users' records
8. IF role changes THEN the system SHALL refresh UI to show/hide features accordingly

### Requirement 17: Password Management

**User Story:** As a user, I want to reset my password through the Laravel API, so that I can recover my account.

#### Acceptance Criteria

1. WHEN user forgets password THEN the system SHALL send POST to /api/v1/auth/forgot-password with email
2. WHEN reset link is sent THEN the system SHALL display "Check your email" message
3. WHEN user clicks reset link THEN the system SHALL extract token from URL
4. WHEN submitting new password THEN the system SHALL send POST to /api/v1/auth/reset-password
5. WHEN password reset succeeds THEN the system SHALL redirect to login with success message
6. WHEN changing password THEN the system SHALL send PUT to /api/v1/profile/password
7. WHEN password change succeeds THEN the system SHALL display success message
8. IF reset token is invalid THEN the system SHALL display "Invalid or expired token" error

### Requirement 18: User Profile Management

**User Story:** As a user, I want to manage my profile through the Laravel API, so that I can update my information.

#### Acceptance Criteria

1. WHEN viewing profile THEN the system SHALL send GET request to /api/v1/profile
2. WHEN updating profile THEN the system SHALL send PUT request to /api/v1/profile with name and email
3. WHEN profile update succeeds THEN the system SHALL update local user data and display success
4. WHEN deleting account THEN the system SHALL send DELETE request to /api/v1/profile
5. WHEN account deletion succeeds THEN the system SHALL clear all local data and redirect to welcome
6. WHEN viewing profile THEN the system SHALL display user statistics (expense count, total amounts)
7. WHEN profile API fails THEN the system SHALL display error message
8. IF email is changed THEN the system SHALL require re-authentication

### Requirement 19: Audit Logging (Admin Only)

**User Story:** As an administrator, I want to view audit logs through the Laravel API, so that I can track system activity.

#### Acceptance Criteria

1. WHEN admin views audit logs THEN the system SHALL send GET request to /api/v1/audit-logs
2. WHEN filtering logs THEN the system SHALL include query parameters (user_id, action, resource_type, date range)
3. WHEN viewing log details THEN the system SHALL send GET request to /api/v1/audit-logs/{id}
4. WHEN displaying logs THEN the system SHALL show user name, action, resource type, IP address, and timestamp
5. WHEN paginating logs THEN the system SHALL support page and per_page parameters
6. WHEN logs load THEN the system SHALL display in reverse chronological order
7. WHEN non-admin accesses logs THEN the system SHALL receive 403 Forbidden
8. IF logs are extensive THEN the system SHALL implement infinite scroll pagination

### Requirement 20: API Configuration Management

**User Story:** As a developer, I want to configure API settings easily, so that the app can connect to different environments.

#### Acceptance Criteria

1. WHEN building for development THEN the system SHALL use development API URL from environment config
2. WHEN building for production THEN the system SHALL use production API URL
3. WHEN configuring API THEN the system SHALL support base URL, timeout, and retry settings
4. WHEN API version changes THEN the system SHALL update version prefix in all endpoints
5. WHEN debugging THEN the system SHALL log all API requests and responses
6. WHEN in production THEN the system SHALL disable debug logging
7. WHEN API URL is invalid THEN the system SHALL display configuration error on startup
8. IF multiple environments exist THEN the system SHALL support environment-specific configs

### Requirement 21: Token Management and Refresh

**User Story:** As a user, I want my session to remain active, so that I don't have to log in frequently.

#### Acceptance Criteria

1. WHEN token is about to expire THEN the system SHALL automatically refresh it using /api/v1/auth/refresh
2. WHEN refresh succeeds THEN the system SHALL store new token and continue operations
3. WHEN refresh fails THEN the system SHALL redirect to login and clear stored credentials
4. WHEN app starts THEN the system SHALL validate stored token by calling /api/v1/auth/me
5. WHEN token is invalid THEN the system SHALL redirect to login
6. WHEN user is inactive THEN the system SHALL keep token valid for 30 days
7. WHEN token expires THEN the system SHALL show "Session expired, please log in" message
8. IF refresh is in progress THEN the system SHALL queue API requests until refresh completes

### Requirement 22: Data Migration from Old System

**User Story:** As a user with existing data, I want to migrate my data to the Laravel backend, so that I don't lose my records.

#### Acceptance Criteria

1. WHEN migration starts THEN the system SHALL export all local SQLite data to JSON format
2. WHEN uploading data THEN the system SHALL use batch sync endpoint to create records
3. WHEN migration is in progress THEN the system SHALL display progress indicator
4. WHEN migration completes THEN the system SHALL verify all records were uploaded successfully
5. WHEN migration fails THEN the system SHALL retry failed records and log errors
6. WHEN migration succeeds THEN the system SHALL delete local SQLite database
7. WHEN user has Supabase data THEN the system SHALL provide export tool from Supabase
8. IF migration is interrupted THEN the system SHALL resume from last successful record

### Requirement 23: Rate Limiting Handling

**User Story:** As a user, I want the app to handle rate limits gracefully, so that I can continue using it without errors.

#### Acceptance Criteria

1. WHEN API returns 429 THEN the system SHALL read Retry-After header
2. WHEN rate limited THEN the system SHALL wait specified duration before retrying
3. WHEN displaying rate limit THEN the system SHALL show "Too many requests, please wait" message
4. WHEN retry time is long THEN the system SHALL display countdown timer
5. WHEN rate limit clears THEN the system SHALL automatically retry failed request
6. WHEN multiple requests are rate limited THEN the system SHALL queue them and retry in order
7. WHEN user triggers many actions THEN the system SHALL throttle requests client-side
8. IF rate limits are frequent THEN the system SHALL implement request batching

### Requirement 24: Caching Strategy

**User Story:** As a user, I want the app to cache data intelligently, so that it loads quickly and uses less bandwidth.

#### Acceptance Criteria

1. WHEN fetching data THEN the system SHALL cache responses locally with expiration time
2. WHEN cache is valid THEN the system SHALL use cached data and skip API request
3. WHEN cache expires THEN the system SHALL fetch fresh data from API
4. WHEN data is modified THEN the system SHALL invalidate related cache entries
5. WHEN app starts THEN the system SHALL load from cache while fetching fresh data in background
6. WHEN network is slow THEN the system SHALL show cached data with "Updating..." indicator
7. WHEN cache grows large THEN the system SHALL implement LRU eviction policy
8. IF cache is corrupted THEN the system SHALL clear cache and fetch fresh data

### Requirement 25: Multi-Currency Support

**User Story:** As a user, I want to track expenses in multiple currencies, so that I can manage international transactions.

#### Acceptance Criteria

1. WHEN creating expense THEN the system SHALL support price_usd, price_syp, and price_try fields
2. WHEN displaying expenses THEN the system SHALL show all non-null currency amounts
3. WHEN filtering by currency THEN the system SHALL send currency filter to API
4. WHEN calculating totals THEN the system SHALL sum amounts per currency separately
5. WHEN exporting data THEN the system SHALL include all currency columns
6. WHEN viewing dashboard THEN the system SHALL show totals for each currency
7. WHEN admin views analytics THEN the system SHALL see currency breakdown
8. IF new currency is needed THEN the system SHALL support adding custom currency fields

### Requirement 26: Localization Support

**User Story:** As a user, I want the app to support Arabic and English, so that I can use it in my preferred language.

#### Acceptance Criteria

1. WHEN app starts THEN the system SHALL detect device language and use appropriate translations
2. WHEN displaying API errors THEN the system SHALL translate error messages to user's language
3. WHEN showing dates THEN the system SHALL format according to locale
4. WHEN displaying numbers THEN the system SHALL use locale-specific formatting
5. WHEN user switches language THEN the system SHALL update all UI text immediately
6. WHEN API returns English errors THEN the system SHALL map to localized messages
7. WHEN exporting data THEN the system SHALL use user's language for headers and labels
8. IF translation is missing THEN the system SHALL fall back to English

### Requirement 27: Security Best Practices

**User Story:** As a user, I want my data to be secure, so that my financial information is protected.

#### Acceptance Criteria

1. WHEN storing token THEN the system SHALL use secure storage (Keychain/Keystore)
2. WHEN transmitting data THEN the system SHALL use HTTPS for all API requests
3. WHEN logging THEN the system SHALL never log sensitive data (passwords, tokens)
4. WHEN app is backgrounded THEN the system SHALL clear sensitive data from memory
5. WHEN certificate is invalid THEN the system SHALL refuse connection and show error
6. WHEN user logs out THEN the system SHALL securely wipe all stored credentials
7. WHEN handling files THEN the system SHALL validate file types and sizes
8. IF security vulnerability is detected THEN the system SHALL prompt user to update app

### Requirement 28: Performance Optimization

**User Story:** As a user, I want the app to be fast and responsive, so that I can work efficiently.

#### Acceptance Criteria

1. WHEN loading lists THEN the system SHALL implement pagination with 15 items per page
2. WHEN scrolling THEN the system SHALL lazy load additional pages
3. WHEN fetching data THEN the system SHALL show loading indicators
4. WHEN operations complete THEN the system SHALL update UI within 100ms
5. WHEN uploading images THEN the system SHALL compress to reduce upload time
6. WHEN downloading files THEN the system SHALL show progress indicator
7. WHEN app starts THEN the system SHALL load critical data first, defer non-critical
8. IF API is slow THEN the system SHALL show cached data while waiting for response

### Requirement 29: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive tests, so that the integration is reliable.

#### Acceptance Criteria

1. WHEN writing API services THEN the system SHALL include unit tests for all methods
2. WHEN testing authentication THEN the system SHALL mock API responses
3. WHEN testing data operations THEN the system SHALL verify correct endpoints are called
4. WHEN testing error handling THEN the system SHALL simulate various error scenarios
5. WHEN testing offline mode THEN the system SHALL verify queueing and sync behavior
6. WHEN running integration tests THEN the system SHALL use test API environment
7. WHEN testing file uploads THEN the system SHALL verify multipart encoding
8. IF tests fail THEN the system SHALL provide clear error messages for debugging

### Requirement 30: Documentation and Developer Experience

**User Story:** As a developer, I want clear documentation, so that I can maintain and extend the integration.

#### Acceptance Criteria

1. WHEN implementing API service THEN the system SHALL include inline code documentation
2. WHEN creating models THEN the system SHALL document all fields and their types
3. WHEN writing error handlers THEN the system SHALL document error codes and meanings
4. WHEN configuring environment THEN the system SHALL provide example configuration files
5. WHEN setting up project THEN the system SHALL include README with setup instructions
6. WHEN API changes THEN the system SHALL update documentation accordingly
7. WHEN debugging THEN the system SHALL provide detailed logs with request/response data
8. IF new developer joins THEN the system SHALL have onboarding guide for Laravel integration
