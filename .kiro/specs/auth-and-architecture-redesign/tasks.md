# Implementation Plan

- [x] 1. Set up project dependencies and folder structure





  - Add required dependencies to pubspec.yaml (flutter_bloc, get_it, dartz, flutter_secure_storage, crypto, bcrypt, uuid, equatable)
  - Create clean architecture folder structure: lib/core, lib/features, lib/injection_container.dart
  - Create feature folders: lib/features/auth, lib/features/transfers, lib/features/expenses, lib/features/fund_box
  - Within each feature create: data, domain, presentation subfolders
  - _Requirements: 5.1, 5.2, 5.3, 7.1_

- [x] 2. Implement core utilities and error handling





  - Create lib/core/error/failures.dart with Failure classes (DatabaseFailure, AuthenticationFailure, ValidationFailure, etc.)
  - Create lib/core/error/exceptions.dart with Exception classes
  - Create lib/core/utils/validators.dart with email, password validation functions
  - Create lib/core/utils/constants.dart for app-wide constants
  - _Requirements: 11.1, 11.2, 11.3, 1.4, 2.7_

- [x] 3. Database migration for multi-user support





  - Update lib/data/db.dart to version 5
  - Create users table with id, username, email, password_hash, profile_picture_path, created_at, updated_at, last_login
  - Create sessions table with id, user_id, token, created_at, expires_at, last_activity
  - Create password_reset_tokens table with id, user_id, token, created_at, expires_at, used
  - Add user_id column to fund_box, transfers, incoming, expenses tables
  - Create default user in migration and associate existing data with that user
  - Add indexes on user_id columns for performance
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [x] 4. Implement authentication domain layer





  - Create lib/features/auth/domain/entities/user.dart entity
  - Create lib/features/auth/domain/entities/session.dart entity
  - Create lib/features/auth/domain/repositories/auth_repository.dart interface
  - Create lib/features/auth/domain/usecases/login_usecase.dart with validation
  - Create lib/features/auth/domain/usecases/register_usecase.dart with validation
  - Create lib/features/auth/domain/usecases/logout_usecase.dart
  - Create lib/features/auth/domain/usecases/get_current_user_usecase.dart
  - Create lib/features/auth/domain/usecases/check_auth_status_usecase.dart
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 1.8, 5.3, 5.5_

- [x] 5. Implement authentication data layer





  - Create lib/features/auth/data/models/user_model.dart extending User entity
  - Create lib/features/auth/data/models/session_model.dart extending Session entity
  - Create lib/features/auth/data/datasources/auth_local_datasource.dart interface
  - Implement lib/features/auth/data/datasources/auth_local_datasource_impl.dart with SQLite operations
  - Implement password hashing using crypto package (bcrypt alternative for Flutter)
  - Implement token generation using uuid package
  - Implement lib/features/auth/data/repositories/auth_repository_impl.dart
  - _Requirements: 1.3, 1.8, 8.1, 8.2, 9.1, 9.2_

- [x] 6. Implement session management





  - Create lib/core/services/session_manager.dart
  - Implement session creation with token generation
  - Implement session validation with expiration check
  - Implement session refresh mechanism
  - Implement session clearing on logout
  - Use flutter_secure_storage for token persistence
  - _Requirements: 1.8, 1.9, 9.1, 9.2, 9.3, 9.4, 9.5, 8.1_

- [x] 7. Implement authentication presentation layer (BLoC)





  - Create lib/features/auth/presentation/bloc/auth_event.dart with events (LoginRequested, RegisterRequested, LogoutRequested, CheckAuthRequested)
  - Create lib/features/auth/presentation/bloc/auth_state.dart with states (Initial, Loading, Authenticated, Unauthenticated, Error)
  - Create lib/features/auth/presentation/bloc/auth_bloc.dart implementing event handlers
  - Handle authentication state changes and emit appropriate states
  - _Requirements: 1.1, 1.5, 1.6, 1.10, 6.1, 6.2, 6.3, 6.6_

- [x] 8. Create authentication UI screens





  - Create lib/features/auth/presentation/pages/welcome_page.dart with login/register options
  - Create lib/features/auth/presentation/pages/login_page.dart with email, password fields, remember me checkbox
  - Create lib/features/auth/presentation/pages/register_page.dart with username, email, password, confirm password fields
  - Create lib/features/auth/presentation/widgets/auth_text_field.dart reusable widget
  - Implement form validation in UI
  - Add loading indicators during authentication
  - Display error messages from BLoC states
  - _Requirements: 1.1, 1.2, 1.4, 1.5, 1.9_

