import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to check internet connectivity status.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if the device has an active internet connection.
  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
