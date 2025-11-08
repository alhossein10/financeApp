# Implementation Plan

- [x] 1. Set up PocketBase infrastructure and project configuration
  - Create PocketBase project locally
  - Configure PocketBase collections (expenses, invoice_files, users)
  - Set up collection rules for security
  - Add role field to users collection
  - Configure file upload settings
  - Test PocketBase locally
  - _Requirements: 1.6, 6.1, 6.2, 6.3, 10.1_

- [x] 2. Implement build flavor configuration system





  - [x] 2.1 Create AppFlavor enum and FlavorConfig class


    - Write lib/core/config/flavor_config.dart with AppFlavor enum (admin, user)
    - Implement FlavorConfig class with flavor-specific settings
    - Add module enable/disable flags (enableCashModule, enableCashboxModule, etc.)
    - Add flavor-specific app names and application IDs
    - _Requirements: 1.1, 1.2, 1.3, 11.1, 11.2_



  
  - [x] 2.2 Create separate entry points for each flavor


    - Create lib/main_admin.dart that initializes admin flavor
    - Create lib/main_user.dart that initializes user flavor
    - Update lib/main.dart to be flavor-agnostic
    - _Requirements: 1.1, 1.5_
  
  - [x] 2.3 Configure Android build flavors


    - Update android/app/build.gradle with productFlavors (admin, user)
    - Set distinct applicationId for each flavor
    - Configure flavor-specific app names
    - _Requirements: 11.1, 11.2, 11.3_
  
  - [x] 2.4 Configure iOS build schemes


    - Create Admin and User schemes in Xcode
    - Configure distinct bundle identifiers for each scheme
    - _Requirements: 11.1, 11.2, 11.3_

- [x] 3. Implement cloud storage service for invoice images with PocketBase





  - [x] 3.1 Create StorageService interface


    - Define abstract StorageService class in lib/core/services/storage_service.dart
    - Add uploadInvoiceImage method signature
    - Add getInvoiceImageUrl method signature
    - Add downloadInvoiceImage method signature
    - Add deleteInvoiceImage method signature
    - Add isOnline method signature
    - _Requirements: 5.1, 5.2, 5.3, 6.2_
  
  - [x] 3.2 Implement PocketBaseStorageService


    - Create lib/core/services/pocketbase_storage_service.dart
    - Implement uploadInvoiceImage with image compression
    - Upload files to PocketBase 'invoice_files' collection
    - Implement getInvoiceImageUrl using PocketBase file URLs
    - Implement downloadInvoiceImage with local caching
    - Implement deleteInvoiceImage
    - Implement isOnline using connectivity_plus
    - Add error handling for network failures
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.2, 6.4_
  
  - [x] 3.3 Add image compression utility


    - Create lib/core/utils/image_compression.dart
    - Implement image resizing (max 1920px width)
    - Implement JPEG compression with 85% quality
    - Handle various image formats (PNG, JPEG, HEIC)
    - _Requirements: 5.5, 6.5_

- [x] 4. Update database schema for synchronization support






  - [x] 4.1 Add sync-related columns to expenses table

    - Add invoice_cloud_file_id TEXT column
    - Add sync_status INTEGER column (default 0 for pending)
    - Add synced_at INTEGER column
    - Add sync_retry_count INTEGER column (default 0)
    - Add sync_error_message TEXT column
    - Create migration script in lib/data/db.dart
    - _Requirements: 7.1, 7.2, 9.1, 12.1, 12.2_
  

  - [x] 4.2 Add role column to users table

    - Add role INTEGER column to users table (default 0 for user, 1 for admin)
    - Update User entity and UserModel with role field
    - Create migration to add role column
    - _Requirements: 8.1, 10.1, 10.2_
  

  - [x] 4.3 Create database indexes for sync queries

    - Create index on expenses(sync_status)
    - Create index on expenses(synced_at)
    - Create index on expenses(user_id, sync_status)
    - _Requirements: 7.1, 9.1_

