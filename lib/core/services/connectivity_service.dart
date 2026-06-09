import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Broadcasts online/offline status for sync orchestration.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final StreamController<bool> _onlineController = StreamController<bool>.broadcast();

  Stream<bool> get onOnlineChanged => _onlineController.stream;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);
    _onlineController.add(_isOnline);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = _hasConnection(results);
      _onlineController.add(_isOnline);
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
