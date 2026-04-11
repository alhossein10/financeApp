import 'package:flutter/material.dart';
import '../services/security_manager.dart';

/// Widget that detects user activity and reports it to SecurityManager
/// Wraps the entire app to track all user interactions
/// 
/// Usage:
/// ```dart
/// MaterialApp(
///   home: ActivityDetector(
///     securityManager: securityManager,
///     child: HomePage(),
///   ),
/// );
/// ```
class ActivityDetector extends StatelessWidget {
  final Widget child;
  final SecurityManager securityManager;
  
  const ActivityDetector({
    Key? key,
    required this.child,
    required this.securityManager,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => securityManager.recordActivity(),
      onPanDown: (_) => securityManager.recordActivity(),
      onScaleStart: (_) => securityManager.recordActivity(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => securityManager.recordActivity(),
        onPointerMove: (_) => securityManager.recordActivity(),
        onPointerUp: (_) => securityManager.recordActivity(),
        child: child,
      ),
    );
  }
}

/// Mixin to add activity tracking to any StatefulWidget
/// 
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   _MyPageState createState() => _MyPageState();
/// }
/// 
/// class _MyPageState extends State<MyPage> with ActivityTrackingMixin {
///   @override
///   SecurityManager get securityManager => context.read<SecurityManager>();
///   
///   @override
///   Widget build(BuildContext context) {
///     return trackActivity(
///       child: Scaffold(
///         body: Center(child: Text('My Page')),
///       ),
///     );
///   }
/// }
/// ```
mixin ActivityTrackingMixin<T extends StatefulWidget> on State<T> {
  SecurityManager get securityManager;
  
  /// Wrap widget with activity tracking
  Widget trackActivity({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => securityManager.recordActivity(),
      onPanDown: (_) => securityManager.recordActivity(),
      onScaleStart: (_) => securityManager.recordActivity(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => securityManager.recordActivity(),
        onPointerMove: (_) => securityManager.recordActivity(),
        onPointerUp: (_) => securityManager.recordActivity(),
        child: child,
      ),
    );
  }
  
  /// Record activity manually
  void recordActivity() {
    securityManager.recordActivity();
  }
}
