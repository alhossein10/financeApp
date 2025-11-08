 # Implementation Plan

- [x] 1. Create AdminGroup model and migration




  - Create `admin_groups` table migration with columns: id, admin_user_id, group_code, group_name, is_active, timestamps
  - Add indexes on group_code and admin_user_id
  - Add foreign key constraint to users table
  - Create AdminGroup model with fillable fields and relationships
  - Implement `generateUniqueGroupCode()` static method using secure random generation
  - Implement `regenerateGroupCode()` instance method
  - _Requirements: 2.1, 2.2, 2.3, 10.1, 10.2, 10.3, 10.4_

- [x] 2. Update Users table for free-text organization and group membership





  - Create migration to add organization_name, department_name, admin_group_id columns to users table
  - Migrate existing organization_id and department_id data to new text fields
  - Make old organization_id and department_id nullable for backward compatibility
  - Add foreign key for admin_group_id referencing admin_groups table
  - Update User model fillable array with new fields
  - Add adminGroup() and managedGroup() relationships to User model
  - Implement helper methods: isGroupMember(), getGroupAdmin(), canAccessUser()
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 3.6_

- [x] 3. Create AdminGroupRepository





  - Create AdminGroupRepository extending BaseRepository
  - Implement findByGroupCode() method
  - Implement findByAdmin() method
  - Implement getGroupMembers() with pagination and filters
  - Implement isGroupCodeUnique() method
  - Implement updateGroupCode() method
  - _Requirements: 2.1, 2.2, 3.1, 4.1, 4.2_

- [x] 4. Create AdminGroupService





  - Create AdminGroupService with AdminGroupRepository dependency injection
  - Implement createGroupForAdmin() to generate group when admin registers
  - Implement getAdminGroup() to retrieve admin's group
  - Implement regenerateGroupCode() with uniqueness validation
  - Implement joinGroupByCode() with organization matching validation
  - Implement validateGroupCodeForUser() for organization name comparison (case-insensitive)
  - Implement getGroupMembers() with pagination
  - Implement removeMemberFromGroup() with authorization checks
  - Implement getAvailableTransferRecipients() for transfer restrictions
  - _Requirements: 2.1, 2.2, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 7.1, 7.2, 7.3, 8.1, 8.2, 8.3, 8.4, 9.1, 9.2, 9.3_

- [x] 5. Update AuthService for group-based registration





  - Modify register() method to accept organization_name and department_name as text fields
  - Add logic to create AdminGroup automatically when admin user registers
  - Add optional group_code parameter handling in registration
  - Implement validation for organization_name (required, 2-255 chars)
  - Implement validation for department_name (optional, 2-255 chars)
  - Call AdminGroupService to join group if group_code provided
  - Update token generation to include group information
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 6. Update RegisterRequest validation





  - Replace organization_id and department_id validation with organization_name and department_name
  - Add validation rules for organization_name (required, string, min:2, max:255)
  - Add validation rules for department_name (nullable, string, min:2, max:255)
  - Add optional group_code validation (nullable, string, digits_between:4,6)
  - Remove foreign key existence checks for organization and department
  - Add custom validation to check group_code exists if provided
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.1, 3.2, 10.2, 10.3_

- [x] 7. Create AdminGroupController





  - Create AdminGroupController with AdminGroupService dependency
  - Implement getAdminGroup() endpoint (GET /api/admin/group) to return group info and code
  - Implement regenerateGroupCode() endpoint (POST /api/admin/group/regenerate)
  - Implement getGroupMembers() endpoint (GET /api/admin/group/members) with pagination
  - Implement removeMember() endpoint (DELETE /api/admin/group/members/{id})
  - Implement joinGroup() endpoint (POST /api/user/join-group) for users to join via code
  - Implement getGroupInfo() endpoint (GET /api/user/group-info) for users to see their group
  - Add authorization middleware to ensure only admins access admin endpoints
  - _Requirements: 2.4, 2.5, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 8. Add API routes for admin group management





  - Add admin group routes to routes/api.php or routes/api_v1.php
  - Group admin routes under 'admin' prefix with auth:sanctum middleware
  - Add role:admin middleware for admin-only endpoints
  - Add user group routes under 'user' prefix with auth:sanctum middleware
  - Document all new endpoints with comments
  - _Requirements: 2.4, 2.5, 3.1, 4.1, 4.2, 4.3, 4.4_

- [x] 9. Update ExpenseRepository for group-based data scoping





  - Modify getAllExpenses() to accept User parameter
  - Add logic to scope expenses by admin_group_id for admin users
  - Add logic to scope expenses by user_id for regular users
  - Ensure admins only see expenses from their group members
  - Ensure regular users only see their own expenses
  - _Requirements: 5.1, 6.1_

- [x] 10. Update TransferRepository for group-based data scoping





  - Modify getAllTransfers() to accept User parameter
  - Add logic to scope transfers by admin_group_id for admin users
  - Add logic to scope transfers by user_id for regular users
  - Ensure admins only see transfers from their group members
  - Ensure regular users only see their own transfers
  - _Requirements: 5.2, 6.2_

