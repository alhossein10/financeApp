import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/role_service.dart';
import '../../domain/usecases/get_audit_log_details_usecase.dart';
import '../../domain/usecases/get_audit_logs_usecase.dart';
import 'audit_log_event.dart';
import 'audit_log_state.dart';

/// BLoC for managing audit log state
class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  final GetAuditLogsUseCase _getAuditLogsUseCase;
  final GetAuditLogDetailsUseCase _getAuditLogDetailsUseCase;
  final RoleService _roleService;

  // Store current filters for pagination
  int? _currentUserId;
  String? _currentAction;
  String? _currentEntityType;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  int _currentPage = 1;
  final int _perPage = 15;

  AuditLogBloc({
    required GetAuditLogsUseCase getAuditLogsUseCase,
    required GetAuditLogDetailsUseCase getAuditLogDetailsUseCase,
    required RoleService roleService,
  })  : _getAuditLogsUseCase = getAuditLogsUseCase,
        _getAuditLogDetailsUseCase = getAuditLogDetailsUseCase,
        _roleService = roleService,
        super(const AuditLogInitial()) {
    on<FetchAuditLogsRequested>(_onFetchAuditLogs);
    on<LoadMoreAuditLogsRequested>(_onLoadMoreAuditLogs);
    on<FetchAuditLogDetailsRequested>(_onFetchAuditLogDetails);
    on<RefreshAuditLogsRequested>(_onRefreshAuditLogs);
  }

  Future<void> _onFetchAuditLogs(
    FetchAuditLogsRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(const AuditLogLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();

      // Store filters for pagination
      _currentUserId = event.userId;
      _currentAction = event.action;
      _currentEntityType = event.entityType;
      _currentStartDate = event.startDate;
      _currentEndDate = event.endDate;
      _currentPage = event.page;

      final result = await _getAuditLogsUseCase(
        page: event.page,
        perPage: event.perPage,
        userId: event.userId,
        action: event.action,
        entityType: event.entityType,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      result.fold(
        (failure) {
          final requiresLogin = failure.toString().contains('Session expired') ||
              failure.toString().contains('not authenticated');
          emit(AuditLogError(
            failure.toString(),
            requiresLogin: requiresLogin,
          ));
        },
        (auditLogList) {
          emit(AuditLogLoaded(
            logs: auditLogList.logs,
            currentPage: auditLogList.currentPage,
            lastPage: auditLogList.lastPage,
            total: auditLogList.total,
            hasMorePages: auditLogList.hasMorePages,
          ));
        },
      );
    } catch (e) {
      if (e.toString().contains('Insufficient permissions') || 
          e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        emit(AuditLogError(
          e.toString(),
          requiresLogin: false,
        ));
      } else {
        emit(AuditLogError(
          e.toString(),
          requiresLogin: false,
        ));
      }
    }
  }

  Future<void> _onLoadMoreAuditLogs(
    LoadMoreAuditLogsRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    if (state is! AuditLogLoaded) return;

    final currentState = state as AuditLogLoaded;
    if (!currentState.hasMorePages) return;

    emit(AuditLogLoadingMore(
      currentLogs: currentState.logs,
      currentPage: currentState.currentPage,
    ));

    final nextPage = currentState.currentPage + 1;
    _currentPage = nextPage;

    final result = await _getAuditLogsUseCase(
      page: nextPage,
      perPage: _perPage,
      userId: _currentUserId,
      action: _currentAction,
      entityType: _currentEntityType,
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    );

    result.fold(
      (failure) {
        // Restore previous state on error
        emit(currentState);
        emit(AuditLogError(failure.toString()));
      },
      (auditLogList) {
        final allLogs = [...currentState.logs, ...auditLogList.logs];
        emit(AuditLogLoaded(
          logs: allLogs,
          currentPage: auditLogList.currentPage,
          lastPage: auditLogList.lastPage,
          total: auditLogList.total,
          hasMorePages: auditLogList.hasMorePages,
        ));
      },
    );
  }

  Future<void> _onFetchAuditLogDetails(
    FetchAuditLogDetailsRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(const AuditLogLoading());

    try {
      // Validate admin permission before API call
      await _roleService.requireAdminPermission();

      final result = await _getAuditLogDetailsUseCase(event.id);

      result.fold(
        (failure) {
          final requiresLogin = failure.toString().contains('Session expired') ||
              failure.toString().contains('not authenticated');
          emit(AuditLogError(
            failure.toString(),
            requiresLogin: requiresLogin,
          ));
        },
        (auditLog) {
          emit(AuditLogDetailsLoaded(auditLog));
        },
      );
    } catch (e) {
      if (e.toString().contains('Insufficient permissions') || 
          e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        emit(AuditLogError(
          e.toString(),
          requiresLogin: false,
        ));
      } else {
        emit(AuditLogError(
          e.toString(),
          requiresLogin: false,
        ));
      }
    }
  }

  Future<void> _onRefreshAuditLogs(
    RefreshAuditLogsRequested event,
    Emitter<AuditLogState> emit,
  ) async {
    // Reset to first page and fetch
    add(FetchAuditLogsRequested(
      page: 1,
      perPage: _perPage,
      userId: _currentUserId,
      action: _currentAction,
      entityType: _currentEntityType,
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    ));
  }
}
