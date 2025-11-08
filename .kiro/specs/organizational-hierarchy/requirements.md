# Requirements Document - Organizational Hierarchy System

## Introduction

This document specifies the requirements for implementing an organizational hierarchy system in the user registration and data access control. The system enables multi-organization support with department-level granularity, allowing administrators to manage organization-wide data while regular users access only their department-specific data.

## Glossary

- **System**: The Laravel backend application
- **Organization**: A top-level entity representing a major organizational unit (e.g., هيئة الاتصالات, هيئة الموارد البشرية)
- **Department**: A sub-unit within an Organization (e.g., إدارة الشبكات, إدارة المعلوماتية)
- **Admin User**: A user with administrative privileges who manages an entire Organization
- **Regular User**: A standard user who belongs to a specific Department within an Organization
- **User Data**: Any records (expenses, transfers, incoming, fund box entries) created by a user
- **Registration Endpoint**: The API endpoint `/api/register` that handles new user registration
- **Authentication Token**: JWT token containing user identity and organizational context

## Requirements

### Requirement 1: Organization Management

**User Story:** As a system administrator, I want to manage multiple organizations in the system, so that different organizational entities can use the application independently.

#### Acceptance Criteria

1. THE System SHALL store Organization records with unique identifiers and Arabic names
2. THE System SHALL provide an API endpoint to retrieve the list of available Organizations
3. THE System SHALL support adding new Organizations without code changes
4. THE System SHALL include "هيئة الاتصالات" as the initial Organization in the database
5. THE System SHALL validate that Organization identifiers are unique across the system

### Requirement 2: Department Management

**User Story:** As a system administrator, I want to associate departments with their parent organizations, so that the organizational structure is properly maintained.

#### Acceptance Criteria

1. THE System SHALL store Department records with unique identifiers, Arabic names, and Organization associations
2. THE System SHALL provide an API endpoint to retrieve Departments filtered by Organization identifier
3. THE System SHALL support adding new Departments to existing Organizations without code changes
4. THE System SHALL include the following Departments for "هيئة الاتصالات": إدارة الإشارة, إدارة المعلوماتية, إدارة الشبكات, إدارة الحرب الالكترونية
5. THE System SHALL validate that Department identifiers are unique within their Organization
6. THE System SHALL prevent deletion of Organizations that have associated Departments

### Requirement 3: User Registration with Organizational Context

**User Story:** As a new user, I want to select my organization and department during registration, so that my account is properly associated with my organizational unit.

#### Acceptance Criteria

1. THE System SHALL accept `organization_id` as a required field in the registration request
2. WHEN a Regular User registers, THE System SHALL require `department_id` in the registration request
3. WHEN an Admin User registers, THE System SHALL accept registration without `department_id`
4. THE System SHALL validate that the provided `organization_id` exists in the database
5. IF `department_id` is provided, THEN THE System SHALL validate that it exists and belongs to the specified Organization
6. THE System SHALL store the Organization and Department associations in the users table
7. THE System SHALL return validation error 422 with descriptive messages for invalid organizational data
8. THE System SHALL include organization and department information in the registration response

### Requirement 4: Authentication Token Enhancement

**User Story:** As an authenticated user, I want my organizational context included in my authentication token, so that the system can enforce proper data access controls.

#### Acceptance Criteria

1. WHEN a user logs in, THE System SHALL include `organization_id` in the JWT token payload
2. WHEN a Regular User logs in, THE System SHALL include `department_id` in the JWT token payload
3. WHEN an Admin User logs in, THE System SHALL include `is_admin` flag in the JWT token payload
4. THE System SHALL include `role` field in the JWT token payload indicating user type
5. THE System SHALL validate token integrity on every authenticated request

### Requirement 5: Admin Data Access Control

**User Story:** As an admin user, I want to view all data from all departments within my organization, so that I can oversee organization-wide operations.

#### Acceptance Criteria

1. WHEN an Admin User requests data, THE System SHALL return records from all Departments within their Organization
2. THE System SHALL filter data based on the `organization_id` from the authentication token
3. THE System SHALL apply organization-level filtering to expenses, transfers, incoming, and fund box queries
4. THE System SHALL exclude data from other Organizations in all responses
5. THE System SHALL maintain this filtering across all paginated results

