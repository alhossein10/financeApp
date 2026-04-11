import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Service for monitoring app performance
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final List<FrameTimingInfo> _frameTimings = [];
  final Map<String, Duration> _operationTimings = {};
  final Map<String, int> _apiCallCounts = {};
  
  bool _isMonitoring = false;
  Timer? _reportTimer;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor frame timings
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
    
    // Periodic performance report (every 30 seconds)
    _reportTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _generatePerformanceReport(),
    );
    
    debugPrint('Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _reportTimer?.cancel();
    _reportTimer = null;
    
    debugPrint('Performance monitoring stopped');
  }

  /// Track frame timing
  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      final totalDuration = buildDuration + rasterDuration;
      
      _frameTimings.add(FrameTimingInfo(
        buildDuration: buildDuration,
        rasterDuration: rasterDuration,
        totalDuration: totalDuration,
        timestamp: DateTime.now(),
      ));
      
      // Keep only last 100 frame timings
      if (_frameTimings.length > 100) {
        _frameTimings.removeAt(0);
      }
      
      // Log slow frames (> 16ms = 60fps threshold)
      if (totalDuration > const Duration(milliseconds: 16)) {
        debugPrint(
          'Slow frame detected: ${totalDuration.inMilliseconds}ms '
          '(build: ${buildDuration.inMilliseconds}ms, '
          'raster: ${rasterDuration.inMilliseconds}ms)',
        );
      }
    }
  }

  /// Track operation timing
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _operationTimings[operationName] = stopwatch.elapsed;
      
      // Log slow operations (> 2 seconds)
      if (stopwatch.elapsed > const Duration(seconds: 2)) {
        debugPrint(
          'Slow operation: $operationName took ${stopwatch.elapsed.inMilliseconds}ms',
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _operationTimings[operationName] = stopwatch.elapsed;
      rethrow;
    }
  }

  /// Track API call
  void trackApiCall(String endpoint) {
    _apiCallCounts[endpoint] = (_apiCallCounts[endpoint] ?? 0) + 1;
  }

  /// Get average frame time
  Duration? getAverageFrameTime() {
    if (_frameTimings.isEmpty) return null;
    
    final totalMs = _frameTimings.fold<int>(
      0,
      (sum, timing) => sum + timing.totalDuration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ _frameTimings.length);
  }

  /// Get frame rate (FPS)
  double? getFrameRate() {
    final avgFrameTime = getAverageFrameTime();
    if (avgFrameTime == null || avgFrameTime.inMilliseconds == 0) return null;
    
    return 1000 / avgFrameTime.inMilliseconds;
  }

  /// Get percentage of frames that are slow (> 16ms)
  double? getSlowFramePercentage() {
    if (_frameTimings.isEmpty) return null;
    
    final slowFrames = _frameTimings.where(
      (timing) => timing.totalDuration > const Duration(milliseconds: 16),
    ).length;
    
    return (slowFrames / _frameTimings.length) * 100;
  }

  /// Get operation timing
  Duration? getOperationTiming(String operationName) {
    return _operationTimings[operationName];
  }

  /// Get API call count
  int getApiCallCount(String endpoint) {
    return _apiCallCounts[endpoint] ?? 0;
  }

  /// Get total API calls
  int getTotalApiCalls() {
    return _apiCallCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Generate performance report
  void _generatePerformanceReport() {
    if (!kDebugMode) return;
    
    final avgFrameTime = getAverageFrameTime();
    final fps = getFrameRate();
    final slowFramePercent = getSlowFramePercentage();
    
    debugPrint('=== Performance Report ===');
    
    if (avgFrameTime != null) {
      debugPrint('Average frame time: ${avgFrameTime.inMilliseconds}ms');
    }
    
    if (fps != null) {
      debugPrint('Frame rate: ${fps.toStringAsFixed(1)} FPS');
    }
    
    if (slowFramePercent != null) {
      debugPrint('Slow frames: ${slowFramePercent.toStringAsFixed(1)}%');
    }
    
    if (_operationTimings.isNotEmpty) {
      debugPrint('Operation timings:');
      _operationTimings.forEach((name, duration) {
        debugPrint('  $name: ${duration.inMilliseconds}ms');
      });
    }
    
    if (_apiCallCounts.isNotEmpty) {
      debugPrint('API call counts:');
      _apiCallCounts.forEach((endpoint, count) {
        debugPrint('  $endpoint: $count calls');
      });
    }
    
    debugPrint('========================');
  }

  /// Get performance metrics
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      averageFrameTime: getAverageFrameTime(),
      frameRate: getFrameRate(),
      slowFramePercentage: getSlowFramePercentage(),
      operationTimings: Map.from(_operationTimings),
      apiCallCounts: Map.from(_apiCallCounts),
      totalApiCalls: getTotalApiCalls(),
    );
  }

  /// Clear all metrics
  void clearMetrics() {
    _frameTimings.clear();
    _operationTimings.clear();
    _apiCallCounts.clear();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearMetrics();
  }
}

/// Frame timing information
class FrameTimingInfo {
  final Duration buildDuration;
  final Duration rasterDuration;
  final Duration totalDuration;
  final DateTime timestamp;

  FrameTimingInfo({
    required this.buildDuration,
    required this.rasterDuration,
    required this.totalDuration,
    required this.timestamp,
  });
}

/// Performance metrics snapshot
class PerformanceMetrics {
  final Duration? averageFrameTime;
  final double? frameRate;
  final double? slowFramePercentage;
  final Map<String, Duration> operationTimings;
  final Map<String, int> apiCallCounts;
  final int totalApiCalls;

  PerformanceMetrics({
    this.averageFrameTime,
    this.frameRate,
    this.slowFramePercentage,
    required this.operationTimings,
    required this.apiCallCounts,
    required this.totalApiCalls,
  });

  Map<String, dynamic> toJson() {
    return {
      'averageFrameTimeMs': averageFrameTime?.inMilliseconds,
      'frameRate': frameRate,
      'slowFramePercentage': slowFramePercentage,
      'operationTimings': operationTimings.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'apiCallCounts': apiCallCounts,
      'totalApiCalls': totalApiCalls,
    };
  }
}
