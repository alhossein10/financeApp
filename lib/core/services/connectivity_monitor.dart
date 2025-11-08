import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity status
enum ConnectivityStatus {
  online,
  offline;

  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
}

/// Connectivity monitor service
abstract class ConnectivityMonitor {
  Stream<ConnectivityStatus> get connectivityStream;
  Future<ConnectivityStatus> checkConnectivity();
  Future<bool> get isOnline;
  Future<void> initialize();
  Future<void> dispose();
}

class ConnectivityMonitorImpl implements ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;

  @override
  Stream<ConnectivityStatus> get connectivityStream => _statusController.stream;

  @override
  Future<bool> get isOnline async {
    final status = await checkConnectivity();
    return status.isOnline;
  }

  @override
  Future<void> initialize() async {
    // Check initial connectivity
    _currentStatus = await checkConnectivity();
    _statusController.add(_currentStatus);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final status = _mapConnectivityResult(results);
        if (status != _currentStatus) {
          _currentStatus = status;
          _statusController.add(status);
        }
      },
    );
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _mapConnectivityResult(results);
    } catch (e) {
      // If we can't check connectivity, assume offline
      return ConnectivityStatus.offline;
    }
  }

  @override
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _statusController.close();
  }

  /// Map ConnectivityResult to ConnectivityStatus
  ConnectivityStatus _mapConnectivityResult(List<ConnectivityResult> results) {
    // If any result indicates connectivity, consider online
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }

    for (final result in results) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn) {
        return ConnectivityStatus.online;
      }
    }

    return ConnectivityStatus.offline;
  }

  /// Get current connectivity status (synchronous)
  ConnectivityStatus get currentStatus => _currentStatus;
}
