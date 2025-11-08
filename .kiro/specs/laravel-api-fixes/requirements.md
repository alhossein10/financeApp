# Requirements Document: Laravel API Integration Fixes

## Introduction

This document outlines the requirements for fixing critical API integration issues between the Flutter finance app and the Laravel backend. The API endpoints work perfectly in Postman but have multiple field mapping mismatches, incorrect request/response handling, and flavor-specific issues in the app, particularly affecting the admin flavor for transfers, incoming, fund box, and admin dashboard features.

## Glossary

- **System**: The Flutter finance management application
- **Laravel Backend**: The RESTful API server built with Laravel framework
- **Admin Flavor**: The administrative version of the app with elevated privileges
- **User Flavor**: The standard user version of the app with limited privileges
- **DTO**: Data Transfer Object used for API communication
- **Field Mapping**: The correspondence between API JSON fields and app model properties
- **Payment Method**: The method used for transactions (cash, card, bank_transfer)
- **Fund Box**: The global balance management feature for administrators

## Requirements

### Requirement 1: Transfer API Field Mapping

**User Story:** As a user or admin, I want to create and manage transfers so that the data is correctly synchronized with the Laravel backend.

#### Acceptance Criteria

1. WHEN the System sends a transfer creation request, THE System SHALL map `from_account` and `to_account` fields according to the API specification
2. WHEN the System receives a transfer response, THE System SHALL correctly parse `amount`, `from_account`, `to_account`, `description`, and `date` fields
3. WHEN the System creates a transfer, THE System SHALL send the date field in YYYY-MM-DD format as required by the API
4. WHERE the transfer includes exchange information, THE System SHALL handle the nested exchange object structure
5. WHEN the System updates a transfer, THE System SHALL include all required fields in the PUT request body

### Requirement 2: Incoming (Income) API Field Mapping

**User Story:** As a user or admin, I want to record income transactions so that they are accurately stored and retrieved from the backend.

#### Acceptance Criteria

1. WHEN the System sends an incoming creation request, THE System SHALL map `source`, `description`, `amount`, `date`, and `payment_method` fields correctly
2. WHEN the System receives an incoming response, THE System SHALL parse the `source` field as the primary descriptor
3. WHEN the System creates incoming records, THE System SHALL validate that `payment_method` is one of: cash, card, bank_transfer
4. WHEN the System lists incoming transactions, THE System SHALL handle paginated responses with `per_page` parameter
5. WHEN the System updates incoming records, THE System SHALL send all required fields in the request body

### Requirement 3: Fund Box Admin Access Control

**User Story:** As an admin, I want to access and update the fund box so that I can manage the organization's total balance, while regular users are properly restricted.

#### Acceptance Criteria

1. WHEN an admin user accesses the fund box, THE System SHALL successfully retrieve the balance from `/fund-box` endpoint
2. WHEN a regular user attempts to access the fund box, THE System SHALL handle 403 Forbidden responses gracefully
3. WHEN an admin updates the fund box, THE System SHALL send `total_balance` field in the request body
4. WHEN the System receives a fund box response, THE System SHALL parse `total_balance` and `last_updated` fields correctly
5. IF the System receives a 403 error, THEN THE System SHALL display "Access denied. Admin privileges required" message

### Requirement 4: Admin Dashboard API Integration

**User Story:** As an admin, I want to view comprehensive dashboard statistics so that I can monitor system-wide activity and analytics.

#### Acceptance Criteria

1. WHEN an admin requests dashboard stats, THE System SHALL call `/admin/dashboard/stats` endpoint
2. WHEN the System receives dashboard stats, THE System SHALL parse `total_users`, `total_expenses`, `total_income`, `total_transfers`, `total_amount_expenses`, `total_amount_income`, and `fund_box_balance` fields
3. WHEN an admin requests user activity, THE System SHALL call `/admin/dashboard/users` endpoint
4. WHEN an admin requests expense summaries, THE System SHALL call `/admin/dashboard/expenses` endpoint and parse `by_category` and `by_payment_method` groupings
5. WHEN an admin requests analytics, THE System SHALL send `date_from` and `date_to` query parameters in YYYY-MM-DD format

