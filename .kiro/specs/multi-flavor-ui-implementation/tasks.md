# Implementation Plan: Multi-Flavor Application UI

## Task Overview

This implementation plan breaks down the multi-flavor application development into discrete, manageable tasks. Each task builds incrementally on previous work, ensuring the application remains functional throughout development.

## Task List

- [x] 1. Flavor Configuration and Project Setup





  - Set up three flavor configurations (superadmin, admin, user)
  - Create main entry points for each flavor (main_superadmin.dart, main_admin.dart, main_user.dart)
  - Configure build variants in android/build.gradle and ios project
  - Create FlavorConfig class with feature flags and navigation definitions
  - Update app identifiers and names for each flavor
  - _Requirements: 1.1, 1.2, 1.3, 22.1, 22.2, 22.3, 23.1, 23.2_

- [x] 2. Enhanced Data Models




  - [x] 2.1 Update User model with profile image and group fields


    - Add profileImageUrl, organizationName, departmentName fields
    - Add adminGroupId and superadminGroupId fields
    - Update JSON serialization/deserialization
    - _Requirements: 17.1, 17.2, 17.3_
  
  - [x] 2.2 Create multi-currency FundBox model


    - Add balanceUsd, balanceSyp, balanceTry fields
    - Add lastCalculatedAt timestamp
    - Create DTO for API integration
    - _Requirements: 6.1, 6.2, 13.1, 13.2_
  
  - [x] 2.3 Create Exchange model


    - Add fields: userId, transferId, targetCurrency, amountUsd, exchangeRate, convertedAmount
    - Support optional transfer linking
    - Create DTO for API integration
    - _Requirements: 10.1, 10.2, 10.3, 14.1, 14.2_
  
  - [x] 2.4 Update Expense model for multi-currency


    - Add priceUsd, priceSyp, priceTry fields (all nullable)
    - Add hasInvoice boolean flag
    - Update DTO to handle multiple currency fields
    - _Requirements: 11.1, 11.2, 15.1, 15.2_
  
  - [x] 2.5 Create SuperadminGroup and AdminGroup models


    - Add groupCode, groupName, membersCount fields
    - Create DTOs for API integration
    - _Requirements: 1.1, 2.1, 3.1, 4.1, 8.1_

- [x] 3. Balance Verification Service





  - Create BalanceVerificationService class
  - Implement verifyBalance method with currency parameter
  - Implement getCurrentBalances method
  - Add InsufficientBalanceException
  - Integrate with FundBox API datasource
  - Add client-side balance checks before operations
  - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5_

- [x] 4. Authentication Flow Updates




  - [x] 4.1 Update registration API datasource


    - Add support for role parameter (superadmin, admin, user)
    - Add support for super_admin_group_code parameter
    - Handle super_admin_group_code in response
    - Handle admin_group information in response
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2_
  
  - [x] 4.2 Create Superadmin registration page


    - Remove join code input field
    - Add organization_name and admin_group_name fields
    - Handle registration success with group code display
    - Create SuperadminSuccessDialog with copy-to-clipboard
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [x] 4.3 Create Admin registration page

    - Add join code input field (6 characters)
    - Validate join code format
    - Handle registration success with admin group info
    - Create AdminSuccessDialog
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x] 4.4 Create User registration page

    - Add join code input field (6 characters)
    - Validate join code format
    - Handle registration success
    - Create UserSuccessDialog
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5. Flavor-Specific Navigation





  - [x] 5.1 Create AppNavigationBar widget

    - Implement flavor-based navigation destination logic
    - Add Superadmin destinations: Group, Cash, Transfers, Analytics, Profile
    - Add Admin destinations: Group, Cash, Exchange, Expenses, Export, Profile
    - Add User destinations: Home, Exchange, Expenses, Export, Profile
    - _Requirements: 22.1, 22.2, 22.3, 23.1, 23.2, 24.1, 24.2_
  

  - [x] 5.2 Create flavor-specific routing

    - Implement route guards based on flavor
    - Hide routes not available for each flavor
    - Set default home page per flavor
    - _Requirements: 22.4, 22.5, 23.3, 24.3_

