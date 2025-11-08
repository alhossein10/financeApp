# Requirements Document

## Introduction

This document defines the requirements for a comprehensive RESTful API backend for a dual-version finance management application. The backend will support both Admin and User versions of a Flutter mobile application, providing authentication, data management, file storage, and synchronization capabilities for financial tracking operations including expenses, transfers, currency exchange, fund management, and invoice handling.

## Glossary

- **Backend System**: The Laravel-based RESTful API server that manages all data operations, authentication, and file storage
- **Admin User**: A privileged user with access to all system data and administrative features
- **Regular User**: A standard user with access only to their own financial data
- **Expense Record**: A financial transaction representing money spent, optionally with an invoice attachment
- **Transfer Record**: A financial transaction representing money sent to a recipient
- **Exchange Record**: A currency conversion transaction linked to a transfer
- **Incoming Record**: A financial transaction representing money received
- **Fund Box**: A single-row entity tracking the total USD balance across the system
- **Invoice File**: An image file (JPEG/PNG) attached to an expense record
- **Sync Status**: The cloud synchronization state of a record (pending, syncing, synced, failed)
- **API Client**: The Flutter mobile application consuming the backend API
- **Authentication Token**: A JWT or Sanctum token used to authenticate API requests

## Requirements

### Requirement 1: User Authentication and Authorization

**User Story:** As a user, I want to securely register, login, and manage my account, so that my financial data is protected and accessible only to me.

#### Acceptance Criteria

1. WHEN a new user submits registration credentials (name, email, password), THE Backend System SHALL create a user account with hashed password storage
2. WHEN a user submits valid login credentials, THE Backend System SHALL return an authentication token valid for 30 days
3. WHEN a user submits an invalid authentication token, THE Backend System SHALL return a 401 Unauthorized response
4. WHEN an Admin User authenticates, THE Backend System SHALL include admin role information in the authentication response
5. WHEN a user requests password reset, THE Backend System SHALL generate a secure reset token and send it via email

### Requirement 2: Expense Management

**User Story:** As a user, I want to create, read, update, and delete expense records with optional invoice attachments, so that I can track my spending accurately.

#### Acceptance Criteria

1. WHEN a Regular User creates an expense record, THE Backend System SHALL store the expense with user_id, description, prices in multiple currencies (USD, SYP, TRY), invoice status, expense date, and timestamps
2. WHEN a user uploads an invoice file with an expense, THE Backend System SHALL validate the file type (JPEG, PNG, PDF), compress images to maximum 1920px width, and store the file with a unique identifier
3. WHEN a Regular User requests their expense records, THE Backend System SHALL return only expenses belonging to that user
4. WHEN an Admin User requests expense records, THE Backend System SHALL return all expenses from all users with user identification
5. WHEN a user updates an expense record, THE Backend System SHALL update the updated_at timestamp and maintain sync status tracking
6. WHEN a user deletes an expense record, THE Backend System SHALL perform soft deletion and remove associated invoice files from storage

### Requirement 3: Transfer and Currency Exchange Management

**User Story:** As a user, I want to record money transfers with optional currency exchange information, so that I can track outgoing payments and currency conversions.

#### Acceptance Criteria

1. WHEN a user creates a transfer record, THE Backend System SHALL store recipient name, amount in USD, optional converted amounts, exchange rates, transaction date, and timestamps
2. WHEN a user creates an exchange record linked to a transfer, THE Backend System SHALL validate the transfer_id exists and store converted amounts with exchange rate snapshots
3. WHEN a user requests transfer records with exchange data, THE Backend System SHALL return transfers with their associated exchange records in a single response
4. WHEN a Regular User requests transfers, THE Backend System SHALL return only their own transfer records
5. WHEN an Admin User requests transfers, THE Backend System SHALL return all transfer records from all users

### Requirement 4: Incoming Funds Management

**User Story:** As a user, I want to record incoming money transactions, so that I can track revenue and money received.

#### Acceptance Criteria

1. WHEN a user creates an incoming record, THE Backend System SHALL store description, amount in USD, transaction date, and timestamps with user association
2. WHEN a Regular User requests incoming records, THE Backend System SHALL return only their own incoming transactions
3. WHEN an Admin User requests incoming records, THE Backend System SHALL return all incoming transactions from all users
4. WHEN a user updates an incoming record, THE Backend System SHALL update the updated_at timestamp
5. WHEN a user deletes an incoming record, THE Backend System SHALL perform soft deletion

