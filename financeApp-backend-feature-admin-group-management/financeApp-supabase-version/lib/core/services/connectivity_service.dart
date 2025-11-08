import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status
/// Provides a stream of connectivity changes and current status
class ConnectivityService {
  final Connectivity _connectivity;
  
  StreamController<ConnectivityStatus>? _statusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  ConnectivityService({
    required Connectivity connectivity,
  }) : _connectivity = connectivity;

  /// Get the current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Check if device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream {
    _statusController ??= StreamController<ConnectivityStatus>.broadcast(
      onListen: _startMonitoring,
      onCancel: _stopMonitoring,
    );
    return _statusController!.stream;
  }

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    await _checkInitialConnectivity();
    _startMonitoring();
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(_mapConnectivityResult(result));
    } catch (e) {
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Start monitoring connectivity changes
  void _startMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        // Take the first result if multiple are provided
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        _updateStatus(_mapConnectivityResult([result]));
      },
      onError: (error) {
        _updateStatus(ConnectivityStatus.unknown);
      },
    );
  }

  /// Stop monitoring connectivity changes
  void _stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Update connectivity status and emit to stream
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      
      // Emit status change
      _statusController?.add(newStatus);
      
      // Log status change for debugging
      _logStatusChange(previousStatus, newStatus);
    }
  }

  /// Map ConnectivityResult to ConnectivityStatus
  ConnectivityStatus _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty || results.first == ConnectivityResult.none) {
      return ConnectivityStatus.offline;
    }
    
    // Any connection type (wifi, mobile, ethernet, etc.) is considered online
    return ConnectivityStatus.online;
  }

  /// Log connectivity status changes
  void _logStatusChange(ConnectivityStatus from, ConnectivityStatus to) {
    print('[ConnectivityService] Status changed: $from -> $to');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController?.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown;

  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isUnknown => this == ConnectivityStatus.unknown;
}