- [x] 6. Superadmin Group Management




  - [x] 6.1 Create Superadmin group API datasource

    - Implement GET /api/v1/superadmin/group
    - Implement GET /api/v1/superadmin/group/members with pagination
    - Implement POST /api/v1/superadmin/group/regenerate-code
    - Implement DELETE /api/v1/superadmin/group/members/{id}
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [x] 6.2 Create AdminListCard widget


    - Display Admin profile image as circular avatar
    - Display Admin name and email
    - Handle tap to show Admin details
    - _Requirements: 4.3, 4.4_
  
  - [x] 6.3 Create AdminDetailSheet widget


    - Display Admin's financial box balances (USD, SYP, TRY)
    - Format currency amounts appropriately
    - Show last updated timestamp
    - _Requirements: 4.5, 4.6_
  
  - [x] 6.4 Create Superadmin group management page


    - Display total Admin count
    - Display list of AdminListCard widgets
    - Handle empty state
    - Implement pull-to-refresh
    - _Requirements: 4.1, 4.2, 4.7, 4.8_

- [x] 7. Admin Group Management




  - [x] 7.1 Create Admin group API datasource


    - Implement GET /api/v1/admin/group
    - Implement GET /api/v1/admin/group/members
    - Implement POST /api/v1/admin/group/regenerate
    - Implement DELETE /api/v1/admin/group/members/{id}
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [x] 7.2 Create UserListCard widget


    - Display User profile image as circular avatar
    - Display User name
    - Display User balances in all currencies
    - Handle tap to show User details
    - _Requirements: 8.2, 8.3, 8.4_
  
  - [x] 7.3 Create Admin group management page


    - Display list of UserListCard widgets
    - Display total member count
    - Handle empty state
    - Implement pull-to-refresh
    - _Requirements: 8.1, 8.5, 8.6, 8.7, 8.8_

- [x] 8. User Group Information




  - [x] 8.1 Create User group API datasource


    - Implement POST /api/v1/user/join-group
    - Implement GET /api/v1/user/group-info
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [x] 8.2 Create join group page


    - Add group code input field
    - Validate 6-character format
    - Handle join success
    - Display error messages
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [x] 8.3 Add group info section to User profile


    - Display group code, group name, admin name
    - Display member count and join date
    - Handle not-in-group state
    - _Requirements: 3.6, 3.7, 3.8_

- [x] 9. Multi-Currency Financial Box




  - [x] 9.1 Update FundBox API datasource


    - Support GET /api/v1/fund-box with currency parameter
    - Support GET /api/v1/fund-box?user_id={id} for Admin/Superadmin
    - Handle multi-currency response
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 6.2, 13.1, 13.2_
  
  - [x] 9.2 Create MultiCurrencyBalanceCard widget


    - Display USD, SYP, TRY balances
    - Format each currency appropriately
    - Show last updated timestamp
    - Add loading and error states
    - _Requirements: 5.3, 5.4, 5.5, 13.2, 13.3_
  
  - [x] 9.3 Create Superadmin Financial Box page


    - Display MultiCurrencyBalanceCard
    - Add button to manually add incoming amount
    - Implement add incoming functionality
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  

  - [x] 9.4 Create Admin Financial Box page

    - Display MultiCurrencyBalanceCard
    - Display incoming transfers from Superadmin
    - Display outgoing transfers to Users
    - Add filters (date, user)
    - Add export to PDF button
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_
  
  - [x] 9.5 Create User Financial Box page (Home)


    - Display MultiCurrencyBalanceCard
    - Display incoming transfers from Admin
    - Format transfer information
    - Handle empty state
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_

- [x] 10. Transfer Management





  - [x] 10.1 Update Transfer API datasource


    - Support POST /api/v1/transfers with recipient_user_id
    - Support GET /api/v1/transfers with pagination
    - Support filtering by recipient and date
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  

  - [x] 10.2 Create TransferForm widget

    - Add recipient selector (filtered by role)
    - Add amount input (USD only)
    - Add transfer date picker
    - Add notes field
    - Implement balance verification before submit
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
  
  - [x] 10.3 Create Superadmin Transfers page


    - Display outgoing transfers to Admins
    - Add create transfer button
    - Add filters (recipient Admin, date range)
    - Add export to PDF button
    - Apply filters to export
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [x] 11. Currency Exchange




  - [x] 11.1 Create Exchange API datasource

    - Implement POST /api/v1/exchanges
    - Support target_currency, amount_usd, exchange_rate, converted_amount
    - Support optional transfer_id
    - Implement GET /api/v1/exchanges with currency filter
    - Implement GET /api/v1/exchanges/transfer/{id}
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 14.1, 14.2_
  
  - [x] 11.2 Create ExchangeForm widget


    - Add target currency selector (SYP or TRY)
    - Add USD amount input
    - Add exchange rate OR converted amount input
    - Calculate missing value automatically
    - Add exchange date picker
    - Add notes field
    - Implement balance verification
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 14.1, 14.2_
  
  - [x] 11.3 Create Admin Exchange page


    - Display ExchangeForm
    - Add "Exchange Log" button
    - Implement exchange creation with balance update
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_
  
  - [x] 11.4 Create Admin Exchange Log page

    - Display Admin's own exchanges
    - Display all Users' exchanges in group
    - Show total exchanged amounts (SYP and TRY) in fixed label
    - Add filter by user
    - Add filter by currency
    - Add export to PDF button
    - _Requirements: 10.6, 10.7, 10.8, 10.9, 10.10, 10.11, 10.12_
  
  - [x] 11.5 Create User Exchange page


    - Display ExchangeForm
    - Add "Exchange Log" button
    - Implement exchange creation with balance update
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_
  
  - [x] 11.6 Create User Exchange Log page

    - Display ONLY User's own exchanges
    - Add filter by currency
    - Add export to PDF button
    - _Requirements: 14.6, 14.7, 14.8, 14.9, 14.10_