### Requirement 6: Regular User Data Access Control

**User Story:** As a regular user, I want to view only the data I created within my department, so that I maintain privacy and data separation.

#### Acceptance Criteria

1. WHEN a Regular User requests data, THE System SHALL return only records created by that specific user
2. THE System SHALL filter data based on the `user_id` from the authentication token
3. THE System SHALL apply user-level filtering to expenses, transfers, incoming, and fund box queries
4. THE System SHALL exclude data from other users even within the same Department
5. THE System SHALL maintain this filtering across all paginated results

### Requirement 7: Data Creation with Organizational Context

**User Story:** As a user creating financial records, I want my organizational context automatically associated with my data, so that proper data segregation is maintained.

#### Acceptance Criteria

1. WHEN a user creates a record, THE System SHALL automatically associate the user's `organization_id` with the record
2. WHEN a Regular User creates a record, THE System SHALL automatically associate the user's `department_id` with the record
3. THE System SHALL prevent users from manually specifying different organizational contexts
4. THE System SHALL validate organizational context consistency before persisting records
5. THE System SHALL apply this behavior to expenses, transfers, incoming, and fund box entries

### Requirement 8: Database Schema Updates

**User Story:** As a database administrator, I want proper schema structure for organizational hierarchy, so that data integrity is maintained.

#### Acceptance Criteria

1. THE System SHALL include an `organizations` table with columns: id, name, created_at, updated_at
2. THE System SHALL include a `departments` table with columns: id, organization_id, name, created_at, updated_at
3. THE System SHALL add `organization_id` column to the `users` table as a required foreign key
4. THE System SHALL add `department_id` column to the `users` table as a nullable foreign key
5. THE System SHALL add `organization_id` column to all financial record tables (expenses, transfers, incoming, fund_box)
6. THE System SHALL add `department_id` column to all financial record tables as a nullable field
7. THE System SHALL create foreign key constraints to maintain referential integrity
8. THE System SHALL create database indexes on organizational columns for query performance

### Requirement 9: API Endpoints for Organizational Data

**User Story:** As a frontend developer, I want API endpoints to retrieve organizational structure, so that I can populate dropdown menus in the registration form.

#### Acceptance Criteria

1. THE System SHALL provide GET `/api/organizations` endpoint returning all Organizations
2. THE System SHALL provide GET `/api/organizations/{id}/departments` endpoint returning Departments for a specific Organization
3. THE System SHALL return Organization data in JSON format with id and name fields
4. THE System SHALL return Department data in JSON format with id, organization_id, and name fields
5. THE System SHALL allow unauthenticated access to these endpoints for registration purposes
6. THE System SHALL return 404 error for non-existent Organization identifiers

### Requirement 10: Data Migration for Existing Users

**User Story:** As a system administrator, I want existing user data migrated to the new organizational structure, so that the system remains functional after the update.

#### Acceptance Criteria

1. THE System SHALL provide a migration script to assign existing users to default Organization
2. THE System SHALL provide a migration script to add organizational context to existing financial records
3. THE System SHALL maintain data integrity during the migration process
4. THE System SHALL log any migration errors for manual review
5. THE System SHALL allow rollback of migrations if issues are detected

### Requirement 11: Validation and Error Handling

**User Story:** As a user, I want clear error messages when I provide invalid organizational data, so that I can correct my input.

#### Acceptance Criteria

1. WHEN invalid `organization_id` is provided, THE System SHALL return error message "المنظمة المحددة غير موجودة" (Selected organization does not exist)
2. WHEN invalid `department_id` is provided, THE System SHALL return error message "القسم المحدد غير موجود" (Selected department does not exist)
3. WHEN `department_id` does not belong to specified Organization, THE System SHALL return error message "القسم لا ينتمي للمنظمة المحددة" (Department does not belong to the specified organization)
4. WHEN Regular User registers without `department_id`, THE System SHALL return error message "القسم مطلوب للمستخدمين العاديين" (Department is required for regular users)
5. THE System SHALL return validation errors with HTTP status code 422