- [x] 5. Implement synchronization service with PocketBase





  - [x] 5.1 Create SyncStatus enum and sync models


    - Create lib/core/models/sync_status.dart with enum (pending, syncing, synced, failed)
    - Create SyncRetryStrategy class with exponential backoff logic
    - _Requirements: 3.1, 3.6, 3.7, 9.1, 9.2_
  
  - [x] 5.2 Create SyncService interface


    - Define abstract SyncService class in lib/core/services/sync_service.dart
    - Add syncExpense method signature
    - Add syncPendingExpenses method signature
    - Add fetchAdminExpenses method signature
    - Add watchSyncStatus stream method signature
    - Add startAutoSync and stopAutoSync method signatures
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 4.3, 9.1_
  
  - [x] 5.3 Implement CloudSyncService with PocketBase


    - Create lib/core/services/cloud_sync_service.dart
    - Implement syncExpense with image upload and PocketBase record creation
    - Implement syncPendingExpenses with batch processing
    - Implement fetchAdminExpenses (admin-only) using PocketBase queries
    - Implement watchSyncStatus with StreamController
    - Implement startAutoSync with Timer.periodic (5 minutes)
    - Implement stopAutoSync
    - Add retry logic with exponential backoff
    - Add user attribution (username, email) to synced data
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 8.1, 8.2, 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [x] 5.4 Update ExpenseLocalDataSource for sync operations


    - Add updateSyncStatus method
    - Add updateCloudFileId method
    - Add getExpensesBySyncStatus method
    - Add incrementSyncRetryCount method
    - Add updateSyncErrorMessage method
    - _Requirements: 3.1, 3.6, 7.1, 9.1, 9.3_

- [x] 6. Update Expense domain layer with sync fields





  - [x] 6.1 Update Expense entity


    - Add invoiceCloudFileId field to Expense entity
    - Add syncStatus field (default SyncStatus.pending)
    - Add syncedAt field
    - Add syncRetryCount field (default 0)
    - Add syncErrorMessage field
    - Add creatorUsername field (for admin view)
    - Add creatorEmail field (for admin view)
    - Update Expense constructor and props
    - _Requirements: 3.1, 3.4, 7.1, 8.1, 8.2, 9.1_
  
  - [x] 6.2 Update ExpenseModel


    - Update ExpenseModel.fromMap to include new sync fields
    - Update ExpenseModel.toMap to include new sync fields
    - Update ExpenseModel.copyWith to include new sync fields
    - _Requirements: 3.1, 7.1, 9.1_

- [x] 7. Integrate sync service into expense creation flow





  - [x] 7.1 Update CreateExpenseUseCase


    - Inject SyncService into CreateExpenseUseCase
    - After creating expense locally, queue it for sync
    - Set initial sync_status to pending
    - Handle sync errors gracefully
    - _Requirements: 3.1, 3.2, 3.8, 7.1, 9.1_
  
  - [x] 7.2 Update ExpenseBloc to handle sync events


    - Add SyncExpenseEvent
    - Add SyncAllPendingEvent
    - Add SyncStatusUpdatedEvent
    - Update ExpenseState to include sync status map
    - Listen to sync status stream and emit state updates
    - _Requirements: 3.1, 3.6, 9.1, 9.2, 9.5_

- [x] 8. Implement conditional UI based on flavor




  - [x] 8.1 Update HomeScaffold navigation

    - Modify _pages getter to conditionally include pages based on FlavorConfig
    - Modify _destinations getter to conditionally include navigation items
    - Remove Cash and Cashbox from user version navigation
    - _Requirements: 1.3, 1.4, 2.1, 2.2_
  
  - [x] 8.2 Create SyncStatusIndicator widget


    - Create lib/ui/widgets/sync_status_indicator.dart
    - Display different icons/colors for each SyncStatus
    - Add retry button for failed syncs
    - _Requirements: 9.1, 9.2, 9.3_
  
  - [x] 8.3 Update ExpensePage to show sync status


    - Add SyncStatusIndicator to each expense list item
    - Add pull-to-refresh to trigger manual sync
    - Show sync progress indicator during batch sync
    - _Requirements: 9.1, 9.2, 9.4, 9.5_