- [x] 12. Expense Management






  - [x] 12.1 Update Expense API datasource


    - Support multi-currency fields (price_usd, price_syp, price_try)
    - Support POST /api/v1/expenses with currency selection
    - Support GET /api/v1/expenses with filters (date, currency, user)
    - Support invoice upload/download/delete endpoints
    - _Requirements: 11.1, 11.2, 11.3, 15.1, 15.2_
  
  - [x] 12.2 Create ExpenseForm widget


    - Add description input
    - Add currency selector (USD, SYP, TRY)
    - Add amount input
    - Add expense date picker
    - Add invoice photo upload button
    - Implement balance verification before submit
    - _Requirements: 11.3, 11.7, 11.8, 11.9, 11.10, 15.2, 15.3_
  
  - [x] 12.3 Create InvoicePreviewDialog widget


    - Display full-screen invoice image
    - Add zoom controls
    - Add loading indicator
    - Handle image load errors
    - _Requirements: 11.7, 25.1, 25.2, 25.3, 25.4, 25.5, 25.6, 25.7, 25.8_
  
  - [x] 12.4 Create Admin Expenses page



    - Display Admin's own expenses
    - Display all Users' expenses in group
    - Add create expense button
    - Add filters (date, currency, user)
    - Add inline invoice preview button
    - Implement filter persistence
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.9, 11.10_
  
  - [x] 12.5 Create User Expenses page



    - Display ONLY User's own expenses
    - Add create expense button
    - Add filters (date, currency)
    - Add inline invoice preview button
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7, 15.8_
  
  - [x] 12.6 Create Superadmin Expenses page



    - Display expenses grouped by Admin group
    - Show expense summaries per group
    - Add filters (date, Admin group)
    - NO create expense button
    - Display read-only expense details
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [x] 13. Export Functionality




  - [x] 13.1 Update Export API datasource


    - Implement POST /api/v1/export/expenses/pdf
    - Implement POST /api/v1/export/expenses/excel
    - Implement export invoice images endpoint
    - Implement GET /api/v1/export/{id}/status
    - Implement GET /api/v1/export/{id}/download
    - _Requirements: 12.1, 12.2, 12.3, 16.1, 16.2_
  

  - [x] 13.2 Create Admin Export page

    - Add "Export to PDF" button
    - Add "Export to Excel" button
    - Add "Export Invoice Images to PDF Bundle" button
    - Apply active filters from Expenses page
    - Show export progress
    - Handle export completion and download
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8_
  
  - [x] 13.3 Create User Export page


    - Add "Export to PDF" button
    - Add "Export to Excel" button
    - Add "Export Invoice Images to PDF Bundle" button
    - Apply active filters from Expenses page
    - Export ONLY User's own expenses
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7, 16.8_

- [x] 14. Superadmin Analytics




  - [x] 14.1 Create Superadmin Analytics API datasource


    - Implement GET /api/v1/super-admin/analytics
    - Support period parameter (15days, month, all)
    - Parse aggregated analytics response
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [x] 14.2 Create GlobalSummaryCard widget


    - Display total invoices count
    - Display total invoices value
    - Display total transfers count
    - Format numbers appropriately
    - _Requirements: 7.2, 7.3, 7.4_
  

  - [x] 14.3 Create AdminGroupAnalyticsCard widget

    - Display Admin name
    - Display user count in Admin's group
    - Display invoice count and value
    - Display transfer count
    - _Requirements: 7.6_
  
  - [x] 14.4 Create Superadmin Analytics page


    - Display GlobalSummaryCard
    - Display list of AdminGroupAnalyticsCard widgets
    - Add filter by date (15days, month, all)
    - Add filter by Admin group
    - Add export to PDF button
    - Add export to Excel button
    - Apply filters to export
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10_