### Requirement 5: Expense API Field Corrections

**User Story:** As a user or admin, I want to manage expenses so that all fields are correctly mapped to the API specification.

#### Acceptance Criteria

1. WHEN the System creates an expense, THE System SHALL send `amount`, `category`, `description`, `date`, and `payment_method` fields
2. WHEN the System receives expense responses, THE System SHALL parse all fields including `created_at` and `updated_at` timestamps
3. WHEN the System filters expenses, THE System SHALL use `category`, `date_from`, and `date_to` query parameters
4. WHEN the System paginates expenses, THE System SHALL use `per_page` query parameter with default value of 15
5. WHEN the System validates payment methods, THE System SHALL ensure the value is one of: cash, card, bank_transfer

### Requirement 6: Profile API Integration

**User Story:** As a user, I want to manage my profile information so that my account details are synchronized with the backend.

#### Acceptance Criteria

1. WHEN the System retrieves user profile, THE System SHALL call `/profile` endpoint
2. WHEN the System updates profile, THE System SHALL send `name` and `email` fields in the request body
3. WHEN the System changes password, THE System SHALL call `/profile/password` endpoint with `current_password`, `new_password`, and `new_password_confirmation` fields
4. WHEN the System receives profile responses, THE System SHALL parse `id`, `name`, `email`, `role`, and `created_at` fields
5. WHEN the System handles profile errors, THE System SHALL display validation messages from the `errors` object

### Requirement 7: Export API Integration

**User Story:** As a user or admin, I want to export expense data so that I can generate PDF or Excel reports.

#### Acceptance Criteria

1. WHEN the System requests PDF export, THE System SHALL call `/export/expenses/pdf` endpoint with `format`, `date_from`, and `date_to` fields
2. WHEN the System requests Excel export, THE System SHALL call `/export/expenses/excel` endpoint with the same parameters
3. WHEN the System receives export response, THE System SHALL parse `id`, `format`, `status`, and `download_url` fields
4. WHEN the System checks export status, THE System SHALL call `/export/{id}/status` endpoint
5. WHEN the System downloads export, THE System SHALL call `/export/{id}/download` endpoint and handle file download

### Requirement 8: Batch Sync API Integration

**User Story:** As a user, I want offline changes to sync automatically so that my data is consistent across devices.

#### Acceptance Criteria

1. WHEN the System performs batch sync, THE System SHALL call `/sync/batch` endpoint with `last_sync` timestamp and `data` object
2. WHEN the System sends sync data, THE System SHALL structure the `data` object with `expenses`, `incoming`, and `transfers` arrays
3. WHEN the System receives sync response, THE System SHALL parse `synced_at`, created items with `local_id` to `server_id` mapping, and `conflicts` array
4. WHEN the System retrieves changes, THE System SHALL call `/sync/changes` endpoint with `since` query parameter
5. WHEN the System processes sync conflicts, THE System SHALL handle `created`, `updated`, and `deleted` arrays for each entity type

### Requirement 9: File Upload API Integration

**User Story:** As a user, I want to upload receipts and documents so that they are securely stored with my transactions.

#### Acceptance Criteria

1. WHEN the System uploads a file, THE System SHALL call `/files/upload` endpoint with multipart/form-data content type
2. WHEN the System sends file upload, THE System SHALL include `file` and `type` fields (receipt, invoice, document)
3. WHEN the System receives upload response, THE System SHALL parse `id`, `filename`, `path`, `type`, `size`, `mime_type`, and `uploaded_at` fields
4. WHEN the System downloads a file, THE System SHALL call `/files/download` endpoint with `path` query parameter
5. WHEN the System deletes a file, THE System SHALL call DELETE `/files` endpoint with `path` in request body

### Requirement 10: Audit Logs Admin Feature

**User Story:** As an admin, I want to view audit logs so that I can track system activities for security and compliance.

#### Acceptance Criteria

