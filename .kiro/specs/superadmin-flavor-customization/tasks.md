# Implementation Plan

## Overview

This implementation plan breaks down the SuperAdmin flavor customization into discrete, manageable coding tasks. Each task builds incrementally on previous work to create a complete SuperAdmin experience with group code generation, unified cash management, and aggregated expense monitoring.

---

## Tasks

- [x] 1. Update FlavorConfig for SuperAdmin




  - Update `FlavorConfig` class in `lib/core/config/flavor_config.dart` to add new configuration flags for SuperAdmin
  - Add `enableSuperAdminCashPage`, `enableSuperAdminExpensesPage`, `showIncomingTransfers`, and `showExchangeHistory` boolean flags
  - Configure SuperAdmin flavor with: `enableCurrencyModule: false`, `enableExportModule: false`, `showIncomingTransfers: false`, `showExchangeHistory: false`
  - _Requirements: 3.4, 5.3, 6.3, 7.2_

- [x] 2. Create SuperAdmin Registration Success Dialog





  - [x] 2.1 Create dialog widget

    - Create `SuperAdminRegistrationSuccessDialog` widget in `lib/features/auth/presentation/widgets/superadmin_registration_success_dialog.dart`
    - Accept `groupCode` and `adminGroupName` as required parameters
    - Display group code prominently with copy-to-clipboard button
    - Include explanatory text about sharing code with admins
    - Add "Continue" button to dismiss and navigate to home
    - _Requirements: 1.2, 1.3, 1.4_
  

  - [x] 2.2 Integrate dialog with registration flow

    - Modify `AuthBloc` to detect SuperAdmin flavor during registration
    - Extract `groupCode` and `adminGroupName` from registration API response
    - Update `AuthState` to include optional `groupCode` and `adminGroupName` fields
    - Show dialog when SuperAdmin registration succeeds with group code
    - _Requirements: 1.1, 1.5_

- [x] 3. Create SuperAdmin Cash Page





  - [x] 3.1 Create page structure


    - Create `SuperAdminCashPage` widget in `lib/ui/superadmin_cash_page.dart`
    - Add fund box balance display section at top
    - Add "Create Outgoing Transfer" button
    - Add outgoing transfers list section
    - Use existing `FundBoxBloc` and `TransferBloc`
    - _Requirements: 2.2, 2.6_
  
  - [x] 3.2 Implement transfer filtering


    - Add `TransferType` enum (incoming, outgoing, all) to transfer domain
    - Modify `LoadTransfersEvent` to accept `TransferType` parameter
    - Update `TransferBloc` to filter transfers by type
    - Filter SuperAdmin cash page to show only outgoing transfers
    - _Requirements: 2.3, 2.4_
  
  - [x] 3.3 Implement recipient filtering for transfer creation


    - Modify transfer creation flow to filter recipients
    - Show only admin users from SuperAdmin's group as recipients
    - Integrate with `AdminGroupBloc` to get group members
    - Filter members by role to show only admins
    - _Requirements: 2.6_

- [x] 4. Create SuperAdmin Expenses Page





  - [x] 4.1 Create expense summary data models


    - Create `AdminGroupExpenseSummary` model with fields: adminGroupId, adminGroupName, totalAmount, expenseCount, pendingCount, approvedCount, rejectedCount
    - Create `SuperAdminExpenseView` model with fields: groupSummaries list, grandTotal, totalExpenseCount
    - Create DTOs for API integration
    - _Requirements: 4.2, 4.3_
  
  - [x] 4.2 Create API datasource for expense summaries


    - Create `SuperAdminExpenseApiDatasource` in `lib/features/expenses/data/datasources/`
    - Implement `getExpenseSummary()` method calling `GET /api/superadmin/expenses/summary`
    - Implement `getExpensesByGroup(groupId)` method calling `GET /api/superadmin/expenses/by-group/{groupId}`
    - Handle API errors and map responses to domain models
    - _Requirements: 4.2, 4.6_
  
  - [x] 4.3 Create SuperAdmin expenses page UI


    - Create `SuperAdminExpensesPage` widget in `lib/ui/superadmin_expenses_page.dart`
    - Remove "Add Expense" button (no expense creation for SuperAdmin)
    - Display expense summary cards grouped by admin group
    - Show total amount, count, and status breakdown per group
    - Add "View Details" button for each group
    - _Requirements: 4.1, 4.2, 4.3, 4.7_
  
  - [x] 4.4 Implement filtering and drill-down

    - Add admin group filter dropdown at top of page
    - Implement filtering logic to show selected group or all groups
    - Create detail view page showing individual expenses for selected group
    - Make detail view read-only (no edit/delete actions)
    - _Requirements: 4.4, 4.5, 4.6_

