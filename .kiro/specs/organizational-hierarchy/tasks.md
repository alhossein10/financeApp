# Implementation Plan - Organizational Hierarchy Frontend

- [x] 1. Create domain entities and models





- [x] 1.1 Create Organization entity

  - Create `lib/features/auth/domain/entities/organization.dart`
  - Define Organization class with id and name properties
  - _Requirements: 1.1, 1.2_


- [x] 1.2 Create Department entity

  - Create `lib/features/auth/domain/entities/department.dart`
  - Define Department class with id, organizationId, and name properties
  - _Requirements: 2.1, 2.2_


- [x] 1.3 Create OrganizationModel

  - Create `lib/features/auth/data/models/organization_model.dart`
  - Implement fromJson and toJson methods
  - Extend Organization entity
  - _Requirements: 1.1, 1.2_


- [x] 1.4 Create DepartmentModel

  - Create `lib/features/auth/data/models/department_model.dart`
  - Implement fromJson and toJson methods
  - Extend Department entity
  - _Requirements: 2.1, 2.2_


- [x] 1.5 Update UserModel with organizational fields

  - Add organizationId field (required)
  - Add departmentId field (nullable)
  - Add organization field (optional Organization object)
  - Add department field (optional Department object)
  - Update fromJson to parse organizational data
  - Update toJson to include organizational data
  - _Requirements: 3.1, 3.2, 3.3, 3.6_

- [x] 2. Update API datasource





- [x] 2.1 Add getOrganizations method to AuthApiDataSource


  - Define abstract method in interface
  - Implement method to call `GET /api/v1/organizations`
  - Parse response and return List<OrganizationModel>
  - Handle errors appropriately
  - _Requirements: 9.1, 9.3_

- [x] 2.2 Add getDepartments method to AuthApiDataSource

  - Define abstract method in interface with organizationId parameter
  - Implement method to call `GET /api/v1/organizations/{id}/departments`
  - Parse response and return List<DepartmentModel>
  - Handle errors appropriately
  - _Requirements: 9.2, 9.4, 9.6_

- [x] 2.3 Update register method in AuthApiDataSource

  - Add organizationId parameter (required)
  - Add departmentId parameter (nullable)
  - Add role parameter
  - Update request body to include organizational fields
  - Only include department_id if not null
  - Parse updated user response with organizational data
  - _Requirements: 3.1, 3.2, 3.3, 3.6, 3.7, 3.8_

- [x] 3. Update repository layer





- [x] 3.1 Add getOrganizations method to AuthRepository


  - Define abstract method in repository interface
  - Implement method in AuthRepositoryImpl
  - Call datasource and handle errors
  - Return Either<Failure, List<Organization>>
  - _Requirements: 1.1, 1.2_


- [x] 3.2 Add getDepartments method to AuthRepository

  - Define abstract method in repository interface with organizationId parameter
  - Implement method in AuthRepositoryImpl
  - Call datasource and handle errors
  - Return Either<Failure, List<Department>>
  - _Requirements: 2.1, 2.2_


- [x] 3.3 Update register method in AuthRepository

  - Add organizationId parameter
  - Add departmentId parameter (nullable)
  - Add role parameter
  - Update implementation to pass new parameters to datasource
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 4. Create use cases






- [x] 4.1 Create GetOrganizationsUseCase

  - Create `lib/features/auth/domain/usecases/get_organizations_usecase.dart`
  - Implement call method that returns Either<Failure, List<Organization>>
  - Inject AuthRepository dependency
  - _Requirements: 1.1, 1.2_


- [x] 4.2 Create GetDepartmentsUseCase

  - Create `lib/features/auth/domain/usecases/get_departments_usecase.dart`
  - Implement call method with organizationId parameter
  - Return Either<Failure, List<Department>>
  - Inject AuthRepository dependency
  - _Requirements: 2.1, 2.2_

- [x] 4.3 Update RegisterUseCase


  - Add organizationId parameter
  - Add departmentId parameter (nullable)
  - Add role parameter
  - Update call method to pass new parameters to repository
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 5. Update BLoC layer






