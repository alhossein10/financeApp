# Design Document

## Overview

The Admin Group Management system extends the existing Finance Application to support group-based data isolation and management. The design introduces a new `AdminGroup` model that links admins to their managed users, replaces the foreign-key based organization/department system with free-text fields, and implements group code-based user assignment. The architecture maintains the existing service-repository pattern while adding new components for group management.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     API Layer (Controllers)                  │
├─────────────────────────────────────────────────────────────┤
│  AuthController  │  AdminGroupController  │  ExpenseController│
│  TransferController  │  IncomingController  │  etc.          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
├─────────────────────────────────────────────────────────────┤
│  AuthService  │  AdminGroupService  │  ExpenseService        │
│  TransferService  │  IncomingService  │  etc.                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Repository Layer                            │
├─────────────────────────────────────────────────────────────┤
│  AdminGroupRepository  │  ExpenseRepository                  │
│  TransferRepository  │  IncomingRepository  │  etc.          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer (Models)                      │
├─────────────────────────────────────────────────────────────┤
│  User  │  AdminGroup  │  Expense  │  Transfer  │  Incoming  │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Free-Text Organization/Department**: Remove foreign key constraints from `organization_id` and `department_id` in the `users` table, converting them to `organization_name` and `department_name` text fields. This allows users to enter any organization/department without predefined options.

2. **AdminGroup Model**: Introduce a new `admin_groups` table to manage the relationship between admins and their group members, storing the group code and admin reference.

3. **Group Code Generation**: Use Laravel's `Str::random()` with numeric characters to generate 4-6 digit codes, with uniqueness validation.

4. **Data Scoping Middleware**: Create middleware to automatically scope queries based on user role and group membership.

5. **Backward Compatibility**: Maintain existing Organization and Department models for historical data, but make them optional for new registrations.

## Components and Interfaces

### 1. AdminGroup Model

**Purpose**: Represents the relationship between an admin user and their managed group of regular users.

**Properties**:
- `id`: Primary key
- `admin_user_id`: Foreign key to users table (admin)
- `group_code`: Unique 4-6 digit numeric code
- `group_name`: Optional descriptive name for the group
- `is_active`: Boolean flag for active/inactive groups
- `created_at`, `updated_at`: Timestamps

**Relationships**:
- `admin()`: BelongsTo User (admin)
- `members()`: HasMany User (regular users)

**Methods**:
- `generateUniqueGroupCode()`: Static method to generate unique group codes
- `regenerateGroupCode()`: Instance method to regenerate the group code
- `addMember(User $user)`: Add a user to the group
- `removeMember(User $user)`: Remove a user from the group
- `isMember(User $user)`: Check if a user is a member

### 2. User Model Updates

**New Properties**:
- `organization_name`: String field (replaces organization_id)
- `department_name`: Nullable string field (replaces department_id)
- `admin_group_id`: Nullable foreign key to admin_groups table

**New Relationships**:
- `adminGroup()`: BelongsTo AdminGroup
- `managedGroup()`: HasOne AdminGroup (for admin users)

**New Methods**:
- `isGroupMember()`: Check if user belongs to an admin group
- `getGroupAdmin()`: Get the admin of the user's group
- `canAccessUser(User $user)`: Check if current user can access another user's data

### 3. AdminGroupService

**Purpose**: Business logic for admin group management.

**Methods**:

```php
public function createGroupForAdmin(User $admin): AdminGroup
// Creates a new admin group with unique code when admin registers

public function getAdminGroup(User $admin): ?AdminGroup
// Retrieves the admin's group

public function regenerateGroupCode(User $admin): AdminGroup
// Generates a new group code for the admin

public function joinGroupByCode(User $user, string $groupCode): AdminGroup
// Assigns a user to a group using the group code

public function getGroupMembers(User $admin, array $filters = [], int $perPage = 15): LengthAwarePaginator
// Returns paginated list of group members

public function removeMemberFromGroup(User $admin, User $member): bool
// Removes a user from the admin's group

public function validateGroupCodeForUser(User $user, string $groupCode): bool
// Validates if a user can join a group (same organization check)

public function getAvailableTransferRecipients(User $admin): Collection
// Returns users in admin's group who can receive transfers
```