### Requirement 12: Scalability and Extensibility

**User Story:** As a system architect, I want the organizational structure to be easily extensible, so that new organizations and departments can be added without code changes.

#### Acceptance Criteria

1. THE System SHALL support adding new Organizations through database seeding or admin interface
2. THE System SHALL support adding new Departments through database seeding or admin interface
3. THE System SHALL not require code deployment to add new organizational entities
4. THE System SHALL maintain consistent behavior regardless of the number of Organizations
5. THE System SHALL maintain query performance with up to 100 Organizations and 1000 Departments

## Technical Notes for Backend Team

### Database Schema Recommendations

```sql
-- Organizations table
CREATE TABLE organizations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    INDEX idx_name (name)
);

-- Departments table
CREATE TABLE departments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    INDEX idx_organization (organization_id)
);

-- Users table modifications
ALTER TABLE users 
    ADD COLUMN organization_id BIGINT UNSIGNED NOT NULL AFTER id,
    ADD COLUMN department_id BIGINT UNSIGNED NULL AFTER organization_id,
    ADD FOREIGN KEY (organization_id) REFERENCES organizations(id),
    ADD FOREIGN KEY (department_id) REFERENCES departments(id),
    ADD INDEX idx_organization (organization_id),
    ADD INDEX idx_department (department_id);

-- Financial tables modifications (apply to: expenses, transfers, incoming, fund_box)
ALTER TABLE {table_name}
    ADD COLUMN organization_id BIGINT UNSIGNED NOT NULL AFTER user_id,
    ADD COLUMN department_id BIGINT UNSIGNED NULL AFTER organization_id,
    ADD FOREIGN KEY (organization_id) REFERENCES organizations(id),
    ADD FOREIGN KEY (department_id) REFERENCES departments(id),
    ADD INDEX idx_organization (organization_id),
    ADD INDEX idx_department (department_id);
```

### API Response Format Examples

**GET /api/organizations**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "هيئة الاتصالات"
    }
  ]
}
```

**GET /api/organizations/1/departments**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "إدارة الإشارة"
    },
    {
      "id": 2,
      "organization_id": 1,
      "name": "إدارة المعلوماتية"
    },
    {
      "id": 3,
      "organization_id": 1,
      "name": "إدارة الشبكات"
    },
    {
      "id": 4,
      "organization_id": 1,
      "name": "إدارة الحرب الالكترونية"
    }
  ]
}
```

**POST /api/register (Regular User)**
```json
{
  "name": "أحمد محمد",
  "email": "ahmad@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "department_id": 3,
  "role": "user"
}
```

**POST /api/register (Admin User)**
```json
{
  "name": "مدير النظام",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "role": "admin"
}
```

### Query Filtering Logic

**For Admin Users:**
```php
// Filter by organization only
$query->where('organization_id', auth()->user()->organization_id);
```

**For Regular Users:**
```php
// Filter by user_id (owns the data)
$query->where('user_id', auth()->id());
```

### Initial Data Seeding

```php
// Seed initial organization
Organization::create(['name' => 'هيئة الاتصالات']);

// Seed initial departments
$org = Organization::where('name', 'هيئة الاتصالات')->first();
Department::create(['organization_id' => $org->id, 'name' => 'إدارة الإشارة']);
Department::create(['organization_id' => $org->id, 'name' => 'إدارة المعلوماتية']);
Department::create(['organization_id' => $org->id, 'name' => 'إدارة الشبكات']);
Department::create(['organization_id' => $org->id, 'name' => 'إدارة الحرب الالكترونية']);
```

## Implementation Priority

1. Database schema updates (Requirement 8)
2. Organization and Department management (Requirements 1, 2)
3. API endpoints for organizational data (Requirement 9)
4. User registration updates (Requirement 3)
5. Authentication token enhancement (Requirement 4)
6. Data access control (Requirements 5, 6)
7. Data creation with context (Requirement 7)
8. Validation and error handling (Requirement 11)
9. Data migration (Requirement 10)
10. Testing and scalability verification (Requirement 12)
