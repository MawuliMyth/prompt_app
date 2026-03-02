import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity.none;
  final StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityService() {
    _connectivity = Connectivity.none;
    _subscription = Connectivity().onConnectivityChanged.listen(_connectivity);
  }

  void dispose() {
    _subscription?.cancel();
    _connectivity = Connectivity.none;
  }
}
