# Admin Group Management Integration - Requirements

## Introduction

This specification defines the requirements for integrating the Admin Group Management feature into the Flutter frontend application. The backend has implemented a group-based access control system using 6-character group codes, replacing the traditional organization/department dropdown selection.

## Glossary

- **Admin Group**: A collection of users managed by an admin user, identified by a unique 6-character code
- **Group Code**: A unique 6-character alphanumeric identifier for an admin group (case-insensitive)
- **Admin User**: A user with the 'admin' role who can create and manage a group
- **Regular User**: A user with the 'user' role who joins an admin's group
- **Organization Name**: Free-text field for organization identification (replaces organization_id)
- **Department Name**: Free-text field for department identification (replaces department_id)
- **Data Scoping**: Filtering of financial data based on admin group membership

## Requirements

### Requirement 1: Registration Flow Update

**User Story:** As a user, I want to register using a group code system so that I can join my admin's group easily.

#### Acceptance Criteria

1. WHEN an admin registers, THE System SHALL auto-create an admin group with a unique 6-character group code
2. WHEN an admin completes registration, THE System SHALL display the generated group code prominently with a copy-to-clipboard button
3. WHEN a regular user registers, THE System SHALL require a valid 6-character group code
4. WHEN a user enters a group code, THE System SHALL validate the format (exactly 6 alphanumeric characters, case-insensitive)
5. WHEN a user submits registration with an invalid group code, THE System SHALL display an error message below the group code input field
6. WHEN organization or department fields are displayed, THE System SHALL show them as optional text input fields (not dropdowns)
7. WHEN a user submits registration, THE System SHALL send organization_name and department_name as text (not organization_id and department_id)

### Requirement 2: Admin Group Management

**User Story:** As an admin, I want to manage my group members so that I can control who has access to our financial data.

#### Acceptance Criteria

1. WHEN an admin navigates to the group management section, THE System SHALL display the current group code with a copy button
2. WHEN an admin views the group management section, THE System SHALL display the total member count
3. WHEN an admin requests the member list, THE System SHALL display all group members with their name, email, and department
4. WHEN an admin clicks the remove button for a member, THE System SHALL show a confirmation dialog
5. WHEN an admin confirms member removal, THE System SHALL remove the user from the group and refresh the member list
6. WHEN an admin attempts to remove themselves, THE System SHALL disable the remove button
7. WHEN an admin clicks regenerate code, THE System SHALL show a warning dialog about code invalidation
8. WHEN an admin confirms code regeneration, THE System SHALL generate a new code and display it prominently

### Requirement 3: User Group Information

**User Story:** As a regular user, I want to view my group information so that I know which admin group I belong to.

#### Acceptance Criteria

1. WHEN a user navigates to their profile or settings, THE System SHALL display a "My Group" section
2. WHEN a user views the group section, THE System SHALL display the group code, group name, admin name, and admin email
3. WHEN a user views the group section, THE System SHALL display the total member count
4. WHEN a user views the group section, THE System SHALL display the date they joined the group
5. WHEN a user is not in any group, THE System SHALL display a message indicating they are not in a group
6. WHEN a user is not in a group, THE System SHALL provide an option to join a group using a code

### Requirement 4: Join Group Functionality

**User Story:** As a user, I want to join an admin group after registration so that I can access shared financial data.

#### Acceptance Criteria

1. WHEN a user without a group accesses the join group feature, THE System SHALL display a group code input field
2. WHEN a user enters a 6-character code, THE System SHALL validate the format
3. WHEN a user submits a valid group code, THE System SHALL add the user to the admin's group
4. WHEN a user successfully joins a group, THE System SHALL display a success message with the group name
5. WHEN a user attempts to join while already in a group, THE System SHALL display an error message
6. WHEN a user enters an invalid or non-existent code, THE System SHALL display an appropriate error message

### Requirement 5: Data Model Updates

**User Story:** As a developer, I want updated data models so that the app can handle the new group-based structure.

#### Acceptance Criteria

