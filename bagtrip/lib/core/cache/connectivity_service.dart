import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  bool _isOnline = true;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _mapResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _mapResults(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return false;
    return results.isNotEmpty;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