- [x] 5.1 Add new events to AuthBloc

  - Create LoadOrganizationsEvent
  - Create LoadDepartmentsEvent with organizationId parameter
  - Create OrganizationSelectedEvent with organizationId parameter
  - Update RegisterSubmittedEvent to include organizationId, departmentId, and role
  - _Requirements: 1.1, 2.1, 3.1_



- [x] 5.2 Update AuthState

  - Add organizations list field
  - Add departments list field
  - Add selectedOrganizationId field
  - Add isLoadingOrganizations boolean field
  - Add isLoadingDepartments boolean field
  - Update copyWith method
  - Update props for Equatable
  - _Requirements: 1.1, 2.1_


- [x] 5.3 Implement LoadOrganizationsEvent handler

  - Set isLoadingOrganizations to true
  - Call GetOrganizationsUseCase
  - On success: update organizations list and set loading to false
  - On failure: emit error state with message
  - _Requirements: 1.1, 1.2, 9.1_

- [x] 5.4 Implement LoadDepartmentsEvent handler


  - Set isLoadingDepartments to true
  - Call GetDepartmentsUseCase with organizationId
  - On success: update departments list and set loading to false
  - On failure: emit error state with message
  - _Requirements: 2.1, 2.2, 9.2_

- [x] 5.5 Update RegisterSubmittedEvent handler


  - Extract organizationId, departmentId, and role from event
  - Call RegisterUseCase with all parameters including organizational fields
  - Handle validation errors from backend
  - On success: emit success state with user data
  - On failure: emit error state with appropriate message
  - _Requirements: 3.1, 3.2, 3.3, 3.6, 3.7, 3.8, 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 6. Create UI widgets






- [x] 6.1 Create OrganizationDropdown widget

  - Create `lib/features/auth/presentation/widgets/organization_dropdown.dart`
  - Accept organizations list, selectedOrganizationId, onChanged callback
  - Add isLoading parameter to show loading indicator
  - Add errorText parameter for validation errors
  - Implement DropdownButtonFormField with Arabic label "المنظمة"
  - Add validator to ensure organization is selected
  - Show loading indicator when isLoading is true
  - _Requirements: 1.1, 1.2, 9.1, 11.1_


- [x] 6.2 Create DepartmentDropdown widget

  - Create `lib/features/auth/presentation/widgets/department_dropdown.dart`
  - Accept departments list, selectedDepartmentId, onChanged callback
  - Add isLoading parameter to show loading indicator
  - Add isRequired parameter (true for regular users, false for admins)
  - Add errorText parameter for validation errors
  - Implement DropdownButtonFormField with Arabic label "القسم"
  - Add conditional validator based on isRequired
  - Disable dropdown when departments list is empty
  - Show loading indicator when isLoading is true
  - _Requirements: 2.1, 2.2, 9.2, 11.2, 11.3, 11.4_

- [x] 7. Update RegisterPage






- [x] 7.1 Add state variables for organizational fields

  - Add _selectedOrganizationId variable
  - Add _selectedDepartmentId variable
  - Add _selectedRole variable (default to 'user')
  - _Requirements: 3.1, 3.2_


- [x] 7.2 Load organizations on page init

  - Override initState method
  - Dispatch LoadOrganizationsEvent to AuthBloc
  - _Requirements: 1.1, 9.1_

- [x] 7.3 Add role selection dropdown


  - Add DropdownButtonFormField for role selection
  - Options: 'user' (مستخدم عادي) and 'admin' (مدير)
  - On role change: clear departmentId if switching to admin
  - _Requirements: 3.2, 3.3_


- [x] 7.4 Add OrganizationDropdown to form

  - Place after role selection field
  - Bind to state.organizations
  - Bind selectedOrganizationId to _selectedOrganizationId
  - On change: update _selectedOrganizationId, clear _selectedDepartmentId, dispatch LoadDepartmentsEvent
  - Show loading state from state.isLoadingOrganizations
  - _Requirements: 1.1, 1.2, 9.1_

