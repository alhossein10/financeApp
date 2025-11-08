# Implementation Plan

## Task Overview

This implementation plan converts the design into actionable coding tasks. Each task builds incrementally on previous work, ensuring the Laravel backend integration is implemented systematically with minimal disruption to existing functionality.

---

## Phase 1: Infrastructure Setup

- [x] 1. Set up API client infrastructure




  - Create `lib/core/api/api_client.dart` with dio HTTP client
  - Implement request/response interceptors
  - Add authentication token injection
  - Implement retry logic with exponential backoff
  - Add request timeout configuration
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_


- [x] 1.1 Create API configuration

  - Create `lib/core/config/api_config.dart`
  - Define base URL for dev/staging/production
  - Configure timeout and retry settings
  - Add API version constants
  - _Requirements: 20.1, 20.2, 20.3_


- [x] 1.2 Add required packages

  - Add `dio` for HTTP requests
  - Add `flutter_secure_storage` for token storage
  - Add `hive` and `hive_flutter` for caching
  - Add `connectivity_plus` for network monitoring
  - Remove `sqflite`, `supabase_flutter`, `pocketbase` packages
  - _Requirements: 3.4, 4.4, 5.3_


- [x] 1.3 Create error handling system

  - Create `lib/core/api/api_exception.dart`
  - Define exception types for each HTTP status code
  - Implement error parsing from API responses
  - Create user-friendly error messages
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_


- [x] 1.4 Implement logging system

  - Create `lib/core/utils/api_logger.dart`
  - Log requests/responses in debug mode
  - Implement error logging with stack traces
  - Never log sensitive data (tokens, passwords)
  - _Requirements: 20.5, 20.6_

---

## Phase 2: Authentication Implementation

- [x] 2. Implement authentication service




  - Create `lib/core/services/laravel_auth_service.dart`
  - Implement register, login, logout methods
  - Add token storage using secure storage
  - Implement token retrieval and validation
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 2.1 Create authentication models


  - Create `lib/core/api/models/auth_response.dart`
  - Create `lib/core/api/models/user_dto.dart`
  - Implement JSON serialization/deserialization
  - Map DTOs to domain entities
  - _Requirements: 2.1, 2.2_

- [x] 2.2 Implement token management


  - Create `lib/core/services/token_manager.dart`
  - Store tokens in flutter_secure_storage
  - Implement token expiration checking
  - Add automatic token refresh logic
  - Handle token refresh failures
  - _Requirements: 2.5, 2.6, 21.1, 21.2, 21.3_

