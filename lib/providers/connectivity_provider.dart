import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../services/connectivity_service.dart';

/// Provider pour gérer l'état de connectivité de l'application
class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  // État de connectivité
  bool _isConnectedToNetwork = false;
  bool _hasInternetAccess = false;
  String _connectionType = 'Aucune connexion';
  bool _isChecking = false;

  // Subscriptions
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  // Getters
  bool get isConnectedToNetwork => _isConnectedToNetwork;
  bool get hasInternetAccess => _hasInternetAccess;
  bool get isOffline => !_hasInternetAccess;
  bool get isOnline => _hasInternetAccess;
  String get connectionType => _connectionType;
  bool get isChecking => _isChecking;

  /// Message d'état pour l'utilisateur
  String get statusMessage {
    if (_isChecking) return 'Vérification...';
    if (!_isConnectedToNetwork) return 'Aucune connexion réseau';
    if (!_hasInternetAccess) return 'Connecté mais pas d\'accès internet';
    return 'Connecté à $_connectionType';
  }

  /// Icône d'état
  String get statusIcon {
    if (_isChecking) return '🔄';
    if (!_isConnectedToNetwork) return '📵';
    if (!_hasInternetAccess) return '⚠️';
    return '✅';
  }

  ConnectivityProvider() {
    _initialize();
  }

  /// Initialise le monitoring de la connectivité
  Future<void> _initialize() async {
    // Vérification initiale
    await checkConnectivity();

    // Écoute des changements de connectivité réseau
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (ConnectivityResult result) async {
        _isConnectedToNetwork = result != ConnectivityResult.none;
        _connectionType = await _connectivityService.getConnectionType();
        
        // Si déconnecté du réseau, pas besoin de vérifier internet
        if (!_isConnectedToNetwork) {
          _hasInternetAccess = false;
          notifyListeners();
        } else {
          // Vérifier l'accès internet réel
          await _checkInternetAccess();
        }
      },
      onError: (error) {
        debugPrint('Erreur connectivité: $error');
      },
    );

    // Écoute des changements d'accès internet
    _internetSubscription = _connectivityService.internetStream.listen(
      (InternetStatus status) {
        _hasInternetAccess = status == InternetStatus.connected;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erreur internet checker: $error');
      },
    );
  }

  /// Vérifie l'accès internet
  Future<void> _checkInternetAccess() async {
    try {
      _hasInternetAccess = await _connectivityService.hasInternetAccess();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur vérification internet: $e');
      _hasInternetAccess = false;
      notifyListeners();
    }
  }

  /// Vérifie manuellement la connectivité (pour pull-to-refresh par exemple)
  Future<void> checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    try {
      _isConnectedToNetwork = await _connectivityService.isConnectedToNetwork();
      _connectionType = await _connectivityService.getConnectionType();
      
      if (_isConnectedToNetwork) {
        _hasInternetAccess = await _connectivityService.hasInternetAccess();
      } else {
        _hasInternetAccess = false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification: $e');
      _isConnectedToNetwork = false;
      _hasInternetAccess = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