### 4. AdminGroupRepository

**Purpose**: Data access layer for admin groups.

**Methods**:

```php
public function findByGroupCode(string $groupCode): ?AdminGroup
// Find admin group by group code

public function findByAdmin(User $admin): ?AdminGroup
// Find admin group by admin user

public function getGroupMembers(AdminGroup $group, array $filters = [], int $perPage = 15): LengthAwarePaginator
// Get paginated group members

public function isGroupCodeUnique(string $groupCode): bool
// Check if group code is unique

public function updateGroupCode(AdminGroup $group, string $newCode): AdminGroup
// Update group code
```

### 5. AdminGroupController

**Purpose**: HTTP API endpoints for group management.

**Endpoints**:

```php
GET    /api/admin/group              // Get admin's group info and code
POST   /api/admin/group/regenerate   // Regenerate group code
GET    /api/admin/group/members      // List group members (paginated)
DELETE /api/admin/group/members/{id} // Remove member from group
POST   /api/user/join-group          // Join group using code
GET    /api/user/group-info          // Get current user's group info
```

### 6. Updated AuthService

**New/Modified Methods**:

```php
public function register(array $data): User
// Modified to:
// - Accept organization_name and department_name as text
// - Create AdminGroup for admin users
// - Handle optional group_code for regular users

public function registerWithGroupCode(array $data, string $groupCode): User
// New method for users registering with a group code
```

### 7. Data Scoping Middleware

**Purpose**: Automatically filter queries based on user role and group membership.

**Class**: `ScopeDataByUserGroup`

**Logic**:
- For regular users: Scope to only their own data
- For admin users: Scope to data from all users in their group
- Apply to all financial data endpoints (expenses, transfers, incoming, fund box)

### 8. Updated Repository Methods

**ExpenseRepository, TransferRepository, IncomingRepository**:

All `getAll` methods will be updated to accept a `User` parameter and apply group-based scoping:

```php
public function getAllExpenses(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
// Returns expenses scoped to user's group if admin, or own data if regular user

public function getAllTransfers(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
// Returns transfers scoped to user's group if admin, or own data if regular user
```

## Data Models

### AdminGroup Table Schema

```sql
CREATE TABLE admin_groups (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    admin_user_id BIGINT UNSIGNED NOT NULL,
    group_code VARCHAR(6) UNIQUE NOT NULL,
    group_name VARCHAR(255) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    
    FOREIGN KEY (admin_user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_group_code (group_code),
    INDEX idx_admin_user_id (admin_user_id)
);
```

### Users Table Migration

```sql
-- Add new columns
ALTER TABLE users 
    ADD COLUMN organization_name VARCHAR(255) NULL AFTER role,
    ADD COLUMN department_name VARCHAR(255) NULL AFTER organization_name,
    ADD COLUMN admin_group_id BIGINT UNSIGNED NULL AFTER department_name,
    ADD FOREIGN KEY (admin_group_id) REFERENCES admin_groups(id) ON DELETE SET NULL;

-- Migrate existing data
UPDATE users u
INNER JOIN organizations o ON u.organization_id = o.id
SET u.organization_name = o.name;

UPDATE users u
INNER JOIN departments d ON u.department_id = d.id
SET u.department_name = d.name;

-- Make old columns nullable (keep for backward compatibility)
ALTER TABLE users 
    MODIFY COLUMN organization_id BIGINT UNSIGNED NULL,
    MODIFY COLUMN department_id BIGINT UNSIGNED NULL;
```

### Financial Tables Updates

No schema changes needed for `expenses`, `transfers`, `incomings`, `fund_boxes` tables. The existing `user_id` foreign key is sufficient for group-based scoping through the user's `admin_group_id`.

## Error Handling

### Error Scenarios and Responses