- [x] 5. Update Navigation for SuperAdmin





  - [x] 5.1 Modify HomeScaffold navigation builder


    - Update `_buildPages()` method in `lib/main.dart` to check for SuperAdmin flavor
    - For SuperAdmin: add Group Management, SuperAdmin Cash Page, SuperAdmin Expenses Page, Profile
    - Remove Currency Exchange, Export, Exchange History, User Cash Inbox pages for SuperAdmin
    - _Requirements: 7.1, 3.1, 3.2, 3.3, 5.1, 5.2, 6.1, 6.2_
  

  - [x] 5.2 Update navigation destinations

    - Update `destinations` list in HomeScaffold to match SuperAdmin pages
    - Use appropriate icons: Groups, Wallet, Receipt, Person
    - Update labels using localization keys
    - Ensure navigation order matches requirements: Group Management, Cash, Expenses, Profile
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 6. Add Localization Support





  - Add Arabic and English translations for all new UI elements
  - Add keys: `superadmin_registration_success`, `group_code_generated`, `share_with_admins`, `copy_group_code`
  - Add keys: `outgoing_transfers`, `create_outgoing_transfer`
  - Add keys: `expense_overview`, `admin_group_summary`, `view_group_details`
  - Add keys: `total_expenses`, `pending_expenses`, `approved_expenses`, `rejected_expenses`
  - Update `lib/l10n/app_localizations.dart` with new translations
  - _Requirements: All requirements (localization support)_

- [x] 7. Update Registration Page for SuperAdmin





  - Modify `RegisterPage` to detect SuperAdmin flavor
  - Listen for `AuthAuthenticated` state with group code
  - Show `SuperAdminRegistrationSuccessDialog` when group code is present
  - Handle dialog dismissal and navigation to home
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 8. Update Main Entry Point





  - Verify `main_superadmin.dart` initializes SuperAdmin flavor correctly
  - Ensure Supabase service initialization (if needed for SuperAdmin)
  - Verify dependency injection includes all SuperAdmin-specific services
  - _Requirements: All requirements (app initialization)_

- [ ] 9. Write Unit Tests






  - [x] 9.1 Test FlavorConfig for SuperAdmin



    - Test SuperAdmin configuration flags are set correctly
    - Test navigation item generation based on SuperAdmin flags
    - Test feature enablement logic
    - _Requirements: 1.1-7.5_
  

  - [x] 9.2 Test SuperAdmin Cash Page logic


    - Test transfer filtering (outgoing only)
    - Test recipient filtering (admins only)
    - Test fund box data loading
    - _Requirements: 2.1-2.6_
  

  - [x] 9.3 Test SuperAdmin Expenses Page logic


    - Test expense summary aggregation
    - Test group filtering
    - Test drill-down navigation
    - _Requirements: 4.1-4.7_

- [x] 10. Write Widget Tests







  - [x] 10.1 Test SuperAdmin Registration Success Dialog



    - Test group code display
    - Test copy-to-clipboard functionality
    - Test navigation after dismissal
    - _Requirements: 1.1-1.5_
  
  - [x] 10.2 Test SuperAdmin Cash Page UI



    - Test UI rendering with mock data
    - Test empty states
    - Test error states
    - _Requirements: 2.1-2.6_
  
  - [x] 10.3 Test SuperAdmin Expenses Page UI



    - Test summary card rendering
    - Test filtering functionality
    - Test navigation to details
    - _Requirements: 4.1-4.7_

- [-] 11. Write Integration Tests




  - [x] 11.1 Test registration flow



    - Test complete registration with group code generation
    - Test dialog display and dismissal
    - Test navigation to home
    - _Requirements: 1.1-1.5_
  



  - [x] 11.2 Test cash page flow


    - Test loading fund box and transfers
    - Test creating outgoing transfer
    - Test transfer list updates
    - _Requirements: 2.1-2.6_
  

  - [x] 11.3 Test expenses page flow





    - Test loading expense summaries
    - Test filtering by group
    - Test drill-down to details
    - _Requirements: 4.1-4.7_

- [x] 12. Documentation and Polish





  - Create user guide for SuperAdmin features
  - Document API endpoints required for backend team
  - Add code comments for SuperAdmin-specific logic
  - Update README with SuperAdmin flavor build instructions
  - _Requirements: All requirements (documentation)_