- [x] 9. Implement admin-specific features





  - [x] 9.1 Create AdminDashboard page


    - Create lib/features/admin/presentation/pages/admin_dashboard_page.dart
    - Display statistics (total users, total expenses, pending sync, total amount)
    - Show recent user-submitted expenses
    - Display user activity summary
    - Only accessible when FlavorConfig.flavor == AppFlavor.admin
    - _Requirements: 4.3, 8.1, 8.2, 8.3, 8.4, 10.1_
  
  - [x] 9.2 Create AdminBloc for dashboard data


    - Create lib/features/admin/presentation/bloc/admin_bloc.dart
    - Implement FetchAdminStatisticsEvent
    - Implement FetchAllUserExpensesEvent
    - Call SyncService.fetchAdminExpenses()
    - Aggregate statistics from fetched data
    - _Requirements: 4.3, 8.1, 8.2, 8.3_
  
  - [x] 9.3 Update ExpensePage for admin view


    - Show creator username/email for each expense in admin version
    - Add filter by user dropdown
    - Add filter by sync status
    - Display invoice images from PocketBase storage
    - _Requirements: 4.3, 5.2, 8.1, 8.2, 8.3, 8.4_

- [x] 10. Implement security and access control





  - [x] 10.1 Configure PocketBase collection rules


    - Write collection rules for expenses collection
    - Write collection rules for invoice_files collection
    - Ensure users can only write their own expenses
    - Ensure users can only read their own expenses
    - Ensure admins can read all expenses
    - Test rules in PocketBase admin UI
    - _Requirements: 6.3, 10.1, 10.2, 10.3, 10.4, 10.6_
  
  - [x] 10.2 Add role-based access checks in repositories


    - Update ExpenseRepository to check user role for admin operations
    - Prevent non-admin users from accessing fetchAdminExpenses
    - Log unauthorized access attempts
    - _Requirements: 4.4, 4.5, 10.1, 10.2, 10.6_

- [x] 11. Update dependency injection container





  - [x] 11.1 Register new services in injection_container.dart


    - Register FlavorConfig as singleton
    - Register PocketBase instance
    - Register Connectivity instance
    - Register StorageService (PocketBaseStorageService)
    - Register SyncService (CloudSyncService)
    - Update ExpenseBloc to inject SyncService
    - _Requirements: 1.5, 3.1, 5.1, 6.1_

- [x] 12. Add offline support and connectivity handling





  - [x] 12.1 Implement connectivity monitoring


    - Create lib/core/services/connectivity_service.dart
    - Monitor connectivity changes using connectivity_plus
    - Emit connectivity status stream
    - _Requirements: 3.6, 3.8, 7.1, 7.2_
  
  - [x] 12.2 Implement automatic sync on connectivity restore


    - Listen to connectivity status in SyncService
    - Trigger syncPendingExpenses when connectivity is restored
    - Show notification when sync completes after going online
    - _Requirements: 3.6, 7.2, 9.5_

- [x] 13. Add localization for new features





  - [x] 13.1 Add sync-related translation keys


    - Add 'sync_pending', 'sync_syncing', 'sync_synced', 'sync_failed' keys
    - Add 'sync_retry', 'sync_all', 'sync_in_progress' keys
    - Add 'admin_dashboard', 'total_users', 'total_expenses' keys
    - Add 'created_by', 'sync_status' keys
    - Provide Arabic translations for all new keys
    - _Requirements: 9.1, 9.2, 9.3_

- [x] 14. Testing and validation




  - [x] 14.1 Write unit tests for FlavorConfig










    - Test admin flavor configuration
    - Test user flavor configuration
    - Test module enable/disable flags
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 14.2 Write unit tests for StorageService






    - Test image upload success
    - Test image upload failure (no network)
    - Test image compression
    - Test file ID generation
    - Mock PocketBase
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 6.2_
  
  - [x] 14.3 Write unit tests for SyncService






    - Test syncExpense success
    - Test syncExpense with image
    - Test sync retry logic
    - Test syncPendingExpenses batch processing
    - Test fetchAdminExpenses (admin only)
    - Mock PocketBase
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 4.3_
  
  - [x] 14.4 Write integration tests for sync flow






    - Test end-to-end: create expense → sync → admin fetch
    - Test offline creation → online sync
    - Test sync failure → retry → success
    - _Requirements: 3.1, 3.6, 7.1, 7.2_

- [x] 15. Documentation and deployment preparation






  - [x] 15.1 Update README with build instructions

    - Document how to build admin flavor
    - Document how to build user flavor
    - Document PocketBase setup steps
    - Document environment configuration
    - _Requirements: 11.4, 11.5, 11.6_
  

  - [x] 15.2 Create deployment guide

    - Document PocketBase local setup
    - Document PocketBase Render deployment (when ready)
    - Document collection rules setup
    - Document app distribution (admin to internal, user to stores)
    - _Requirements: 11.3, 11.5_