- [x] 15. Profile Image Upload






  - [x] 15.1 Create image upload service


    - Implement image picker (gallery/camera)
    - Implement image compression (max 1MB)
    - Implement upload to API
    - Handle upload progress
    - _Requirements: 17.1, 17.2, 17.3, 17.4_
  
  - [x] 15.2 Create ProfileImageUpload widget


    - Display current profile image as circular avatar
    - Add upload button
    - Show upload progress
    - Handle upload errors
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 17.7, 17.8_
  
  - [x] 15.3 Integrate profile image in Admin and User profiles


    - Add ProfileImageUpload to profile page
    - Update User model with image URL
    - Display profile images in group management lists
    - _Requirements: 17.5, 17.6, 17.7_

- [x] 16. Filter Persistence




  - Create FilterPersistenceService
  - Store active filters in memory during session
  - Apply filters when navigating between Expenses and Export
  - Provide "Clear Filters" functionality
  - Display active filter count indicator
  - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6, 26.7, 26.8_

- [x] 17. Offline Support




  - [x] 17.1 Implement local caching


    - Cache financial box balances
    - Cache recent expenses
    - Cache recent transfers
    - Cache user profile data
    - _Requirements: 27.1, 27.2, 27.3_
  

  - [x] 17.2 Implement operation queue

    - Queue create/update operations when offline
    - Sync automatically when connection restores
    - Handle sync conflicts
    - _Requirements: 27.4, 27.5_
  

  - [x] 17.3 Add offline indicator

    - Display persistent banner when offline
    - Prevent balance-dependent operations when offline
    - Show cached data with offline indicator
    - _Requirements: 27.6, 27.7, 27.8_

- [x] 18. Loading States and Error Handling


  - [x] 18.1 Create loading state components


    - Create skeleton loaders for lists
    - Create loading indicators for forms
    - Create progress indicators for uploads/exports
    - Implement pull-to-refresh
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6, 28.7, 28.8_
  

  - [x] 18.2 Implement error handling

    - Create error display components (snackbar, dialog)
    - Implement field validation errors
    - Handle network errors with retry
    - Handle server errors with support contact
    - _Requirements: 29.1, 29.2, 29.3, 29.4, 29.5, 29.6, 29.7, 29.8_

- [x] 19. Localization






  - [x] 19.1 Set up localization infrastructure

    - Add flutter_localizations dependency
    - Create ARB files for English and Arabic
    - Generate localization classes
    - _Requirements: 30.1, 30.2_
  
  - [x] 19.2 Translate all UI strings


    - Translate navigation labels
    - Translate form labels and buttons
    - Translate error messages
    - Translate success messages
    - _Requirements: 30.6, 30.7, 30.8_
  
  - [x] 19.3 Implement RTL support


    - Configure RTL layout for Arabic
    - Test all screens in RTL mode
    - Adjust layouts for RTL compatibility
    - _Requirements: 30.5_
  


  - [x] 19.4 Add language switcher




    - Add language option in profile/settings
    - Implement language change functionality
    - Persist language preference
    - _Requirements: 30.3, 30.4_

- [x] 20. Accessibility




  - Add semantic labels to all interactive elements
  - Implement screen reader support
  - Ensure minimum contrast ratio 4.5:1
  - Support text scaling up to 200%
  - Provide alternative text for images
  - Ensure minimum touch target size 48dp
  - Add haptic feedback for important actions
  - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5, 34.6, 34.7, 34.8_

- [x] 21. Responsive Design




  - Adapt layouts for small phones (< 360dp)
  - Adapt layouts for standard phones (360-600dp)
  - Adapt layouts for large phones/small tablets (600-840dp)
  - Adapt layouts for tablets (> 840dp)
  - Use responsive font sizes
  - Test portrait and landscape orientations
  - _Requirements: 31.1, 31.2, 31.3, 31.4, 31.5, 31.6, 31.7, 31.8_