- [x] 2.3 Update authentication repository


  - Update `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - Replace local auth with API calls
  - Implement API data source
  - Remove SQLite dependencies
  - _Requirements: 2.1, 2.2, 2.3, 2.7_

- [x] 2.4 Update authentication BLoC


  - Update `lib/features/auth/presentation/bloc/auth_bloc.dart`
  - Handle API authentication states
  - Implement error handling for auth failures
  - Update UI to show API errors
  - _Requirements: 2.8, 15.1_

- [x] 2.5 Implement password management


  - Create forgot password API integration
  - Create reset password API integration
  - Update change password to use API
  - Update UI screens for password flows
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

---

## Phase 3: Cache and Offline Support

- [x] 3. Implement cache service





  - Create `lib/core/services/cache_service.dart`
  - Use Hive for local storage
  - Implement get/set/delete/clear methods
  - Add TTL (time-to-live) support
  - Implement LRU eviction policy
  - _Requirements: 24.1, 24.2, 24.3, 24.4_

- [x] 3.1 Create offline queue system


  - Create `lib/core/services/queue_manager.dart`
  - Create `lib/core/models/queue_item.dart`
  - Implement enqueue/dequeue operations
  - Store queue in Hive
  - _Requirements: 14.1, 14.2_

- [x] 3.2 Implement queue processing


  - Monitor connectivity changes
  - Auto-process queue when online
  - Implement exponential backoff for failures
  - Update sync status in UI
  - _Requirements: 14.2, 14.3, 14.6, 14.7_

- [x] 3.3 Create connectivity monitor


  - Use connectivity_plus package
  - Stream connectivity changes
  - Trigger queue processing on connect
  - Update UI with online/offline indicator
  - _Requirements: 14.1, 14.2_

---

## Phase 4: Expense Module Migration

- [x] 4. Create expense API data source






  - Create `lib/features/expenses/data/datasources/expense_api_datasource.dart`
  - Implement getExpenses with pagination
  - Implement createExpense API call
  - Implement updateExpense API call
  - Implement deleteExpense API call
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 4.1 Create expense DTOs


  - Create `lib/features/expenses/data/models/expense_dto.dart`
  - Implement JSON serialization
  - Map DTO to domain entity
  - Handle multi-currency fields
  - _Requirements: 6.1, 25.1, 25.2_

- [x] 4.2 Update expense repository


  - Update `lib/features/expenses/data/repositories/expense_repository_impl.dart`
  - Integrate API data source
  - Integrate cache data source
  - Implement cache-first strategy
  - Queue operations when offline
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 14.1_

- [x] 4.3 Implement file upload for invoices


  - Create `lib/core/services/file_upload_service.dart`
  - Implement image compression
  - Upload invoice to API
  - Download invoice from API
  - Delete invoice via API
  - _Requirements: 6.5, 6.6, 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 4.4 Update expense BLoC


  - Update `lib/features/expenses/presentation/bloc/expense_bloc.dart`
  - Handle API responses
  - Show sync status in UI
  - Handle offline queue status
  - Display API errors
  - _Requirements: 6.8, 14.7, 15.1_

- [x] 4.5 Remove SQLite expense code


  - Delete `lib/features/expenses/data/datasources/expense_local_datasource_impl.dart`
  - Remove database queries
  - Update dependency injection
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

---

## Phase 5: Transfer Module Migration

- [x] 5. Create transfer API data source





  - Create `lib/features/transfers/data/datasources/transfer_api_datasource.dart`
  - Implement getTransfers with pagination
  - Implement createTransfer API call
  - Implement updateTransfer API call
  - Implement deleteTransfer API call
  - Implement addExchange API call
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5.1 Create transfer DTOs


  - Create `lib/features/transfers/data/models/transfer_dto.dart`
  - Create `lib/features/transfers/data/models/exchange_dto.dart`
  - Implement JSON serialization
  - Map DTOs to domain entities
  - _Requirements: 7.1, 7.6_

- [x] 5.2 Update transfer repository


  - Update `lib/features/transfers/data/repositories/transfer_repository_impl.dart`
  - Integrate API data source
  - Integrate cache data source
  - Queue operations when offline
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5.3 Update transfer BLoC


  - Update `lib/features/transfers/presentation/bloc/transfer_bloc.dart`
  - Handle API responses
  - Display exchange information
  - Handle offline status
  - _Requirements: 7.6, 7.8, 14.7_

- [x] 5.4 Remove SQLite transfer code


  - Delete `lib/features/transfers/data/datasources/transfer_local_datasource_impl.dart`
  - Remove database queries
  - Update dependency injection
  - _Requirements: 3.1, 3.2, 3.5_

---

## Phase 6: Incoming Module Migration

- [x] 6. Create incoming API data source





  - Create `lib/features/incoming/data/datasources/incoming_api_datasource.dart`
  - Implement getIncoming with pagination
  - Implement createIncoming API call
  - Implement updateIncoming API call
  - Implement deleteIncoming API call
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 6.1 Create incoming DTOs


  - Create `lib/features/incoming/data/models/incoming_dto.dart`
  - Implement JSON serialization
  - Map DTO to domain entity
  - _Requirements: 8.1, 8.6_

- [x] 6.2 Update incoming repository


  - Update `lib/features/incoming/data/repositories/incoming_repository_impl.dart`
  - Integrate API data source
  - Integrate cache data source
  - Queue operations when offline
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 6.3 Update incoming BLoC


  - Update `lib/features/incoming/presentation/bloc/incoming_bloc.dart`
  - Handle API responses
  - Display totals from API
  - Handle offline status
  - _Requirements: 8.6, 8.7, 8.8_

- [x] 6.4 Remove SQLite incoming code


  - Delete `lib/features/incoming/data/datasources/incoming_local_datasource_impl.dart`
  - Remove database queries
  - Update dependency injection
  - _Requirements: 3.1, 3.2, 3.5_

---

## Phase 7: Admin Features Migration

- [x] 7. Implement fund box API integration






  - Create `lib/features/fund_box/data/datasources/fund_box_api_datasource.dart`
  - Implement getFundBox API call
  - Implement updateFundBox API call
  - Handle admin-only access
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 7.1 Update fund box repository


  - Update `lib/features/fund_box/data/repositories/fund_box_repository_impl.dart`
  - Integrate API data source
  - Remove SQLite dependencies
  - _Requirements: 9.1, 9.2_

- [x] 7.2 Update fund box BLoC



  - Update `lib/features/fund_box/presentation/bloc/fund_box_bloc.dart`
  - Handle API responses
  - Handle 403 errors for non-admin
  - _Requirements: 9.3, 9.4, 9.6_

- [x] 7.3 Implement admin dashboard API


  - Create `lib/features/admin/data/datasources/admin_api_datasource.dart`
  - Implement getStats API call
  - Implement getUserActivity API call
  - Implement getExpenseSummaries API call
  - Implement getAnalytics API call
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 7.4 Update admin dashboard BLoC


  - Update `lib/features/admin/presentation/bloc/admin_bloc.dart`
  - Display API statistics
  - Handle date range filtering
  - Show user activity from API
  - _Requirements: 10.5, 10.6, 10.7_

- [x] 7.5 Implement audit logs (admin only)


  - Create `lib/features/admin/data/datasources/audit_log_api_datasource.dart`
  - Implement getAuditLogs with pagination
  - Implement filtering by user, action, resource
  - Display audit log details
  - _Requirements: 19.1, 19.2, 19.3, 19.4_

- [x] 7.6 Hide admin features for non-admin users


  - Update navigation to check user role
  - Hide fund box for non-admin
  - Hide admin dashboard for non-admin
  - Hide audit logs for non-admin
  - _Requirements: 9.7, 10.8, 16.2, 16.3_

---

## Phase 8: Data Export and Batch Sync

- [x] 8. Implement export API integration





  - Create `lib/features/export/data/datasources/export_api_datasource.dart`
  - Implement exportExpensesToPdf API call
  - Implement exportExpensesToExcel API call
  - Implement getExportStatus API call
  - Implement downloadExport API call
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 8.1 Update export BLoC


  - Create or update export BLoC
  - Handle export queueing
  - Poll export status
  - Download completed exports
  - Show progress indicators
  - _Requirements: 12.3, 12.4, 12.5, 12.8_

- [x] 8.2 Implement batch sync service


  - Create `lib/core/services/batch_sync_service.dart`
  - Create batch request models
  - Batch up to 50 records per request
  - Handle partial failures
  - Retry failed records individually
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.8_

- [x] 8.3 Implement conflict resolution


  - Create conflict resolution API integration
  - Implement server_wins strategy
  - Implement client_wins strategy
  - Update UI to show conflicts
  - _Requirements: 13.6, 13.7_

---

## Phase 9: User Profile and Role Management

- [x] 9. Implement profile API integration





  - Create `lib/features/profile/data/datasources/profile_api_datasource.dart`
  - Implement getProfile API call
  - Implement updateProfile API call
  - Implement changePassword API call
  - Implement deleteAccount API call
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

- [x] 9.1 Update profile repository


  - Update `lib/features/profile/data/repositories/profile_repository_impl.dart`
  - Integrate API data source
  - Remove local storage dependencies
  - _Requirements: 18.1, 18.2_


- [x] 9.2 Update profile BLoC

  - Update `lib/features/profile/presentation/bloc/profile_bloc.dart`
  - Handle API responses
  - Display user statistics from API
  - Handle profile update errors
  - _Requirements: 18.3, 18.6, 18.7_


- [x] 9.3 Implement role-based access control



  - Store user role from API response
  - Check role before showing admin features
  - Check role before making admin API calls
  - Display appropriate error for insufficient permissions
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_

---

## Phase 10: Data Migration

- [x] 10. Create data migration tool




  - Create `lib/core/migration/data_migrator.dart`
  - Export all SQLite data to JSON
  - Transform data to API format
  - Upload data via batch sync API
  - Verify data integrity
  - _Requirements: 22.1, 22.2, 22.3, 22.4_

- [x] 10.1 Implement migration UI


  - Create migration screen
  - Show migration progress
  - Display success/failure status
  - Handle migration errors
  - Provide retry option
  - _Requirements: 22.3, 22.5, 22.8_

- [x] 10.2 Create Supabase export tool


  - Create tool to export Supabase data
  - Transform Supabase data to API format
  - Provide export instructions
  - _Requirements: 22.7_

---

## Phase 11: Cleanup and Optimization

- [x] 11. Remove old database code




  - Delete `lib/data/db.dart`
  - Remove all SQLite database files
  - Remove database migration code
  - Update dependency injection
  - _Requirements: 3.1, 3.2, 3.3, 3.6_

- [x] 11.1 Remove Supabase integration


  - Delete `lib/core/services/supabase_service.dart`
  - Delete `lib/core/services/supabase_sync_service.dart`
  - Delete `lib/core/config/supabase_config.dart`
  - Remove Supabase environment variables
  - Update dependency injection
  - _Requirements: 4.1, 4.2, 4.3, 4.5, 4.6_

- [x] 11.2 Remove PocketBase integration


  - Delete `lib/core/services/cloud_sync_service.dart`
  - Delete `lib/core/services/pocketbase_storage_service.dart`
  - Remove PocketBase configuration files
  - Update dependency injection
  - _Requirements: 5.1, 5.2, 5.4, 5.5_

- [x] 11.3 Optimize API requests


  - Implement request debouncing
  - Batch multiple operations
  - Use pagination for all lists
  - Implement incremental loading
  - _Requirements: 28.1, 28.2, 28.7_

- [x] 11.4 Optimize caching


  - Implement cache warming
  - Use memory cache for hot data
  - Implement cache size limits
  - Optimize cache eviction
  - _Requirements: 24.5, 24.6, 24.7, 24.8_

- [x] 11.5 Optimize UI performance


  - Show cached data immediately
  - Fetch fresh data in background
  - Implement optimistic updates
  - Use skeleton loaders
  - _Requirements: 28.3, 28.4, 28.8_

---

## Phase 12: Testing and Quality Assurance

- [x] 12. Write unit tests for API client




  - Test request methods (GET, POST, PUT, DELETE)
  - Test error handling
  - Test retry logic
  - Test token injection
  - Mock HTTP responses
  - _Requirements: 29.1, 29.2_

- [x] 12.1 Write unit tests for repositories



  - Test API data source integration
  - Test cache integration
  - Test offline queue integration
  - Mock data sources
  - _Requirements: 29.1, 29.3_

- [x] 12.2 Write unit tests for services





  - Test auth service methods
  - Test queue manager
  - Test cache service
  - Test file upload service
  - _Requirements: 29.1, 29.4_

- [x] 12.3 Write integration tests





  - Test complete authentication flow
  - Test CRUD operations for each resource
  - Test offline queue processing
  - Test file upload/download
  - Test batch synchronization
  - _Requirements: 29.5, 29.6, 29.7_

- [x] 12.4 Write widget tests





  - Test login/register forms
  - Test expense list and detail screens
  - Test admin dashboard
  - Test error state displays
  - Test loading indicators
  - _Requirements: 29.8_

- [x] 12.5 Perform manual testing






  - Test on Android devices
  - Test on iOS devices
  - Test offline scenarios
  - Test error scenarios
  - Test admin features
  - _Requirements: All_

---

## Phase 13: Documentation and Deployment

- [x] 13. Update code documentation








  - Document all public APIs
  - Add inline comments for complex logic
  - Create README for each module
  - Document error codes
  - Provide usage examples
  - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5_

- [x] 13.1 Create user documentation


  - Update user guide
  - Create migration guide
  - Document new features
  - Provide troubleshooting guide
  - Create FAQ document
  - _Requirements: 30.6, 30.7, 30.8_

- [x] 13.2 Configure build environments


  - Set up development environment
  - Set up staging environment
  - Set up production environment
  - Configure API URLs for each
  - _Requirements: 20.1, 20.2, 20.4_

- [x] 13.3 Prepare for deployment


  - Test on staging environment
  - Perform user acceptance testing
  - Create rollback plan
  - Document deployment procedure
  - _Requirements: All_

- [x] 13.4 Deploy to production


  - Deploy backend API
  - Deploy Flutter app
  - Monitor for issues
  - Provide user support
  - _Requirements: All_

---

## Task Execution Notes

### Task Dependencies
- Phase 1 must be completed before any other phase
- Phase 2 must be completed before Phases 4-9
- Phase 3 should be completed early for offline support
- Phases 4-6 can be done in parallel
- Phase 7 depends on Phase 2 (authentication)
- Phase 10 depends on Phases 4-6 (data modules)
- Phase 11 depends on all previous phases
- Phase 12 should be done throughout development
- Phase 13 is the final phase

### Testing Strategy
- Write tests alongside implementation
- Test each module before moving to next
- Perform integration testing after each phase
- Manual testing before deployment

### Rollback Strategy
- Keep old code in separate branch
- Test rollback procedure
- Document rollback steps
- Maintain data export functionality

### Success Criteria
- All tests passing
- Zero data loss
- < 500ms API response time
- Smooth offline experience
- Positive user feedback