### Requirement 5: Fund Box Balance Management

**User Story:** As an Admin User, I want to view and manage the central fund box balance, so that I can track the total available funds in the system.

#### Acceptance Criteria

1. WHEN the Backend System initializes, THE Backend System SHALL create a single fund_box record with id=1 and balance_usd=0.0
2. WHEN an Admin User requests the fund box balance, THE Backend System SHALL return the current balance and last updated timestamp
3. WHEN an Admin User updates the fund box balance, THE Backend System SHALL validate the new balance is non-negative and update the updated_at timestamp
4. WHEN a Regular User attempts to access fund box data, THE Backend System SHALL return a 403 Forbidden response
5. WHEN transfer or incoming transactions are created, THE Backend System SHALL automatically update the fund box balance accordingly

### Requirement 6: Admin Dashboard and Analytics

**User Story:** As an Admin User, I want to view comprehensive statistics and analytics about all users and transactions, so that I can monitor system activity and financial health.

#### Acceptance Criteria

1. WHEN an Admin User requests dashboard statistics, THE Backend System SHALL return total counts of users, expenses, transfers, incoming transactions, and total fund box balance
2. WHEN an Admin User requests user activity data, THE Backend System SHALL return a list of all users with their transaction counts and last activity timestamps
3. WHEN an Admin User requests expense summaries, THE Backend System SHALL calculate and return total expenses by currency and by user
4. WHEN an Admin User requests date-range filtered analytics, THE Backend System SHALL return aggregated data for the specified date range
5. WHEN a Regular User attempts to access admin dashboard endpoints, THE Backend System SHALL return a 403 Forbidden response

### Requirement 7: File Storage and Management

**User Story:** As a user, I want to securely upload and retrieve invoice files, so that I can maintain proof of expenses.

#### Acceptance Criteria

1. WHEN a user uploads an invoice file, THE Backend System SHALL validate file size is less than 10MB and file type is image or PDF
2. WHEN an image file is uploaded, THE Backend System SHALL compress the image to maximum 1920px width while maintaining aspect ratio
3. WHEN a file is successfully uploaded, THE Backend System SHALL return a unique file identifier and storage URL
4. WHEN a Regular User requests an invoice file, THE Backend System SHALL verify the user owns the associated expense before serving the file
5. WHEN an Admin User requests any invoice file, THE Backend System SHALL serve the file without ownership verification

### Requirement 8: Data Synchronization Support

**User Story:** As a user, I want my local app data to sync reliably with the cloud backend, so that my data is backed up and accessible across devices.

#### Acceptance Criteria

1. WHEN a user creates or updates a record, THE Backend System SHALL accept sync_status and sync metadata fields (synced_at, sync_retry_count, sync_error_message)
2. WHEN a user requests records modified after a specific timestamp, THE Backend System SHALL return only records with updated_at greater than the provided timestamp
3. WHEN a sync operation fails, THE Backend System SHALL return detailed error information including error codes and messages
4. WHEN multiple records are submitted in a batch sync request, THE Backend System SHALL process all records and return individual success or failure status for each
5. WHEN a conflict is detected (record modified on both client and server), THE Backend System SHALL return a 409 Conflict response with both versions

### Requirement 9: User Profile Management

**User Story:** As a user, I want to view and update my profile information, so that I can keep my account details current.

#### Acceptance Criteria

1. WHEN a user requests their profile, THE Backend System SHALL return name, email, account creation date, and role information
2. WHEN a user updates their profile name, THE Backend System SHALL validate the name is not empty and update the user record
3. WHEN a user updates their email, THE Backend System SHALL validate email uniqueness and format before updating
4. WHEN a user updates their password, THE Backend System SHALL require current password verification and enforce minimum 8 character length
5. WHEN a user requests account deletion, THE Backend System SHALL soft delete the user and all associated records

### Requirement 10: Data Export Functionality

**User Story:** As a user, I want to export my financial data in various formats, so that I can analyze data externally or create backups.

#### Acceptance Criteria