- [x] 22. Performance Optimization



  - Implement image compression and caching
  - Implement list pagination (15 items per page, max 100)
  - Use ListView.builder for efficient rendering
  - Implement lazy loading for images
  - Cache frequently accessed data
  - Batch API requests where possible
  - Implement request debouncing
  - _Requirements: 32.1, 32.2, 32.3, 32.4, 32.5, 32.6, 32.7, 32.8_

- [x] 23. Security Implementation









  - Store tokens in flutter_secure_storage
  - Implement auto-logout after 30 minutes inactivity
  - Encrypt sensitive data at rest
  - Use HTTPS for all API calls
  - Implement certificate pinning
  - Clear all data on logout
  - Validate all user inputs
  - _Requirements: 33.1, 33.2, 33.3, 33.4, 33.5, 33.6, 33.7, 33.8_

- [ ] 24. Unit Tests
  - [ ] 24.1 Test data models
    - Test User model serialization
    - Test FundBox model serialization
    - Test Exchange model serialization
    - Test Expense model serialization
    - Test Group models serialization
    - _Requirements: 35.1_
  
  - [ ] 24.2 Test services
    - Test BalanceVerificationService
    - Test FilterPersistenceService
    - Test ImageUploadService
    - _Requirements: 35.1_
  
  - [ ] 24.3 Test BLoCs
    - Test authentication BLoC
    - Test fund box BLoC
    - Test transfer BLoC
    - Test exchange BLoC
    - Test expense BLoC
    - _Requirements: 35.1_

- [ ] 25. Widget Tests
  - [ ] 25.1 Test registration pages
    - Test SuperadminRegistrationPage
    - Test AdminRegistrationPage
    - Test UserRegistrationPage
    - _Requirements: 35.2_
  
  - [ ] 25.2 Test navigation
    - Test flavor-specific navigation structures
    - Test route guards
    - _Requirements: 35.2_
  
  - [ ] 25.3 Test forms
    - Test TransferForm
    - Test ExchangeForm
    - Test ExpenseForm
    - _Requirements: 35.2_
  
  - [ ] 25.4 Test lists and filters
    - Test expense list with filters
    - Test transfer list with filters
    - Test exchange log with filters
    - _Requirements: 35.2_

- [ ] 26. Integration Tests
  - [ ] 26.1 Test authentication flows
    - Test Superadmin registration and login
    - Test Admin registration with group code
    - Test User registration with group code
    - _Requirements: 35.3_
  
  - [ ] 26.2 Test financial operations
    - Test transfer creation and balance update
    - Test exchange creation and balance update
    - Test expense creation and balance verification
    - _Requirements: 35.3_
  
  - [ ] 26.3 Test group management
    - Test join group flow
    - Test view members flow
    - Test remove member flow
    - _Requirements: 35.3_
  
  - [ ] 26.4 Test export flows
    - Test apply filters and export to PDF
    - Test apply filters and export to Excel
    - Test export invoice images
    - _Requirements: 35.3_

- [x] 27. Flavor-Specific Testing




  - Test Superadmin flavor independently
  - Test Admin flavor independently
  - Test User flavor independently
  - Verify feature flags work correctly
  - Verify navigation is flavor-appropriate
  - Verify data visibility rules
  - _Requirements: 35.5, 35.6_

- [-] 28. Build and Deployment


  - [x] 28.1 Configure build variants


    - Set up Superadmin flavor build configuration
    - Set up Admin flavor build configuration
    - Set up User flavor build configuration
    - Configure app identifiers and names
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 28.2 Create build scripts


    - Create build script for Superadmin APK
    - Create build script for Admin APK
    - Create build script for User APK
    - Create build script for all flavors
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 28.3 Test builds



    - Test Superadmin APK installation and functionality
    - Test Admin APK installation and functionality
    - Test User APK installation and functionality
    - Verify separate app identifiers work correctly
    - _Requirements: 35.5, 35.6_

- [x] 29. Documentation





  - Create user guide for Superadmin flavor
  - Create user guide for Admin flavor
  - Create user guide for User flavor
  - Document API integration points
  - Document flavor configuration
  - Create troubleshooting guide
  - Document testing procedures
  - _Requirements: 35.4, 35.7, 35.8_

- [x] 30. Final Testing and Bug Fixes




  - Perform end-to-end testing for all three flavors
  - Test all user flows
  - Test error scenarios
  - Test offline functionality
  - Fix any discovered bugs
  - Verify all requirements are met
  - _Requirements: 35.3, 35.7, 35.8_