- [x] 9. Implement password management features





  - Create lib/features/auth/domain/usecases/reset_password_usecase.dart
  - Create lib/features/auth/domain/usecases/change_password_usecase.dart
  - Create lib/features/auth/presentation/pages/forgot_password_page.dart
  - Create lib/features/auth/presentation/pages/reset_password_page.dart
  - Implement password reset token generation and validation
  - Implement password change with current password verification
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [x] 10. Implement fund box with multi-user support





  - Create lib/features/fund_box/domain/entities/fund_box.dart entity
  - Create lib/features/fund_box/domain/repositories/fund_box_repository.dart interface
  - Create lib/features/fund_box/domain/usecases/get_fund_box_usecase.dart
  - Create lib/features/fund_box/domain/usecases/update_fund_balance_usecase.dart
  - Create lib/features/fund_box/data/models/fund_box_model.dart
  - Create lib/features/fund_box/data/datasources/fund_box_local_datasource.dart
  - Implement lib/features/fund_box/data/repositories/fund_box_repository_impl.dart with user_id filtering
  - Create lib/features/fund_box/presentation/bloc/fund_box_bloc.dart
  - Update fund box queries to filter by current user ID
  - _Requirements: 3.3, 3.6, 5.4, 5.5_

- [x] 11. Implement transfers with multi-user support





  - Create lib/features/transfers/domain/entities/transfer.dart entity
  - Create lib/features/transfers/domain/repositories/transfer_repository.dart interface
  - Create lib/features/transfers/domain/usecases/create_transfer_usecase.dart with user context
  - Create lib/features/transfers/domain/usecases/get_transfers_usecase.dart
  - Create lib/features/transfers/domain/usecases/update_transfer_usecase.dart
  - Create lib/features/transfers/domain/usecases/delete_transfer_usecase.dart
  - Create lib/features/transfers/data/models/transfer_model.dart
  - Create lib/features/transfers/data/datasources/transfer_local_datasource.dart
  - Implement lib/features/transfers/data/repositories/transfer_repository_impl.dart with user_id filtering
  - Create lib/features/transfers/presentation/bloc/transfer_bloc.dart
  - Update all transfer queries to include WHERE user_id = ?
  - _Requirements: 3.1, 3.2, 3.5, 5.4, 5.5_

- [x] 12. Implement expenses with multi-user support





  - Create lib/features/expenses/domain/entities/expense.dart entity
  - Create lib/features/expenses/domain/repositories/expense_repository.dart interface
  - Create lib/features/expenses/domain/usecases/create_expense_usecase.dart
  - Create lib/features/expenses/domain/usecases/get_expenses_usecase.dart
  - Create lib/features/expenses/domain/usecases/update_expense_usecase.dart
  - Create lib/features/expenses/domain/usecases/delete_expense_usecase.dart
  - Create lib/features/expenses/data/models/expense_model.dart
  - Create lib/features/expenses/data/datasources/expense_local_datasource.dart
  - Implement lib/features/expenses/data/repositories/expense_repository_impl.dart with user_id filtering
  - Create lib/features/expenses/presentation/bloc/expense_bloc.dart
  - Update all expense queries to include WHERE user_id = ?
  - _Requirements: 3.1, 3.2, 3.4, 3.5, 5.4, 5.5_

- [x] 13. Implement incoming transactions with multi-user support





  - Create lib/features/incoming/domain/entities/incoming.dart entity
  - Create lib/features/incoming/domain/repositories/incoming_repository.dart interface
  - Create lib/features/incoming/domain/usecases/create_incoming_usecase.dart
  - Create lib/features/incoming/domain/usecases/get_incoming_usecase.dart
  - Create lib/features/incoming/domain/usecases/update_incoming_usecase.dart
  - Create lib/features/incoming/domain/usecases/delete_incoming_usecase.dart
  - Create lib/features/incoming/data/models/incoming_model.dart
  - Create lib/features/incoming/data/datasources/incoming_local_datasource.dart
  - Implement lib/features/incoming/data/repositories/incoming_repository_impl.dart with user_id filtering
  - Create lib/features/incoming/presentation/bloc/incoming_bloc.dart
  - Update all incoming queries to include WHERE user_id = ?
  - _Requirements: 3.1, 3.2, 3.5, 5.4, 5.5_

- [x] 14. Set up dependency injection





  - Create lib/injection_container.dart
  - Initialize GetIt service locator
  - Register database instance as singleton
  - Register flutter_secure_storage as singleton
  - Register all data sources as lazy singletons
  - Register all repositories as lazy singletons
  - Register all use cases as lazy singletons
  - Register all BLoCs as factories
  - Call initialization in main.dart before runApp
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 15. Update main.dart with authentication flow





  - Import injection_container and call initializeDependencies()
  - Wrap MaterialApp with BlocProvider for AuthBloc
  - Create routing logic based on authentication state
  - Navigate to WelcomePage if unauthenticated
  - Navigate to HomeScaffold if authenticated
  - Implement authentication state listener
  - _Requirements: 1.1, 1.6, 1.8, 6.6_