1. WHEN a user requests expense data export in PDF format, THE Backend System SHALL generate a formatted PDF document with all expense records and return a download URL
2. WHEN a user requests expense data export in Excel format, THE Backend System SHALL generate an XLSX file with expense records in tabular format
3. WHEN a user requests export with date range filters, THE Backend System SHALL include only records within the specified date range
4. WHEN an Admin User requests system-wide export, THE Backend System SHALL include data from all users with user identification columns
5. WHEN an export is generated, THE Backend System SHALL store the file temporarily and provide a download URL valid for 24 hours

### Requirement 11: API Rate Limiting and Security

**User Story:** As a system administrator, I want the API to be protected against abuse and security threats, so that the system remains stable and secure.

#### Acceptance Criteria

1. WHEN any API Client makes requests, THE Backend System SHALL enforce rate limiting of 60 requests per minute per authenticated user
2. WHEN an API Client exceeds rate limits, THE Backend System SHALL return a 429 Too Many Requests response with retry-after header
3. WHEN any API request is received, THE Backend System SHALL validate CSRF tokens for state-changing operations
4. WHEN file uploads are received, THE Backend System SHALL scan for malicious content and reject suspicious files
5. WHEN sensitive operations are performed (password change, account deletion), THE Backend System SHALL require recent authentication (within 15 minutes)

### Requirement 12: Multi-Currency Support

**User Story:** As a user, I want to record transactions in multiple currencies (USD, SYP, TRY), so that I can track expenses in different currencies accurately.

#### Acceptance Criteria

1. WHEN a user creates an expense record, THE Backend System SHALL accept and store price values in USD, SYP, and TRY currencies independently
2. WHEN a user creates a transfer with currency exchange, THE Backend System SHALL store both original USD amount and converted amounts with exchange rate snapshots
3. WHEN a user requests currency conversion rates, THE Backend System SHALL return current exchange rates for supported currency pairs
4. WHEN an Admin User requests currency analytics, THE Backend System SHALL calculate and return totals in each supported currency
5. WHEN currency values are stored, THE Backend System SHALL use decimal precision of 2 digits for currency amounts

### Requirement 13: Audit Logging and Activity Tracking

**User Story:** As an Admin User, I want to view audit logs of all system activities, so that I can monitor security and troubleshoot issues.

#### Acceptance Criteria

1. WHEN any user performs a create, update, or delete operation, THE Backend System SHALL log the action with user_id, resource type, resource_id, action type, and timestamp
2. WHEN an Admin User requests audit logs, THE Backend System SHALL return paginated logs with filtering by user, date range, and action type
3. WHEN a failed authentication attempt occurs, THE Backend System SHALL log the attempt with IP address and timestamp
4. WHEN sensitive data is accessed (other users' data by admin), THE Backend System SHALL log the access event
5. WHEN audit logs are requested, THE Backend System SHALL return logs in reverse chronological order (newest first)

### Requirement 14: Notification System

**User Story:** As a user, I want to receive notifications about important events, so that I stay informed about my account activity.

#### Acceptance Criteria

1. WHEN a user registers successfully, THE Backend System SHALL send a welcome email with account verification link
2. WHEN a password reset is requested, THE Backend System SHALL send a password reset email with secure token
3. WHEN an Admin User creates or modifies data on behalf of a user, THE Backend System SHALL send a notification email to the affected user
4. WHEN a sync operation fails repeatedly (more than 3 times), THE Backend System SHALL send an alert notification to the user
5. WHEN critical system events occur (security alerts, data exports ready), THE Backend System SHALL send push notifications to the mobile app

### Requirement 15: API Versioning and Documentation

**User Story:** As an API Client developer, I want clear API documentation and versioning, so that I can integrate with the backend reliably.

#### Acceptance Criteria

1. WHEN the Backend System is deployed, THE Backend System SHALL expose API endpoints under versioned paths (e.g., /api/v1/)
2. WHEN a developer accesses the API documentation endpoint, THE Backend System SHALL return OpenAPI 3.0 specification with all endpoints documented
3. WHEN API changes are made, THE Backend System SHALL maintain backward compatibility within the same major version
4. WHEN breaking changes are introduced, THE Backend System SHALL increment the major version number and maintain the previous version for 6 months
5. WHEN an API Client requests an unsupported API version, THE Backend System SHALL return a 404 Not Found response with supported versions listed