1. WHEN an admin requests audit logs, THE System SHALL call `/audit-logs` endpoint
2. WHEN the System receives audit logs, THE System SHALL parse paginated response with `current_page`, `data`, `per_page`, and `total` fields
3. WHEN the System displays audit log entries, THE System SHALL show `user_id`, `action`, `entity_type`, `entity_id`, `ip_address`, `user_agent`, and `created_at` fields
4. WHEN an admin views log details, THE System SHALL call `/audit-logs/{id}` endpoint
5. WHEN the System displays log details, THE System SHALL show `user_name`, `changes` object, and all metadata fields

### Requirement 11: Role-Based Access Control

**User Story:** As a system administrator, I want proper role-based access control so that users and admins have appropriate permissions.

#### Acceptance Criteria

1. WHEN the System determines user role, THE System SHALL check the `role` field from authentication response
2. WHEN a user attempts admin-only operations, THE System SHALL prevent access and display appropriate error messages
3. WHEN the System receives 403 Forbidden responses, THE System SHALL handle them gracefully without crashes
4. WHERE admin features are displayed, THE System SHALL verify user role before rendering UI components
5. WHEN the System switches between flavors, THE System SHALL maintain proper role-based restrictions

### Requirement 12: Error Handling and Validation

**User Story:** As a user, I want clear error messages so that I understand what went wrong and how to fix it.

#### Acceptance Criteria

1. WHEN the System receives 400 Bad Request, THE System SHALL display validation errors from the `errors` object
2. WHEN the System receives 401 Unauthorized, THE System SHALL redirect to login and clear stored tokens
3. WHEN the System receives 403 Forbidden, THE System SHALL display "Access denied" message
4. WHEN the System receives 404 Not Found, THE System SHALL display "Resource not found" message
5. WHEN the System receives 422 Unprocessable Entity, THE System SHALL display field-specific validation errors
6. WHEN the System receives 429 Too Many Requests, THE System SHALL display "Too many requests. Please try again later" message
7. WHEN the System receives 500 Internal Server Error, THE System SHALL display "Internal server error" message and log details

### Requirement 13: Authentication Token Management

**User Story:** As a user, I want seamless authentication so that my session is maintained securely across app restarts.

#### Acceptance Criteria

1. WHEN the System authenticates, THE System SHALL store the JWT token from `data.token` field
2. WHEN the System makes authenticated requests, THE System SHALL include `Authorization: Bearer {token}` header
3. WHEN the System receives token expiration, THE System SHALL handle 401 responses and prompt re-authentication
4. WHEN the System logs out, THE System SHALL call `/auth/logout` endpoint and clear stored tokens
5. WHEN the System starts, THE System SHALL validate stored token by calling `/auth/me` endpoint

### Requirement 14: Date Format Consistency

**User Story:** As a developer, I want consistent date formatting so that API requests are always accepted.

#### Acceptance Criteria

1. WHEN the System sends date fields in requests, THE System SHALL format dates as YYYY-MM-DD
2. WHEN the System sends timestamp fields, THE System SHALL format as ISO 8601 (YYYY-MM-DDTHH:mm:ss.sssZ)
3. WHEN the System receives date responses, THE System SHALL parse both YYYY-MM-DD and ISO 8601 formats
4. WHEN the System displays dates to users, THE System SHALL format according to user locale
5. WHEN the System filters by date range, THE System SHALL use `date_from` and `date_to` parameters in YYYY-MM-DD format

### Requirement 15: Pagination Handling

**User Story:** As a user, I want smooth pagination so that I can browse large lists of transactions efficiently.

#### Acceptance Criteria

1. WHEN the System requests paginated data, THE System SHALL send `page` and `per_page` query parameters
2. WHEN the System receives paginated responses, THE System SHALL parse `current_page`, `last_page`, `per_page`, and `total` fields
3. WHEN the System loads more data, THE System SHALL increment the `page` parameter
4. WHEN the System reaches the last page, THE System SHALL disable "load more" functionality
5. WHEN the System refreshes data, THE System SHALL reset to page 1
