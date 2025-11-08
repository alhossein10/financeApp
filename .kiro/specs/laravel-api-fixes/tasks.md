# Implementation Plan: Laravel API Integration Fixes

## Overview

This implementation plan provides a step-by-step guide to fix all API integration issues between the Flutter app and Laravel backend. Each task builds incrementally and focuses on specific modules to ensure systematic progress.

---

## Tasks

- [x] 1. Fix Transfer Module API Integration





  - Update TransferDto with correct field mappings (from_account, to_account, amount, date)
  - Fix TransferApiDataSource request/response handling
  - Update Transfer entity and model mappings
  - Add date formatting utilities for YYYY-MM-DD format
  - Test transfer CRUD operations against Laravel API
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. Fix Incoming Module API Integration





  - Update IncomingDto with source and payment_method fields
  - Fix IncomingApiDataSource request/response handling
  - Add payment method validation (cash, card, bank_transfer)
  - Update Incoming entity and model mappings
  - Test incoming CRUD operations against Laravel API
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 3. Fix Fund Box Module with Admin Access Control






  - Update FundBoxDto with total_balance and last_updated fields
  - Fix FundBoxApiDataSource with proper 403 error handling
  - Update fund box update request body
  - Add AuthorizationFailure exception handling
  - Test fund box operations with admin and regular user roles
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Fix Admin Dashboard API Integration





  - Update AdminStatsDto with all required fields from API spec
  - Create ExpenseSummaryDto for by_category and by_payment_method data
  - Create AnalyticsDto for analytics endpoint
  - Create UserActivityDto for user list endpoint
  - Fix AdminApiDataSource for all dashboard endpoints
  - Add proper 403 error handling for admin-only endpoints
  - Test all admin dashboard endpoints
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 5. Fix Expense Module Field Mappings





  - Update ExpenseDto with payment_method validation
  - Fix date formatting in expense requests
  - Update pagination parameters (per_page, page)
  - Fix filter parameters (category, date_from, date_to)
  - Test expense CRUD operations with all payment methods
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6. Implement Profile API Integration






  - Create ProfileDto with id, name, email, role, created_at fields
  - Create ProfileApiDataSource with get, update, changePassword methods
  - Implement profile repository and use cases
  - Add profile BLoC for state management
  - Create profile UI pages (view, edit, change password)
  - Test profile operations
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7. Implement Export API Integration





  - Create ExportDto with id, format, status, download_url fields
  - Create ExportApiDataSource with PDF and Excel export methods
  - Implement export status checking
  - Implement file download functionality
  - Add export BLoC for state management
  - Update export UI with proper status display
  - Test PDF and Excel export with date range filters
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8. Fix Batch Sync API Integration





  - Create SyncRequestDto and SyncResponseDto
  - Create SyncDataDto for expenses, incoming, transfers arrays
  - Create EntitySyncResult with created items and conflicts
  - Update BatchSyncService with correct request/response handling
  - Implement conflict resolution UI
  - Test batch sync with offline changes
  - Test sync changes endpoint with since parameter
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 9. Implement File Upload API Integration





  - Create FileUploadDto with all required fields
  - Update FileUploadService with multipart/form-data support
  - Implement file download with encrypted path parameter
  - Implement file deletion
  - Add file upload UI for receipts and documents
  - Test file upload, download, and deletion
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10. Implement Audit Logs Admin Feature





  - Create AuditLogDto with all required fields
  - Create AuditLogApiDataSource for list and detail endpoints
  - Implement audit log repository and use cases
  - Add audit log BLoC for state management
  - Create audit logs UI page with pagination
  - Create audit log detail view
  - Test audit logs with admin user
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 11. Enhance Error Handling System




  - Update ApiException with statusCode-based properties
  - Add userFriendlyMessage getter with all error codes
  - Add validation error formatting
  - Update all BLoCs with enhanced error handling
  - Add 401 handling with automatic logout
  - Add 403 handling with access denied messages
  - Add 422 handling with field-specific errors
  - Add 429 rate limit handling
  - Test all error scenarios
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