- [x] 7.5 Add DepartmentDropdown to form

  - Place after OrganizationDropdown
  - Only show if _selectedRole is 'user'
  - Bind to state.departments
  - Bind selectedDepartmentId to _selectedDepartmentId
  - On change: update _selectedDepartmentId
  - Set isRequired to true for regular users
  - Show loading state from state.isLoadingDepartments
  - _Requirements: 2.1, 2.2, 3.2, 9.2_

- [x] 7.6 Update form submission handler

  - Validate organizationId is not null
  - Validate departmentId is not null for regular users
  - Show appropriate error messages for missing selections
  - Dispatch RegisterSubmittedEvent with all fields including organizational data
  - _Requirements: 3.1, 3.2, 3.3, 3.6, 11.1, 11.4_

- [x] 7.7 Add BLoC listener for error handling

  - Listen to AuthState changes
  - On registration failure: show SnackBar with error message
  - On registration success: navigate to home page
  - Handle specific validation errors from backend
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 8. Update dependency injection



- [x] 8.1 Register new use cases in injection container

  - Register GetOrganizationsUseCase
  - Register GetDepartmentsUseCase
  - Inject AuthRepository dependency
  - _Requirements: 1.1, 2.1_

- [x] 8.2 Update AuthBloc registration

  - Inject GetOrganizationsUseCase
  - Inject GetDepartmentsUseCase
  - Ensure RegisterUseCase is updated
  - _Requirements: 1.1, 2.1, 3.1_

- [x] 9. Add localization strings





- [x] 9.1 Add Arabic strings to ar.arb


  - Add "organization": "المنظمة"
  - Add "department": "القسم"
  - Add "selectOrganization": "اختر المنظمة"
  - Add "selectDepartment": "اختر القسم"
  - Add "organizationRequired": "الرجاء اختيار المنظمة"
  - Add "departmentRequired": "الرجاء اختيار القسم"
  - Add "regularUser": "مستخدم عادي"
  - Add "adminUser": "مدير"
  - Add "userType": "نوع المستخدم"
  - _Requirements: 11.1, 11.2, 11.4_

- [x] 9.2 Add English strings to en.arb


  - Add "organization": "Organization"
  - Add "department": "Department"
  - Add "selectOrganization": "Select Organization"
  - Add "selectDepartment": "Select Department"
  - Add "organizationRequired": "Please select an organization"
  - Add "departmentRequired": "Please select a department"
  - Add "regularUser": "Regular User"
  - Add "adminUser": "Administrator"
  - Add "userType": "User Type"
  - _Requirements: 11.1, 11.2, 11.4_

- [x] 10. Testing and validation







- [x] 10.1 Test registration flow for regular user


  - Open registration page
  - Verify organizations load automatically
  - Select organization
  - Verify departments load for selected organization
  - Select department
  - Fill in other fields
  - Submit form
  - Verify successful registration with organizational data
  - _Requirements: 3.1, 3.2, 3.3, 3.6_

- [x] 10.2 Test registration flow for admin user



  - Open registration page
  - Select admin role
  - Verify department field is hidden
  - Select organization only
  - Fill in other fields
  - Submit form
  - Verify successful registration without department
  - _Requirements: 3.2, 3.3_


- [x] 10.3 Test validation errors

  - Try submitting without selecting organization
  - Verify error message appears
  - Try submitting as regular user without selecting department
  - Verify error message appears
  - Test backend validation errors display correctly
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_



- [x] 10.4 Test error handling
  - Test with backend offline (organizations endpoint)
  - Verify error message and retry option
  - Test with backend offline (departments endpoint)
  - Verify error message and retry option
  - Test with invalid organization ID
  - Verify appropriate error message
  - _Requirements: 11.1, 11.2, 11.3_



- [x] 10.5 Test UI responsiveness
  - Verify loading indicators show during API calls
  - Verify dropdowns are disabled during loading
  - Verify smooth transitions between states
  - Test on different screen sizes
  - _Requirements: 1.1, 2.1_