1. THE User model SHALL include organization_name as a nullable string field
2. THE User model SHALL include department_name as a nullable string field
3. THE User model SHALL include admin_group_id as a nullable integer field
4. THE System SHALL create an AdminGroup model with id, admin_user_id, group_code, group_name, is_active, members_count, created_at, and updated_at fields
5. THE System SHALL create a GroupMember model with id, name, email, role, organization_name, department_name, and created_at fields
6. THE System SHALL create a GroupInfo model with group_code, group_name, admin_name, admin_email, members_count, and joined_at fields

### Requirement 6: API Integration

**User Story:** As a developer, I want API service methods for group management so that the app can communicate with the backend.

#### Acceptance Criteria

1. THE System SHALL implement GET /api/v1/admin/group endpoint to retrieve admin group information
2. THE System SHALL implement POST /api/v1/admin/group/regenerate endpoint to regenerate group codes
3. THE System SHALL implement GET /api/v1/admin/group/members endpoint to retrieve group members
4. THE System SHALL implement DELETE /api/v1/admin/group/members/{id} endpoint to remove members
5. THE System SHALL implement POST /api/v1/user/join-group endpoint to join groups
6. THE System SHALL implement GET /api/v1/user/group-info endpoint to retrieve user group information
7. WHEN any API call fails, THE System SHALL handle errors appropriately and display user-friendly messages

### Requirement 7: UI/UX Updates

**User Story:** As a user, I want an intuitive interface for group management so that I can easily manage or view my group.

#### Acceptance Criteria

1. WHEN displaying a group code, THE System SHALL provide a copy-to-clipboard button
2. WHEN a user copies a group code, THE System SHALL display a confirmation message
3. WHEN displaying the member list, THE System SHALL show member information in a clear, organized format
4. WHEN displaying forms, THE System SHALL use consistent styling with the existing app design
5. WHEN showing loading states, THE System SHALL display appropriate loading indicators
6. WHEN displaying errors, THE System SHALL show clear, actionable error messages
7. THE System SHALL support both English and Arabic languages for all new UI elements

### Requirement 8: Backward Compatibility

**User Story:** As a developer, I want to maintain backward compatibility so that existing users are not affected during the transition.

#### Acceptance Criteria

1. THE System SHALL continue to accept organization_id and department_id in API responses
2. THE System SHALL prioritize organization_name and department_name over organization_id and department_id when both are present
3. WHEN migrating existing users, THE System SHALL handle users without admin_group_id gracefully
4. THE System SHALL not break existing functionality during the transition period

### Requirement 9: Data Scoping

**User Story:** As a user, I want to see only data from my group members so that financial information remains private to my group.

#### Acceptance Criteria

1. WHEN a user views expenses, THE System SHALL display only expenses from users in their admin group
2. WHEN a user views transfers, THE System SHALL display only transfers from users in their admin group
3. WHEN a user views incoming transactions, THE System SHALL display only incoming from users in their admin group
4. WHEN a user views fund boxes, THE System SHALL display only fund boxes from users in their admin group
5. WHEN an admin views dashboard statistics, THE System SHALL calculate statistics based only on their group members' data

### Requirement 10: Error Handling

**User Story:** As a user, I want clear error messages so that I understand what went wrong and how to fix it.

#### Acceptance Criteria

1. WHEN a group code is invalid, THE System SHALL display "The selected group code is invalid"
2. WHEN a group code is required but missing, THE System SHALL display "The group code field is required"
3. WHEN a user is already in a group, THE System SHALL display "You are already in a group"
4. WHEN an admin tries to join another group, THE System SHALL display "Admins cannot join other groups"
5. WHEN a member cannot be found, THE System SHALL display "User not found or not in your group"
6. WHEN network errors occur, THE System SHALL display appropriate connectivity error messages
7. WHEN API errors occur, THE System SHALL log the error details for debugging

### Requirement 11: Testing

**User Story:** As a developer, I want comprehensive tests so that the group management feature works reliably.

#### Acceptance Criteria

1. THE System SHALL include unit tests for all new data models
2. THE System SHALL include unit tests for all new API service methods
3. THE System SHALL include widget tests for registration page changes
4. THE System SHALL include widget tests for group management screens
5. THE System SHALL include integration tests for the complete registration flow
6. THE System SHALL include integration tests for group management operations
7. THE System SHALL achieve at least 80% code coverage for new code
