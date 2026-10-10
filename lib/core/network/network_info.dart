import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { available, offline, unknown }

abstract class NetworkInfo {
  Future<NetworkStatus> checkStatus();
}

class ConnectivityNetworkInfo implements NetworkInfo {
  final Connectivity _connectivity;

  ConnectivityNetworkInfo(this._connectivity);

  @override
  Future<NetworkStatus> checkStatus() async {
    try {
      final connections = await _connectivity.checkConnectivity().timeout(
        const Duration(seconds: 5),
      );

      if (connections.isEmpty) {
        return NetworkStatus.unknown;
      }

      final hasNetwork = connections.any(
        (connection) => connection != ConnectivityResult.none,
      );

      return hasNetwork ? NetworkStatus.available : NetworkStatus.offline;
    } catch (_) {
      return NetworkStatus.unknown;
    }
  }
}
