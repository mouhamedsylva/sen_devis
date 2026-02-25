import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Service de gestion de la connectivité réseau
/// Combine connectivity_plus (type de connexion) et internet_connection_checker_plus (accès internet réel)
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  // Streams
  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged.map((list) => list.first);
  Stream<InternetStatus> get internetStream => _internetChecker.onStatusChange;

  // État actuel
  ConnectivityResult? _currentConnectivity;
  InternetStatus _currentInternetStatus = InternetStatus.disconnected;

  ConnectivityResult? get currentConnectivity => _currentConnectivity;
  InternetStatus get currentInternetStatus => _currentInternetStatus;

  /// Vérifie si l'appareil est connecté à un réseau (WiFi, mobile, etc.)
  Future<bool> isConnectedToNetwork() async {
    final results = await _connectivity.checkConnectivity();
    _currentConnectivity = results.first;
    return _currentConnectivity != ConnectivityResult.none;
  }

  /// Vérifie si l'appareil a un accès internet réel
  Future<bool> hasInternetAccess() async {
    _currentInternetStatus = await _internetChecker.internetStatus;
    return _currentInternetStatus == InternetStatus.connected;
  }

  /// Vérifie la connectivité complète (réseau + internet)
  Future<bool> isFullyConnected() async {
    final hasNetwork = await isConnectedToNetwork();
    if (!hasNetwork) return false;
    return await hasInternetAccess();
  }

  /// Obtient le type de connexion actuel
  Future<String> getConnectionType() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.first;
    
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Données mobiles';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Autre';
      case ConnectivityResult.none:
      default:
        return 'Aucune connexion';
    }
  }

  /// Dispose les ressources
  void dispose() {
    // Les streams sont gérés automatiquement par les packages
  }
}
