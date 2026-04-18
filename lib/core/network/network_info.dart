import 'package:connectivity_plus/connectivity_plus.dart';

//   isConnected  → এখন internet আছে কিনা (one-time check)
//   onConnectivityChanged → internet status বদলালে stream দাও

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  const NetworkInfoImpl(this.connectivity);

  // ──────────────────────────────────────────────
  // isConnected — এই মুহূর্তে internet আছে?
  // ──────────────────────────────────────────────
  @override
  Future<bool> get isConnected async {
    final results = await connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  // ──────────────────────────────────────────────
  // onConnectivityChanged — Status বদলালে notify করো
  // ──────────────────────────────────────────────
  // BLoC এ এই stream listen করবে।
  // Online হলে → true, Offline হলে → false emit করবে।
  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(
      (results) => _hasConnection(results),
    );
  }

  // Helper — ConnectivityResult list থেকে bool বের করো

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }
}
