import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider for network connectivity status
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      // Check connectivity first
      await checkConnectivity();

      // Set up listener for real-time updates (skip on desktop where it may not work well)
      if (!kIsWeb && !_isDesktop) {
        _subscription = Connectivity().onConnectivityChanged.listen(
          _onConnectivityChanged,
          onError: (error) {
            if (kDebugMode) {
              debugPrint('Connectivity listener error: $error');
            }
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Connectivity init error: $e');
      }
      // Default to online if we can't check
      _isOnline = true;
    }
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateOnlineStatus(results);
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      _isOnline = true;
    } else if (results.contains(ConnectivityResult.none)) {
      _isOnline = false;
    }
    // If results contain bluetooth or other, keep current status

    // Only notify if status changed
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  /// Public method to manually check connectivity (for retry functionality)
  Future<void> checkConnectivity() async {
    try {
      _isChecking = true;
      notifyListeners();

      final results = await Connectivity().checkConnectivity();
      _updateOnlineStatus(results);

      _isChecking = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Connectivity check error: $e');
      }
      _isChecking = false;
      // On error, default to online to not block functionality
      _isOnline = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