1. **Invalid Group Code**
   - HTTP 404: "Group code not found"
   - Validation error when joining group

2. **Organization Mismatch**
   - HTTP 403: "Cannot join group from different organization"
   - Returned when user's organization doesn't match admin's

3. **User Already in Group**
   - HTTP 409: "User already belongs to a group"
   - Returned when user tries to join second group

4. **Unauthorized Group Access**
   - HTTP 403: "You do not have permission to access this group"
   - Returned when admin tries to access another admin's group

5. **Transfer to Non-Group Member**
   - HTTP 403: "Cannot transfer to user outside your group"
   - Validation error in transfer creation

6. **Group Code Generation Failure**
   - HTTP 500: "Failed to generate unique group code"
   - Retry mechanism with max 10 attempts

### Validation Rules

**Join Group Request**:
```php
[
    'group_code' => 'required|string|size:4,6|exists:admin_groups,group_code',
]
```

**Registration with Organization**:
```php
[
    'organization_name' => 'required|string|min:2|max:255',
    'department_name' => 'nullable|string|min:2|max:255',
    'group_code' => 'nullable|string|size:4,6|exists:admin_groups,group_code',
]
```

## Testing Strategy

### Unit Tests

1. **AdminGroup Model Tests**
   - Test group code generation uniqueness
   - Test member addition/removal
   - Test group code regeneration

2. **AdminGroupService Tests**
   - Test group creation for admin
   - Test user joining with valid/invalid codes
   - Test organization matching validation
   - Test member retrieval and filtering

3. **User Model Tests**
   - Test group membership checks
   - Test data access permissions
   - Test organization name storage

### Integration Tests

1. **Registration Flow Tests**
   - Admin registration creates group
   - User registration with group code
   - User registration without group code
   - Organization name validation

2. **Group Management Tests**
   - Admin views group members
   - Admin removes group member
   - Admin regenerates group code
   - User joins group via code

3. **Data Scoping Tests**
   - Admin sees only group member data
   - Regular user sees only own data
   - Transfer restrictions to group members
   - Cross-group data isolation

4. **API Endpoint Tests**
   - Test all AdminGroupController endpoints
   - Test authentication and authorization
   - Test pagination and filtering
   - Test error responses

### Feature Tests

1. **End-to-End Group Workflow**
   - Admin registers → group created
   - Admin shares code with users
   - Users register with code → join group
   - Admin views all member expenses
   - Admin creates transfer to member
   - Member removed from group → loses access

2. **Multi-Admin Scenario**
   - Multiple admins in same organization
   - Each admin has separate group
   - Data isolation between groups
   - Users can only join one group

3. **Organization Matching**
   - User from different organization cannot join
   - Case-insensitive organization matching
   - Department differences allowed

## Performance Considerations

1. **Indexing Strategy**
   - Index on `admin_groups.group_code` for fast lookups
   - Index on `users.admin_group_id` for group member queries
   - Index on `users.organization_name` for organization filtering

2. **Query Optimization**
   - Use eager loading for group relationships
   - Cache group member lists for admins
   - Use database-level scoping for large datasets

3. **Caching Strategy**
   - Cache admin group codes (TTL: 1 hour)
   - Cache group member counts (TTL: 5 minutes)
   - Invalidate cache on member add/remove

4. **Pagination**
   - Default page size: 15 records
   - Maximum page size: 100 records
   - Use cursor pagination for large member lists

## Security Considerations

1. **Group Code Security**
   - Use cryptographically secure random generation
   - Implement rate limiting on group join attempts
   - Log all group join attempts for audit

2. **Authorization Checks**
   - Verify admin owns group before operations
   - Verify user belongs to group for data access
   - Prevent cross-group data leakage

3. **Data Isolation**
   - Enforce group-based scoping at repository level
   - Use Laravel policies for authorization
   - Audit log all group membership changes

4. **Input Validation**
   - Sanitize organization and department names
   - Validate group code format
   - Prevent SQL injection in text fields