- [x] 16. Update existing UI pages to use BLoC pattern




  - Refactor lib/ui/cash_inbox_page.dart to use TransferBloc and IncomingBloc
  - Refactor lib/ui/expense_page.dart to use ExpenseBloc
  - Refactor lib/ui/export_page.dart to use appropriate BLoCs
  - Replace direct database calls with BLoC events
  - Use BlocBuilder and BlocListener for state management
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 17. Implement user profile management






  - Create lib/features/profile/domain/usecases/get_user_profile_usecase.dart
  - Create lib/features/profile/domain/usecases/update_user_profile_usecase.dart
  - Create lib/features/profile/domain/usecases/update_profile_picture_usecase.dart
  - Create lib/features/profile/presentation/bloc/profile_bloc.dart
  - Create lib/features/profile/presentation/pages/profile_page.dart
  - Display user information (username, email, account creation date)
  - Display user statistics (total expenses, total transfers, account age)
  - Add edit profile functionality
  - Add profile picture upload functionality
  - Add logout button
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 18. Implement onboarding experience





  - Create lib/features/onboarding/presentation/pages/onboarding_page.dart
  - Create onboarding slides explaining key features
  - Implement slide navigation with indicators
  - Add skip and next buttons
  - Store onboarding completion status in shared preferences
  - Navigate to home screen after completion
  - Add option to view tutorial again from settings
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 19. Add localization for authentication features





  - Update lib/l10n/app_localizations.dart with authentication keys
  - Add Arabic translations for: welcome, login, register, username, email, password, confirm_password, forgot_password, remember_me, logout, profile
  - Add English translations for all authentication keys
  - Add error message translations: invalid_credentials, registration_success, weak_password, email_already_exists, username_already_exists
  - Add profile and settings translations
  - _Requirements: 1.1, 1.2, 1.4, 1.7, 2.5, 4.1_

- [x] 20. Implement secure storage for sensitive data





  - Create lib/core/services/secure_storage_service.dart wrapper
  - Implement methods for storing/retrieving auth tokens
  - Implement methods for storing/retrieving user credentials (if remember me is checked)
  - Implement method to clear all secure storage on logout
  - Add encryption for sensitive data before storage
  - _Requirements: 8.1, 8.2, 8.3, 1.9_

- [x] 21. Add authorization checks to all data operations




  - Update all repository implementations to verify user ownership before operations
  - Add user ID validation in all use cases
  - Implement authorization middleware for data access
  - Return UnauthorizedFailure when user tries to access other users' data
  - Add logging for unauthorized access attempts
  - _Requirements: 3.5, 11.4_

- [x] 22. Update export functionality for multi-user






















  - Update lib/utils/pdf_export_helper.dart to filter by current user
  - Update Excel export to filter by current user
  - Update invoice images export to filter by current user
  - Add user information to exported documents (username, export date)
  - Ensure exports only contain data belonging to the authenticated user
  - _Requirements: 3.4_

- [x] 23. Implement session timeout and inactivity handling










  - Create lib/core/services/inactivity_service.dart
  - Track user activity (taps, scrolls, navigation)
  - Implement 30-minute inactivity timer
  - Show re-authentication dialog on timeout
  - Clear session and navigate to login on timeout
  - Reset timer on user activity
  - _Requirements: 9.5_

- [ ]* 24. Write unit tests for authentication
  - Write tests for LoginUseCase with valid/invalid credentials
  - Write tests for RegisterUseCase with validation scenarios
  - Write tests for password validation functions
  - Write tests for email validation functions
  - Write tests for AuthBloc event handling and state emissions
  - Write tests for session management functions
  - _Requirements: 1.3, 1.4, 1.7, 2.7_

- [ ]* 25. Write unit tests for repositories
  - Write tests for TransferRepositoryImpl with user filtering
  - Write tests for ExpenseRepositoryImpl with user filtering
  - Write tests for FundBoxRepositoryImpl with user isolation
  - Write tests for IncomingRepositoryImpl with user filtering
  - Mock data sources and verify correct method calls
  - _Requirements: 3.1, 3.2, 3.5_

- [ ]* 26. Write integration tests for database operations
  - Test database migration from version 4 to 5
  - Test user creation and retrieval
  - Test session creation and validation
  - Test data isolation between users
  - Test foreign key constraints
  - Test transaction rollback on errors
  - _Requirements: 10.1, 10.5, 10.6, 3.1, 3.2_

- [ ]* 27. Write widget tests for authentication UI
  - Test WelcomePage navigation
  - Test LoginPage form validation
  - Test RegisterPage form validation
  - Test error message display
  - Test loading indicators
  - Mock AuthBloc for testing
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 28. Add app icon and update branding


























  - Update app icon to reflect multi-user capability
  - Update app name if needed
  - Update splash screen
  - Add branding to welcome/login/register screens
  - _Requirements: 12.1_

- [x] 29. Perform security audit and hardening




  - Review all authentication code for vulnerabilities
  - Ensure passwords are never logged or exposed
  - Verify secure storage implementation
  - Test SQL injection prevention
  - Verify data isolation between users
  - Add rate limiting for login attempts
  - Implement account lockout after failed attempts
  - _Requirements: 8.1, 8.2, 8.4, 3.5, 11.4_

- [x] 30. Final integration and testing




  - Test complete authentication flow (register → login → use app → logout)
  - Test data isolation with multiple user accounts
  - Test session expiration and refresh
  - Test password reset flow
  - Test profile management
  - Test onboarding flow
  - Verify all existing features work with new architecture
  - Test app performance with new architecture
  - Fix any bugs discovered during testing
  - _Requirements: 1.1, 1.6, 1.8, 2.1, 3.1, 4.1, 12.1_