- [x] 11. Update IncomingRepository for group-based data scoping





  - Modify getAllIncomings() to accept User parameter
  - Add logic to scope incoming transactions by admin_group_id for admin users
  - Add logic to scope incoming transactions by user_id for regular users
  - Ensure admins only see incoming transactions from their group members
  - Ensure regular users only see their own incoming transactions
  - _Requirements: 5.3, 6.3_

- [x] 12. Update TransferService for group member validation





  - Add validation in createTransfer() to check recipient is in admin's group
  - Use AdminGroupService to get available transfer recipients
  - Return error if admin tries to transfer to user outside their group
  - Ensure regular users can only transfer to themselves or within their group
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 13. Update StoreTransferRequest validation





  - Add custom validation rule to check recipient_user_id is in admin's group
  - Use AdminGroupService to validate group membership
  - Return appropriate error message if validation fails
  - _Requirements: 7.1, 7.2_

- [x] 14. Update ExpenseService to pass User parameter







  - Modify getAllExpenses() calls to pass authenticated user
  - Ensure service layer properly delegates to repository with user context
  - _Requirements: 5.1, 6.1_

- [x] 15. Update TransferService to pass User parameter





  - Modify getAllTransfers() calls to pass authenticated user
  - Ensure service layer properly delegates to repository with user context
  - _Requirements: 5.2, 6.2_

- [x] 16. Update IncomingService to pass User parameter




  - Modify getAllIncomings() calls to pass authenticated user
  - Ensure service layer properly delegates to repository with user context
  - _Requirements: 5.3, 6.3_

- [x] 17. Update ExpenseController to use group-scoped data





  - Modify index() method to pass authenticated user to service
  - Ensure admins see group expenses and users see only their own
  - _Requirements: 5.1, 6.1_

- [x] 18. Update TransferController to use group-scoped data





  - Modify index() method to pass authenticated user to service
  - Ensure admins see group transfers and users see only their own
  - _Requirements: 5.2, 6.2_

- [x] 19. Update IncomingController to use group-scoped data





  - Modify index() method to pass authenticated user to service
  - Ensure admins see group incoming transactions and users see only their own
  - _Requirements: 5.3, 6.3_

- [x] 20. Update FundBoxService and Repository for group scoping





  - Modify fund box queries to scope by admin_group_id for admins
  - Ensure regular users only see their own fund box data
  - Update FundBoxController to pass user context
  - _Requirements: 5.4, 6.4_

- [x] 21. Create database seeders for testing





  - Create AdminGroupSeeder with sample admin users and groups
  - Create sample group codes for testing
  - Create sample regular users assigned to different groups
  - Create sample expenses, transfers for different groups to test data isolation
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 22. Update API documentation





  - Document new admin group endpoints in OpenAPI/Swagger
  - Document updated registration endpoint with organization_name and group_code
  - Document group code format and validation rules
  - Add examples for group management workflows
  - _Requirements: All requirements_

- [x] 23. Write integration tests for admin group management






  - Test admin registration creates group with unique code
  - Test user registration with valid group code joins group
  - Test user registration with invalid group code fails
  - Test organization mismatch prevents group joining
  - Test admin can view group members
  - Test admin can remove group members
  - Test admin can regenerate group code
  - Test user cannot join multiple groups
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 24. Write integration tests for data scoping






  - Test admin sees only group member expenses
  - Test admin sees only group member transfers
  - Test admin sees only group member incoming transactions
  - Test regular user sees only own expenses
  - Test regular user sees only own transfers
  - Test regular user sees only own incoming transactions
  - Test cross-group data isolation (admin A cannot see admin B's group data)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 9.3_

- [x] 25. Write integration tests for transfer restrictions






  - Test admin can transfer to group members
  - Test admin cannot transfer to non-group members
  - Test transfer validation returns appropriate errors
  - Test regular user transfer restrictions
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_


- [x] 26. Write unit tests for AdminGroup model






  - Test generateUniqueGroupCode() generates valid codes
  - Test group code uniqueness validation
  - Test regenerateGroupCode() creates new unique code
  - Test group member relationships
  - _Requirements: 2.1, 2.2, 2.3, 10.1, 10.2, 10.3, 10.4_

- [x] 27. Write unit tests for AdminGroupService






  - Test createGroupForAdmin() logic
  - Test joinGroupByCode() with valid and invalid codes
  - Test validateGroupCodeForUser() organization matching
  - Test getGroupMembers() pagination
  - Test removeMemberFromGroup() authorization
  - _Requirements: 2.1, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 8.1, 8.2, 8.3_


- [x] 28. Write feature tests for multi-admin scenarios






  - Test multiple admins in same organization with separate groups
  - Test data isolation between different admin groups
  - Test users can only join one group at a time
  - Test group code uniqueness across all admins
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 29. Update Postman collection




  - Add admin group management endpoints to Postman collection
  - Add example requests for group creation, joining, and management
  - Add test scripts for group workflows
  - Update registration examples with organization_name and group_code
  - _Requirements: All requirements_

- [x] 30. Create migration rollback strategy





  - Document rollback steps for organization_name migration
  - Create down() methods for all migrations
  - Test rollback to ensure data integrity
  - Document how to revert to old organization/department system
  - _Requirements: All requirements_
