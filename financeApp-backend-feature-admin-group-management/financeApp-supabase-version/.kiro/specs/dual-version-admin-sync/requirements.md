# Requirements Document

## Introduction

This feature transforms the finance application into two distinct versions: an Admin Version with full functionality and a Public/User Version with limited modules. The system will implement one-way data synchronization where user-submitted invoices automatically appear in the Admin version, but admin-created data remains isolated. This architecture enables centralized oversight while maintaining user privacy and requires transitioning from local-only storage to a hybrid local-cloud storage solution to support invoice image synchronization across versions.

## Requirements

### Requirement 1: Dual Application Build Configuration

**User Story:** As a developer, I want to build two separate application versions from the same codebase, so that I can deploy Admin and User versions with different feature sets.

#### Acceptance Criteria

1. WHEN the application is built THEN the system SHALL support two distinct build flavors: 'admin' and 'user'
2. WHEN building the admin flavor THEN the system SHALL include all existing modules (Currency Exchange, Expenses, Invoice Export, Cash, Cashbox)
3. WHEN building the user flavor THEN the system SHALL include only Currency Exchange, Expenses, and Invoice Export modules
4. WHEN the user version is running THEN the system SHALL not display navigation items or routes for Cash and Cashbox pages
5. WHEN the application starts THEN the system SHALL detect which flavor is running and configure features accordingly
6. WHEN building for different platforms (Android, iOS, Web) THEN the system SHALL support both flavors on all platforms
7. IF a user attempts to access a disabled module through deep linking or direct navigation THEN the system SHALL redirect to the home screen

### Requirement 2: User Version Module Restrictions

**User Story:** As a user of the Public version, I want access only to relevant financial tools, so that the interface is simplified and focused on my needs.

#### Acceptance Criteria

1. WHEN a user opens the Public version THEN the system SHALL display only Currency Exchange, Expenses, and Invoice Export in the navigation
2. WHEN a user navigates the Public version THEN the system SHALL not show any Cash or Cashbox related UI components
3. WHEN a user creates an expense in the Public version THEN the system SHALL function identically to the Admin version
4. WHEN a user exports invoices in the Public version THEN the system SHALL have access to the same export functionality as the Admin version
5. WHEN a user accesses Currency Exchange in the Public version THEN the system SHALL provide the same features as the Admin version
6. IF the Public version code references Cash or Cashbox features THEN the system SHALL handle it gracefully without errors

### Requirement 3: One-Way Data Synchronization (User → Admin)

**User Story:** As an administrator, I want to automatically receive all invoices created by users, so that I can monitor and manage all financial activities centrally.

#### Acceptance Criteria

1. WHEN a user creates a new invoice in the Public version THEN the system SHALL automatically synchronize it to the Admin version
2. WHEN a user attaches an image to an invoice THEN the system SHALL upload the image to shared storage accessible by the Admin
3. WHEN the Admin version queries invoices THEN the system SHALL retrieve both admin-created and user-submitted invoices
4. WHEN a user creates an expense THEN the system SHALL synchronize it to the Admin version with the user's identity preserved
5. WHEN synchronization occurs THEN the system SHALL include metadata indicating the source user and timestamp
6. WHEN a user is offline THEN the system SHALL queue invoice data locally and synchronize when connectivity is restored
7. WHEN synchronization fails THEN the system SHALL retry with exponential backoff and notify the user if persistent failures occur
8. IF network connectivity is unavailable THEN the system SHALL allow users to continue creating invoices locally

### Requirement 4: Data Isolation (Admin → User)

**User Story:** As a user, I want to see only my own data, so that I don't have access to other users' financial information or admin-created records.

#### Acceptance Criteria

1. WHEN the Admin creates a new invoice THEN the system SHALL not synchronize it to any User version
2. WHEN the Admin creates a new user account THEN the system SHALL not appear in other User versions
3. WHEN a User version queries invoices THEN the system SHALL return only invoices created by that specific user
4. WHEN a User version queries expenses THEN the system SHALL return only expenses created by that specific user
5. WHEN the Admin version queries data THEN the system SHALL have access to all user-submitted data plus admin-created data
6. WHEN data filtering occurs THEN the system SHALL enforce user_id-based filtering at the repository level
7. IF a User version attempts to access another user's data THEN the system SHALL deny access and log the attempt

### Requirement 5: Centralized Invoice Image Storage

**User Story:** As an administrator, I want to access all invoice images uploaded by users, so that I can review supporting documentation for financial records.

#### Acceptance Criteria

1. WHEN a user attaches an image to an invoice THEN the system SHALL upload it to a centralized cloud storage service
2. WHEN an image is uploaded THEN the system SHALL generate a unique identifier and store the reference in the invoice record
3. WHEN the Admin views an invoice THEN the system SHALL retrieve and display the associated image from cloud storage
4. WHEN a user is offline THEN the system SHALL store images locally and upload them when connectivity is restored
5. WHEN an image upload fails THEN the system SHALL retry automatically and notify the user if the upload cannot complete
6. WHEN images are stored THEN the system SHALL organize them by user_id and invoice_id for efficient retrieval
7. WHEN the Admin deletes an invoice THEN the system SHALL optionally delete the associated images from cloud storage
8. IF cloud storage is unavailable THEN the system SHALL fall back to local storage and sync when available

### Requirement 6: Cloud Storage Integration

**User Story:** As a developer, I want to integrate a cloud storage solution, so that invoice images can be shared between User and Admin versions.

#### Acceptance Criteria