- [x] 12. Implement Role-Based Access Control




  - Create RoleService for role management
  - Add role checking in all admin-only features
  - Create RoleBasedWidget for conditional UI rendering
  - Update flavor configuration with role awareness
  - Add role validation before admin API calls
  - Handle 403 errors gracefully in UI
  - Test admin features with user and admin roles
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 13. Fix Authentication Token Management





  - Update TokenManager with secure storage
  - Implement token validation on app start
  - Add automatic token refresh logic
  - Update all API calls with Bearer token header
  - Implement logout with token clearing
  - Handle 401 responses with re-authentication
  - Test token expiration and refresh
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 14. Implement Date Format Utilities




  - Create DateFormatter class with toApiDate method
  - Create toApiTimestamp method for ISO 8601 format
  - Create fromApiDate and fromApiTimestamp parsers
  - Update all DTOs to use DateFormatter
  - Update all API data sources with consistent date formatting
  - Test date formatting with various timezones
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 15. Implement Pagination Utilities




  - Create PaginationHelper class
  - Add page and per_page parameter handling
  - Create PaginatedResponse wrapper
  - Update all list endpoints with pagination
  - Implement infinite scroll in UI
  - Add "load more" functionality
  - Test pagination with large datasets
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 16. Write Unit Tests





  - [x] 16.1 Write DTO serialization tests for all entities


  - [x] 16.2 Write API data source tests with mocked responses


  - [x] 16.3 Write validation tests for payment methods and dates


  - [x] 16.4 Write error handling tests for all error codes


  - [x] 16.5 Write role-based access control tests



- [x] 17. Write Integration Tests




  - [x] 17.1 Write transfer CRUD integration tests


  - [x] 17.2 Write incoming CRUD integration tests

  - [x] 17.3 Write fund box integration tests with role checks


  - [x] 17.4 Write admin dashboard integration tests


  - [x] 17.5 Write batch sync integration tests


  - [x] 17.6 Write file upload/download integration tests



- [x] 18. Write Widget Tests





  - [x] 18.1 Write error message display tests



  - [x] 18.2 Write validation error display tests


  - [x] 18.3 Write admin dashboard widget tests


  - [x] 18.4 Write role-based widget visibility tests


- [x] 19. Manual Testing and Validation





  - Test all endpoints with Postman collection
  - Test user flavor with regular user account
  - Test admin flavor with admin account
  - Test admin flavor with regular user (should show access denied)
  - Test offline mode with queue manager
  - Test error scenarios (network errors, validation errors, etc.)
  - Test date formatting across different locales
  - Test pagination with large datasets
  - Verify all field mappings match API specification
  - _Requirements: All_

- [x] 20. Update Documentation





  - Update API integration documentation
  - Update error handling guide
  - Update role-based access control guide
  - Create migration guide for existing users
  - Update troubleshooting guide
  - Document all DTO field mappings
  - Create API testing guide with Postman
  - _Requirements: All_

---

## Implementation Notes

### Critical Path
Tasks 1-5 are critical and must be completed first as they fix the core API integration issues affecting transfers, incoming, fund box, admin dashboard, and expenses.

### Dependencies
- Task 11 (Error Handling) should be completed before tasks 6-10 to ensure consistent error handling
- Task 12 (RBAC) should be completed before testing admin features
- Task 13 (Token Management) should be completed early to ensure authentication works properly
- Task 14 (Date Formatting) should be completed before tasks 1-2, 5-7 to ensure consistent date handling

### Testing Strategy
- Unit tests (Task 16) can be written alongside implementation tasks
- Integration tests (Task 17) should be written after completing tasks 1-10
- Widget tests (Task 18) should be written after UI updates
- Manual testing (Task 19) should be performed after all implementation tasks

### Rollback Strategy
- Keep backup of current DTOs before modifications
- Test each module independently before moving to next
- Use feature flags for new features (Profile, Export, Audit Logs)
- Maintain backward compatibility with local database

### Performance Considerations
- Implement caching for frequently accessed data (profile, fund box)
- Use pagination for all list endpoints
- Optimize offline queue processing
- Monitor API response times

### Security Considerations
- Validate all user inputs before API calls
- Store tokens securely using flutter_secure_storage
- Clear sensitive data on logout
- Handle 403 errors without exposing system details
