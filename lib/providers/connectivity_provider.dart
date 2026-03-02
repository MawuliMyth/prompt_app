import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider for network connectivity status
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      _isChecking = true;
      final results = await Connectivity().checkConnectivity();

      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        _isOnline = true;
      } else {
        _isOnline = false;
      }

      _isChecking = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Connectivity check error: $e');
      }
      _isChecking = false;
      _isOnline = false;
      notifyListeners();
    }
  }

  void dispose() {
    _isOnline = false;
    _isChecking = false;
  }
}
