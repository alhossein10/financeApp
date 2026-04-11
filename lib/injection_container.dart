import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
// Removed sqflite_common_ffi - not needed for this version
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/config/flavor_config.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/role_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/language_service.dart';
import 'core/bloc/language_bloc.dart';
import 'core/services/sync_service.dart';
import 'core/services/noop_sync_service.dart';
import 'data/db.dart';
import 'features/auth/data/datasources/auth_api_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'core/services/laravel_auth_service.dart';
import 'core/services/token_manager.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/get_departments_usecase.dart';
import 'features/auth/domain/usecases/get_organizations_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/domain/usecases/reset_password_with_token_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/expenses/data/datasources/expense_cache_datasource.dart';
import 'features/expenses/data/datasources/expense_api_datasource.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/expenses/domain/usecases/create_expense_usecase.dart';
import 'features/expenses/domain/usecases/delete_expense_usecase.dart';
import 'features/expenses/domain/usecases/fetch_admin_expenses_usecase.dart';
import 'features/expenses/domain/usecases/get_expenses_usecase.dart';
import 'features/expenses/domain/usecases/update_expense_usecase.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'features/fund_box/data/repositories/fund_box_repository_impl.dart';
import 'features/fund_box/domain/repositories/fund_box_repository.dart';
import 'features/fund_box/domain/usecases/get_fund_box_usecase.dart';
import 'features/fund_box/domain/usecases/get_calculated_balance_usecase.dart';
import 'features/fund_box/domain/usecases/update_fund_balance_usecase.dart';
import 'features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'features/incoming/data/datasources/incoming_api_datasource.dart';
import 'features/incoming/data/datasources/incoming_cache_datasource.dart';
import 'features/incoming/data/datasources/incoming_local_datasource.dart';
import 'features/incoming/data/datasources/incoming_local_datasource_impl.dart';
import 'features/incoming/data/repositories/incoming_repository_impl.dart';
import 'features/incoming/domain/repositories/incoming_repository.dart';
import 'features/incoming/domain/usecases/create_incoming_usecase.dart';
import 'features/incoming/domain/usecases/delete_incoming_usecase.dart';
import 'features/incoming/domain/usecases/get_incoming_usecase.dart';
import 'features/incoming/domain/usecases/update_incoming_usecase.dart';
import 'features/incoming/presentation/bloc/incoming_bloc.dart';
import 'core/api/api_client.dart';
import 'core/services/cache_service.dart';
import 'core/services/connectivity_monitor.dart';
import 'core/services/queue_manager.dart';
import 'features/transfers/data/datasources/transfer_api_datasource.dart';
import 'features/transfers/data/datasources/transfer_cache_datasource.dart';
import 'features/transfers/data/repositories/transfer_repository_impl.dart';
import 'features/transfers/domain/repositories/transfer_repository.dart';
import 'features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'features/transfers/domain/usecases/delete_transfer_usecase.dart';
import 'features/transfers/domain/usecases/get_transfers_usecase.dart';
import 'features/transfers/domain/usecases/update_transfer_usecase.dart';
import 'features/transfers/presentation/bloc/transfer_bloc.dart';
import 'features/profile/data/datasources/profile_api_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'features/profile/domain/usecases/update_user_profile_usecase.dart';
import 'features/profile/domain/usecases/update_profile_picture_usecase.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'core/services/profile_image_upload_service.dart';
import 'features/admin/data/datasources/admin_api_datasource.dart';
import 'features/admin/data/datasources/audit_log_api_datasource.dart';
import 'features/admin/data/datasources/super_admin_analytics_api_datasource.dart';
import 'features/admin/data/repositories/audit_log_repository_impl.dart';
import 'features/admin/data/repositories/super_admin_analytics_repository_impl.dart';
import 'features/admin/domain/repositories/audit_log_repository.dart';
import 'features/admin/domain/repositories/super_admin_analytics_repository.dart';
import 'features/admin/domain/usecases/get_audit_log_details_usecase.dart';
import 'features/admin/domain/usecases/get_audit_logs_usecase.dart';
import 'features/admin/domain/usecases/get_super_admin_analytics_usecase.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/admin/presentation/bloc/audit_log_bloc.dart';
import 'features/admin/presentation/bloc/super_admin_analytics_bloc.dart';
import 'features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'features/admin_group/data/repositories/admin_group_repository_impl.dart';
import 'features/admin_group/domain/repositories/admin_group_repository.dart';
import 'features/admin_group/domain/usecases/get_admin_group_usecase.dart';
import 'features/admin_group/domain/usecases/regenerate_group_code_usecase.dart';
import 'features/admin_group/domain/usecases/get_group_members_usecase.dart';
import 'features/admin_group/domain/usecases/remove_group_member_usecase.dart';
import 'features/admin_group/domain/usecases/join_group_usecase.dart';
import 'features/admin_group/domain/usecases/get_user_group_info_usecase.dart';
import 'features/admin_group/domain/usecases/join_superadmin_group_usecase.dart';
import 'features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'core/migration/data_migrator.dart';
import 'core/services/batch_sync_service.dart';
import 'core/services/balance_verification_service.dart';
import 'features/exchanges/data/datasources/exchange_api_datasource.dart';
import 'features/exchanges/data/repositories/exchange_repository_impl.dart';
import 'features/exchanges/domain/repositories/exchange_repository.dart';
import 'features/exchanges/domain/usecases/create_exchange_usecase.dart';
import 'features/exchanges/domain/usecases/get_all_exchanges_usecase.dart';
import 'features/exchanges/domain/usecases/get_exchanges_by_transfer_usecase.dart';
import 'features/exchanges/domain/usecases/get_transfer_balance_usecase.dart';
import 'features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'features/organizations/data/datasources/organizations_api_datasource.dart';
import 'features/organizations/data/datasources/organizations_cache_datasource.dart';
import 'features/export/data/datasources/export_api_datasource.dart';
import 'features/export/presentation/bloc/export_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ========== FLAVOR CONFIGURATION ==========

  // FlavorConfig is initialized in main_admin.dart or main_user.dart
  // Register as singleton after initialization
  sl.registerSingleton<FlavorConfig>(FlavorConfig.instance);

  // ========== EXTERNAL DEPENDENCIES ==========

  // Database - Removed for Laravel API migration
  // Note: Database is only needed for data migration tool
  // If you need to run migration, temporarily uncomment the lines below:
  // final database = await AppDatabase().database;
  // sl.registerSingleton<Database>(database);

  // Secure Storage
  const secureStorage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Connectivity
  final connectivity = Connectivity();
  sl.registerSingleton<Connectivity>(connectivity);

  // ========== CORE SERVICES ==========

  // Token Manager (must be registered before ApiClient)
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(secureStorage: secureStorage),
  );

  // Laravel API Services with Bearer Token support
  sl.registerLazySingleton<ApiClient>(
    () => DioApiClient(
      tokenManager: sl<TokenManager>(),
      // onTokenRefreshFailed callback will be set up by auth service
    ),
  );

  sl.registerLazySingleton<CacheService>(() => CacheServiceImpl());

  sl.registerLazySingleton<QueueManager>(() => QueueManagerImpl());

  sl.registerLazySingleton<ConnectivityMonitor>(
    () => ConnectivityMonitorImpl(),
  );

  // Initialize cache and queue services
  sl<CacheService>().initialize();
  sl<QueueManager>().initialize();
  sl<ConnectivityMonitor>().initialize();

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );

  // Note: These services still use database for backward compatibility
  // TODO: Migrate to API-based audit logging and session management
  // sl.registerLazySingleton<SecurityAuditService>(
  //   () => SecurityAuditService(database: sl()),
  // );

  // sl.registerLazySingleton<SessionManager>(
  //   () => SessionManager(
  //     secureStorage: sl(),
  //     database: sl(),
  //   ),
  // );

  sl.registerLazySingleton<OnboardingService>(() => OnboardingService());

  // Language Service for localization
  sl.registerLazySingleton<LanguageService>(
    () => LanguageService(sl<SharedPreferences>()),
  );

  // Language BLoC
  sl.registerFactory<LanguageBloc>(
    () => LanguageBloc(sl<LanguageService>()),
  );

  // Role Service for role-based access control
  sl.registerLazySingleton<RoleService>(
    () => RoleService(authRepository: sl()),
  );

  // Connectivity Service
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: sl()),
  );

  // Initialize connectivity monitoring
  sl<ConnectivityService>().initialize();

  // ========== ORGANIZATIONS FEATURE (PUBLIC ENDPOINTS) ==========

  // Data Sources
  sl.registerLazySingleton<OrganizationsApiDatasource>(
    () => OrganizationsApiDatasource(apiClient: sl()),
  );

  sl.registerLazySingleton<OrganizationsCacheDatasource>(
    () => OrganizationsCacheDatasource(prefs: sl()),
  );

  // ========== AUTH FEATURE ==========

  // Laravel Auth Service
  sl.registerLazySingleton<LaravelAuthService>(
    () => LaravelAuthService(apiClient: sl(), tokenManager: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthApiDataSource>(
    () => AuthApiDataSourceImpl(authService: sl(), apiClient: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiDataSource: sl(), localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordWithTokenUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => GetOrganizationsUseCase(sl()));
  sl.registerLazySingleton(() => GetDepartmentsUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      resetPasswordUseCase: sl(),
      resetPasswordWithTokenUseCase: sl(),
      changePasswordUseCase: sl(),
      getOrganizationsUseCase: sl(),
      getDepartmentsUseCase: sl(),
    ),
  );

  // ========== FUND BOX FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<FundBoxApiDataSource>(
    () => FundBoxApiDataSourceImpl(apiClient: sl(), roleService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<FundBoxRepository>(
    () => FundBoxRepositoryImpl(apiDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetFundBoxUseCase(sl()));
  sl.registerLazySingleton(() => GetCalculatedBalanceUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFundBalanceUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => FundBoxBloc(
      getFundBoxUseCase: sl(),
      getCalculatedBalanceUseCase: sl(),
      updateFundBalanceUseCase: sl(),
      roleService: sl(),
    ),
  );

  // Balance Verification Service
  sl.registerLazySingleton<BalanceVerificationService>(
    () => BalanceVerificationService(fundBoxApiDataSource: sl()),
  );

  // ========== TRANSFERS FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<TransferApiDataSource>(
    () => TransferApiDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<TransferCacheDataSource>(
    () => TransferCacheDataSourceImpl(cacheService: sl()),
  );

  // Note: Keep local data source for backward compatibility during migration
  // sl.registerLazySingleton<TransferLocalDataSource>(
  //   () => TransferLocalDataSourceImpl(database: sl()),
  // );

  // Repositories
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(
      localDataSource: null, // Set to null to use API only
      apiDataSource: sl(),
      cacheDataSource: sl(),
      queueManager: sl(),
      connectivityMonitor: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateTransferUseCase(sl()));
  sl.registerLazySingleton(() => GetTransfersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransferUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransferUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => TransferBloc(
      createTransferUseCase: sl(),
      getTransfersUseCase: sl(),
      updateTransferUseCase: sl(),
      deleteTransferUseCase: sl(),
      connectivityMonitor: sl(),
    ),
  );

  // ========== EXPENSES FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<ExpenseApiDataSource>(
    () => ExpenseApiDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ExpenseCacheDataSource>(
    () => ExpenseCacheDataSourceImpl(cacheService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      localDataSource: null,
      apiDataSource: sl(),
      cacheDataSource: sl(),
      authRepository: sl(),
      connectivityMonitor: sl(),
      queueManager: sl(),
      syncService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(
    () => CreateExpenseUseCase(repository: sl(), syncService: sl()),
  );
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton(() => FetchAdminExpensesUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => ExpenseBloc(
      createExpenseUseCase: sl(),
      getExpensesUseCase: sl(),
      updateExpenseUseCase: sl(),
      deleteExpenseUseCase: sl(),
      syncService: sl(),
      queueManager: sl(),
    ),
  );

  // ========== INCOMING FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<IncomingApiDataSource>(
    () => IncomingApiDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<IncomingCacheDataSource>(
    () => IncomingCacheDataSourceImpl(cacheService: sl()),
  );

  // Note: Local data source is stub for Laravel API migration
  sl.registerLazySingleton<IncomingLocalDataSource>(
    () => IncomingLocalDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<IncomingRepository>(
    () => IncomingRepositoryImpl(
      localDataSource: sl(),
      apiDataSource: sl(),
      cacheDataSource: sl(),
      connectivityMonitor: sl(),
      queueManager: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(
    () => CreateIncomingUseCase(incomingRepository: sl(), authRepository: sl()),
  );
  sl.registerLazySingleton(
    () => GetIncomingUseCase(incomingRepository: sl(), authRepository: sl()),
  );
  sl.registerLazySingleton(
    () => UpdateIncomingUseCase(incomingRepository: sl(), authRepository: sl()),
  );
  sl.registerLazySingleton(
    () => DeleteIncomingUseCase(incomingRepository: sl(), authRepository: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => IncomingBloc(
      createIncomingUseCase: sl(),
      getIncomingUseCase: sl(),
      updateIncomingUseCase: sl(),
      deleteIncomingUseCase: sl(),
      connectivityMonitor: sl(),
      queueManager: sl(),
    ),
  );

  // ========== PROFILE FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<ProfileApiDataSource>(
    () => ProfileApiDataSourceImpl(
      apiClient: sl(),
      tokenManager: sl(),
    ),
  );

  // Profile Image Upload Service
  sl.registerLazySingleton<ProfileImageUploadService>(
    () => ProfileImageUploadService(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      apiDataSource: sl(),
      imageUploadService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(
    () => GetUserProfileUseCase(authRepository: sl(), profileRepository: sl()),
  );
  sl.registerLazySingleton(
    () =>
        UpdateUserProfileUseCase(authRepository: sl(), profileRepository: sl()),
  );
  sl.registerLazySingleton(
    () => UpdateProfilePictureUseCase(
      authRepository: sl(),
      profileRepository: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => ProfileBloc(
      getUserProfileUseCase: sl(),
      updateUserProfileUseCase: sl(),
      updateProfilePictureUseCase: sl(),
      profileRepository: sl(),
    ),
  );

  // ========== ADMIN FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<AdminApiDataSource>(
    () => AdminApiDataSourceImpl(apiClient: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => AdminBloc(
      fetchAdminExpensesUseCase: sl(),
      getCurrentUserUseCase: sl(),
      adminApiDataSource: sl(),
      roleService: sl(),
    ),
  );

  // ========== AUDIT LOG FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<AuditLogApiDataSource>(
    () => AuditLogApiDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuditLogRepository>(
    () => AuditLogRepositoryImpl(apiDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAuditLogsUseCase(sl()));
  sl.registerLazySingleton(() => GetAuditLogDetailsUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuditLogBloc(
      getAuditLogsUseCase: sl(),
      getAuditLogDetailsUseCase: sl(),
      roleService: sl(),
    ),
  );

  // ========== SUPERADMIN ANALYTICS FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<SuperAdminAnalyticsApiDataSource>(
    () => SuperAdminAnalyticsApiDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SuperAdminAnalyticsRepository>(
    () => SuperAdminAnalyticsRepositoryImpl(apiDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSuperAdminAnalyticsUseCase(sl()));

  // BLoC
  sl.registerFactory(() => SuperAdminAnalyticsBloc(getAnalyticsUseCase: sl()));

  // ========== ADMIN GROUP FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<AdminGroupApiDataSource>(
    () => AdminGroupApiDataSourceImpl(
      apiClient: sl(),
      roleService: sl(),
      tokenManager: sl(),
    ),
  );

  sl.registerLazySingleton<AdminGroupCacheDataSource>(
    () => AdminGroupCacheDataSourceImpl(cacheService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminGroupRepository>(
    () => AdminGroupRepositoryImpl(apiDataSource: sl(), cacheDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAdminGroupUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => RegenerateGroupCodeUseCase(repository: sl(), cacheDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetGroupMembersUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => RemoveGroupMemberUseCase(repository: sl(), cacheDataSource: sl()),
  );
  sl.registerLazySingleton(
    () => JoinGroupUseCase(repository: sl(), cacheDataSource: sl()),
  );
  sl.registerLazySingleton(
    () => JoinSuperAdminGroupUseCase(repository: sl(), cacheDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetUserGroupInfoUseCase(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => AdminGroupBloc(
      getAdminGroupUseCase: sl(),
      regenerateGroupCodeUseCase: sl(),
      getGroupMembersUseCase: sl(),
      removeGroupMemberUseCase: sl(),
      joinGroupUseCase: sl(),
      joinSuperAdminGroupUseCase: sl(),
      getUserGroupInfoUseCase: sl(),
    ),
  );

  // ========== EXCHANGE FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<ExchangeApiDataSource>(
    () => ExchangeApiDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ExchangeRepository>(
    () => ExchangeRepositoryImpl(apiDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateExchangeUseCase(sl()));
  sl.registerLazySingleton(() => GetAllExchangesUseCase(sl()));
  sl.registerLazySingleton(() => GetExchangesByTransferUseCase(sl()));
  sl.registerLazySingleton(() => GetTransferBalanceUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => ExchangeBloc(
      createExchangeUseCase: sl(),
      getAllExchangesUseCase: sl(),
      getExchangesByTransferUseCase: sl(),
      getTransferBalanceUseCase: sl(),
    ),
  );

  // ========== EXPORT FEATURE ==========

  // Data Sources
  sl.registerLazySingleton<ExportApiDataSource>(
    () => ExportApiDataSourceImpl(apiClient: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => ExportBloc(exportApiDataSource: sl()),
  );

  // ========== MIGRATION SERVICES ==========

  // Sync Service (No-op for Laravel version)
  sl.registerLazySingleton<SyncService>(() => NoOpSyncService());

  // Batch Sync Service
  sl.registerLazySingleton<BatchSyncService>(
    () => BatchSyncService(apiClient: sl()),
  );

  // Data Migrator
  sl.registerLazySingleton<DataMigrator>(
    () => DataMigrator(database: AppDatabase(), batchSyncService: sl()),
  );
}

/// Restore authentication token from secure storage and set it in API client
/// This should be called after initializing dependencies but before running the app
Future<void> restoreAuthToken() async {
  try {
    final tokenManager = sl<TokenManager>();
    final apiClient = sl<ApiClient>();

    // Check if token exists
    if (await tokenManager.hasToken()) {
      final token = await tokenManager.getToken();

      if (token != null) {
        // Set token in API client
        apiClient.setAuthToken(token);
      }
    }
  } catch (e) {
    // Don't throw - app should still start even if token restoration fails
    // Error is logged internally by TokenManager
  }
}
