import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/model_extensions.dart';
import 'package:drift/drift.dart' as drift;

class ClientProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  List<Client> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger tous les clients
  Future<void> loadClients(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _db.getClientsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un client
  Future<bool> addClient({
    required int userId,
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    _errorMessage = null;

    try {
      final clientCompanion = CompanionHelpers.createClient(
        userId: userId,
        name: name,
        phone: drift.Value(phone),
        email: drift.Value(email),
        address: drift.Value(address),
      );

      final id = await _db.insertClient(clientCompanion);
      final newClient = await _db.getClientById(id);
      if (newClient != null) {
        _clients.add(newClient);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour un client
  Future<bool> updateClient({
    required int id,
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    _errorMessage = null;

    try {
      final index = _clients.indexWhere((c) => c.id == id);
      if (index == -1) return false;

      final updatedClient = _clients[index].copyWith(
        name: name,
        phone: drift.Value(phone),
        email: drift.Value(email),
        address: drift.Value(address),
        updatedAt: DateTime.now(),
      );

      await _db.updateClient(updatedClient.toCompanion(true));
      _clients[index] = updatedClient;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Supprimer un client
  Future<bool> deleteClient(int id) async {
    _errorMessage = null;

    try {
      // Vérifier si le client est utilisé dans des devis
      final quotes = await _db.getQuotesByClient(id);

      if (quotes.isNotEmpty) {
        _errorMessage = 'Ce client ne peut pas être supprimé car il est utilisé dans des devis';
        notifyListeners();
        return false;
      }

      await _db.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Récupérer un client par son ID
  Client? getClientById(int id) {
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Rechercher des clients
  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;
    
    final lowerQuery = query.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
             (client.phone?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    // Ne pas fermer la base de données car c'est un singleton partagé
    super.dispose();
  }
}
