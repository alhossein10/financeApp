import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/config/flavor_config.dart';
import 'core/config/pocketbase_config.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/pocketbase_storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/security_audit_service.dart';
import 'core/services/session_manager.dart';
import 'core/services/storage_service.dart';
import 'core/services/sync_service.dart';
import 'data/db.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/change_password_usecase.dart';
import 'features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/expenses/data/datasources/expense_local_datasource.dart';
import 'features/expenses/data/datasources/expense_local_datasource_impl.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/expenses/domain/usecases/create_expense_usecase.dart';
import 'features/expenses/domain/usecases/delete_expense_usecase.dart';
import 'features/expenses/domain/usecases/fetch_admin_expenses_usecase.dart';
import 'features/expenses/domain/usecases/get_expenses_usecase.dart';
import 'features/expenses/domain/usecases/update_expense_usecase.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/fund_box/data/datasources/fund_box_local_datasource.dart';
import 'features/fund_box/data/datasources/fund_box_local_datasource_impl.dart';
import 'features/fund_box/data/repositories/fund_box_repository_impl.dart';
import 'features/fund_box/domain/repositories/fund_box_repository.dart';
import 'features/fund_box/domain/usecases/get_fund_box_usecase.dart';
import 'features/fund_box/domain/usecases/update_fund_balance_usecase.dart';
import 'features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'features/incoming/data/datasources/incoming_local_datasource.dart';
import 'features/incoming/data/datasources/incoming_local_datasource_impl.dart';
import 'features/incoming/data/repositories/incoming_repository_impl.dart';
import 'features/incoming/domain/repositories/incoming_repository.dart';
import 'features/incoming/domain/usecases/create_incoming_usecase.dart';
import 'features/incoming/domain/usecases/delete_incoming_usecase.dart';
import 'features/incoming/domain/usecases/get_incoming_usecase.dart';
import 'features/incoming/domain/usecases/update_incoming_usecase.dart';
import 'features/incoming/presentation/bloc/incoming_bloc.dart';
import 'features/transfers/data/datasources/transfer_local_datasource.dart';
import 'features/transfers/data/datasources/transfer_local_datasource_impl.dart';
import 'features/transfers/data/repositories/transfer_repository_impl.dart';
import 'features/transfers/domain/repositories/transfer_repository.dart';
import 'features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'features/transfers/domain/usecases/delete_transfer_usecase.dart';
import 'features/transfers/domain/usecases/get_transfers_usecase.dart';
import 'features/transfers/domain/usecases/update_transfer_usecase.dart';
import 'features/transfers/presentation/bloc/transfer_bloc.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/datasources/profile_local_datasource_impl.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'features/profile/domain/usecases/update_user_profile_usecase.dart';
import 'features/profile/domain/usecases/update_profile_picture_usecase.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ========== FLAVOR CONFIGURATION ==========
  
  // FlavorConfig is initialized in main_admin.dart or main_user.dart
  // Register as singleton after initialization
  sl.registerSingleton<FlavorConfig>(FlavorConfig.instance);

  // ========== EXTERNAL DEPENDENCIES ==========
  
  // Database
  final database = await AppDatabase().database;
  sl.registerSingleton<Database>(database);

  // Secure Storage
  const secureStorage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(secureStorage);

  // PocketBase
  final pocketBase = PocketBase(PocketBaseConfig.baseUrl);
  sl.registerSingleton<PocketBase>(pocketBase);

  // Connectivity
  final connectivity = Connectivity();
  sl.registerSingleton<Connectivity>(connectivity);

  // ========== CORE SERVICES ==========
  
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );

  sl.registerLazySingleton<SecurityAuditService>(
    () => SecurityAuditService(database: sl()),
  );

  sl.registerLazySingleton<SessionManager>(
    () => SessionManager(
      secureStorage: sl(),
      database: sl(),
    ),
  );

  sl.registerLazySingleton<OnboardingService>(
    () => OnboardingService(),
  );

  // Connectivity Service
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(
      connectivity: sl(),
    ),
  );

  // Initialize connectivity monitoring
  sl<ConnectivityService>().initialize();

  // Storage Service (PocketBase implementation)
  sl.registerLazySingleton<StorageService>(
    () => PocketBaseStorageService(
      pb: sl(),
      connectivity: sl(),
    ),
  );

  // Sync Service (Cloud implementation with PocketBase)
  sl.registerLazySingleton<SyncService>(
    () => CloudSyncService(
      pb: sl(),
      storageService: sl(),
      localDataSource: sl(),
      authRepository: sl(),
      flavorConfig: sl(),
      connectivityService: sl(),
    ),
  );

  // Initialize security audit service tables
  sl<SecurityAuditService>().initialize();

  // ========== AUTH FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      database: sl(),
      secureStorage: sl(),
      securityAuditService: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      resetPasswordUseCase: sl(),
      changePasswordUseCase: sl(),
    ),
  );

  // ========== FUND BOX FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<FundBoxLocalDataSource>(
    () => FundBoxLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<FundBoxRepository>(
    () => FundBoxRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetFundBoxUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFundBalanceUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => FundBoxBloc(
      getFundBoxUseCase: sl(),
      updateFundBalanceUseCase: sl(),
    ),
  );

  // ========== TRANSFERS FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<TransferLocalDataSource>(
    () => TransferLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(
      localDataSource: sl(),
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
    ),
  );

  // ========== EXPENSES FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      localDataSource: sl(),
      authRepository: sl(),
      syncService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateExpenseUseCase(
    repository: sl(),
    syncService: sl(),
  ));
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
    ),
  );

  // ========== INCOMING FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<IncomingLocalDataSource>(
    () => IncomingLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<IncomingRepository>(
    () => IncomingRepositoryImpl(
      localDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateIncomingUseCase(
    incomingRepository: sl(),
    authRepository: sl(),
  ));
  sl.registerLazySingleton(() => GetIncomingUseCase(
    incomingRepository: sl(),
    authRepository: sl(),
  ));
  sl.registerLazySingleton(() => UpdateIncomingUseCase(
    incomingRepository: sl(),
    authRepository: sl(),
  ));
  sl.registerLazySingleton(() => DeleteIncomingUseCase(
    incomingRepository: sl(),
    authRepository: sl(),
  ));

  // BLoC
  sl.registerFactory(
    () => IncomingBloc(
      createIncomingUseCase: sl(),
      getIncomingUseCase: sl(),
      updateIncomingUseCase: sl(),
      deleteIncomingUseCase: sl(),
    ),
  );

  // ========== PROFILE FEATURE ==========
  
  // Data Sources
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetUserProfileUseCase(
    authRepository: sl(),
    profileRepository: sl(),
  ));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(
    authRepository: sl(),
    profileRepository: sl(),
  ));
  sl.registerLazySingleton(() => UpdateProfilePictureUseCase(
    authRepository: sl(),
    profileRepository: sl(),
  ));

  // BLoC
  sl.registerFactory(
    () => ProfileBloc(
      getUserProfileUseCase: sl(),
      updateUserProfileUseCase: sl(),
      updateProfilePictureUseCase: sl(),
    ),
  );

  // ========== ADMIN FEATURE ==========
  
  // BLoC
  sl.registerFactory(
    () => AdminBloc(
      fetchAdminExpensesUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
}
