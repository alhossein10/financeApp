import 'dart:async';
import 'package:flutter/widgets.dart';

/// Service to track user inactivity and trigger auto-logout
/// Implements WidgetsBindingObserver to detect app lifecycle changes
/// 
/// Features:
/// - Tracks user interactions (taps, scrolls, etc.)
/// - Auto-logout after 30 minutes of inactivity
/// - Pauses tracking when app is in background
/// - Resumes tracking when app returns to foreground
/// 
/// Usage:
/// ```dart
/// final tracker = InactivityTracker(
///   inactivityDuration: Duration(minutes: 30),
///   onInactivityTimeout: () async {
///     // Logout user
///     await authBloc.logout();
///     Navigator.pushReplacementNamed(context, '/login');
///   },
/// );
/// 
/// // Start tracking
/// tracker.start();
/// 
/// // Stop tracking (on logout)
/// tracker.stop();
/// ```
class InactivityTracker with WidgetsBindingObserver {
  final Duration inactivityDuration;
  final Future<void> Function() onInactivityTimeout;
  
  Timer? _inactivityTimer;
  DateTime? _lastActivityTime;
  bool _isTracking = false;
  bool _isAppInForeground = true;
  
  InactivityTracker({
    required this.inactivityDuration,
    required this.onInactivityTimeout,
  });
  
  /// Start tracking user inactivity
  void start() {
    if (_isTracking) return;
    
    _isTracking = true;
    _lastActivityTime = DateTime.now();
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Start inactivity timer
    _resetInactivityTimer();
    
    print('🔒 [InactivityTracker] Started tracking (timeout: ${inactivityDuration.inMinutes} minutes)');
  }
  
  /// Stop tracking user inactivity
  void stop() {
    if (!_isTracking) return;
    
    _isTracking = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    print('🔒 [InactivityTracker] Stopped tracking');
  }
  
  /// Record user activity (call this on user interactions)
  void recordActivity() {
    if (!_isTracking || !_isAppInForeground) return;
    
    _lastActivityTime = DateTime.now();
    _resetInactivityTimer();
  }
  
  /// Reset the inactivity timer
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    
    _inactivityTimer = Timer(inactivityDuration, () async {
      if (_isTracking && _isAppInForeground) {
        print('⚠️ [InactivityTracker] Inactivity timeout reached - triggering logout');
        await _handleInactivityTimeout();
      }
    });
  }
  
  /// Handle inactivity timeout
  Future<void> _handleInactivityTimeout() async {
    try {
      await onInactivityTimeout();
    } catch (e) {
      print('🔴 [InactivityTracker] Error handling inactivity timeout: $e');
    }
  }
  
  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppPaused();
        break;
    }
  }
  
  /// Handle app resumed (came to foreground)
  void _handleAppResumed() {
    _isAppInForeground = true;
    
    if (!_isTracking) return;
    
    // Check if inactivity timeout was exceeded while app was in background
    if (_lastActivityTime != null) {
      final inactiveDuration = DateTime.now().difference(_lastActivityTime!);
      
      if (inactiveDuration >= inactivityDuration) {
        print('⚠️ [InactivityTracker] Inactivity timeout exceeded while app was in background');
        _handleInactivityTimeout();
        return;
      }
    }
    
    // Resume tracking
    _resetInactivityTimer();
    print('🔒 [InactivityTracker] App resumed - tracking resumed');
  }
  
  /// Handle app paused (went to background)
  void _handleAppPaused() {
    _isAppInForeground = false;
    
    // Pause the timer but keep tracking the last activity time
    _inactivityTimer?.cancel();
    
    print('🔒 [InactivityTracker] App paused - tracking paused');
  }
  
  /// Get time since last activity
  Duration? getTimeSinceLastActivity() {
    if (_lastActivityTime == null) return null;
    return DateTime.now().difference(_lastActivityTime!);
  }
  
  /// Get remaining time until timeout
  Duration? getRemainingTime() {
    final timeSinceActivity = getTimeSinceLastActivity();
    if (timeSinceActivity == null) return null;
    
    final remaining = inactivityDuration - timeSinceActivity;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Check if currently tracking
  bool get isTracking => _isTracking;
  
  /// Check if app is in foreground
  bool get isAppInForeground => _isAppInForeground;
  
  /// Dispose resources
  void dispose() {
    stop();
  }
}