1. WHEN the application initializes THEN the system SHALL configure cloud storage credentials securely
2. WHEN uploading an image THEN the system SHALL use Firebase Storage, AWS S3, or similar cloud storage service
3. WHEN storing images THEN the system SHALL implement proper access control to ensure only authorized users can access images
4. WHEN retrieving images THEN the system SHALL use signed URLs or tokens with expiration for security
5. WHEN images are uploaded THEN the system SHALL compress them to optimize storage and bandwidth
6. WHEN the storage quota is exceeded THEN the system SHALL notify the Admin and prevent new uploads until resolved
7. WHEN images are accessed THEN the system SHALL implement caching to reduce redundant downloads
8. IF cloud storage credentials are invalid THEN the system SHALL log errors and notify administrators

### Requirement 7: Hybrid Local-Cloud Data Architecture

**User Story:** As a user, I want the application to work offline while automatically syncing when online, so that I can work without interruption regardless of connectivity.

#### Acceptance Criteria

1. WHEN a user creates an invoice offline THEN the system SHALL store it locally in SQLite
2. WHEN connectivity is restored THEN the system SHALL automatically sync pending invoices to the cloud
3. WHEN syncing occurs THEN the system SHALL update local records with cloud-generated IDs and timestamps
4. WHEN the Admin version starts THEN the system SHALL fetch the latest data from the cloud and merge with local data
5. WHEN conflicts occur (same invoice modified locally and remotely) THEN the system SHALL use a last-write-wins strategy with cloud data taking precedence
6. WHEN sync is in progress THEN the system SHALL display a sync indicator in the UI
7. WHEN sync completes THEN the system SHALL notify the user of success or any errors
8. IF sync fails repeatedly THEN the system SHALL allow manual retry and provide detailed error information

### Requirement 8: User Identity and Attribution

**User Story:** As an administrator, I want to see which user created each invoice, so that I can track accountability and communicate with users if needed.

#### Acceptance Criteria

1. WHEN a user creates an invoice THEN the system SHALL tag it with the user's ID and username
2. WHEN the Admin views invoices THEN the system SHALL display the creator's username alongside each invoice
3. WHEN filtering invoices THEN the system SHALL allow the Admin to filter by user
4. WHEN exporting data THEN the system SHALL include user attribution in exported reports
5. WHEN a user is deleted THEN the system SHALL preserve their historical invoice data with a "deleted user" marker
6. WHEN displaying user information THEN the system SHALL show user profile details (name, email, registration date)
7. IF user attribution data is missing THEN the system SHALL mark the invoice as "Unknown User" and log the issue

### Requirement 9: Synchronization Status and Monitoring

**User Story:** As a user, I want to know the synchronization status of my invoices, so that I can ensure my data has been successfully submitted to the Admin.

#### Acceptance Criteria

1. WHEN an invoice is created THEN the system SHALL mark it with a sync status: 'pending', 'syncing', 'synced', or 'failed'
2. WHEN viewing invoices THEN the system SHALL display a visual indicator of sync status (icon or badge)
3. WHEN sync fails THEN the system SHALL display an error message with details and a retry option
4. WHEN the user manually triggers sync THEN the system SHALL attempt to sync all pending items
5. WHEN sync completes successfully THEN the system SHALL update the status and show a confirmation
6. WHEN the Admin version is running THEN the system SHALL provide a dashboard showing sync statistics (total synced, pending, failed)
7. IF an invoice remains unsynced for more than 24 hours THEN the system SHALL alert the user

### Requirement 10: Security and Access Control

**User Story:** As an administrator, I want to ensure that only authorized users can access the Admin version, so that sensitive financial data is protected.

#### Acceptance Criteria

1. WHEN the Admin version starts THEN the system SHALL require admin-level authentication
2. WHEN a user attempts to access the Admin version THEN the system SHALL verify admin privileges before granting access
3. WHEN cloud storage is accessed THEN the system SHALL use role-based access control (RBAC) to enforce permissions
4. WHEN API calls are made THEN the system SHALL include authentication tokens in headers
5. WHEN tokens expire THEN the system SHALL automatically refresh them or prompt for re-authentication
6. WHEN the Admin version accesses user data THEN the system SHALL log all access for audit purposes
7. IF unauthorized access is detected THEN the system SHALL block the request and alert administrators

### Requirement 11: Build Configuration and Deployment

**User Story:** As a developer, I want clear build configurations for each version, so that I can easily deploy Admin and User versions to different distribution channels.

#### Acceptance Criteria

1. WHEN building the Admin version THEN the system SHALL use a distinct application ID (e.g., com.app.finance.admin)
2. WHEN building the User version THEN the system SHALL use a different application ID (e.g., com.app.finance.user)
3. WHEN configuring builds THEN the system SHALL use separate Firebase projects or cloud storage buckets for each version
4. WHEN building for production THEN the system SHALL include version-specific app icons and branding
5. WHEN deploying THEN the system SHALL support separate release channels (Admin to internal distribution, User to public stores)
6. WHEN environment variables are needed THEN the system SHALL use .env files or build-time configuration
7. IF build configuration is incorrect THEN the system SHALL fail the build with clear error messages

### Requirement 12: Data Migration and Backward Compatibility

**User Story:** As a developer, I want to migrate existing data to the new architecture, so that current users can transition smoothly without data loss.

#### Acceptance Criteria

1. WHEN the app is updated THEN the system SHALL run a migration script to add sync-related fields to existing tables
2. WHEN existing invoices are migrated THEN the system SHALL mark them as 'synced' if created by admin or 'pending' if user-created
3. WHEN the migration completes THEN the system SHALL update the database version number
4. WHEN users update the app THEN the system SHALL preserve all existing local data
5. WHEN the Admin version is first launched THEN the system SHALL perform an initial sync of all user data
6. IF migration fails THEN the system SHALL rollback changes and display an error message
7. WHEN testing migration THEN the system SHALL provide a way to test on a copy of production data

