import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/model_extensions.dart';

class ProductProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger tous les produits
  Future<void> loadProducts(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _db.getProductsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un produit
  Future<bool> addProduct({
    required int userId,
    required String name,
    required double unitPrice,
    double? vatRate,
  }) async {
    _errorMessage = null;

    try {
      final productCompanion = CompanionHelpers.createProduct(
        userId: userId,
        name: name,
        unitPrice: unitPrice,
        vatRate: vatRate ?? 18.0,
      );

      final id = await _db.insertProduct(productCompanion);
      final newProduct = await _db.getProductById(id);
      if (newProduct != null) {
        _products.add(newProduct);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour un produit
  Future<bool> updateProduct({
    required int id,
    required String name,
    required double unitPrice,
    double? vatRate,
  }) async {
    _errorMessage = null;

    try {
      final index = _products.indexWhere((p) => p.id == id);
      if (index == -1) return false;

      final updatedProduct = _products[index].copyWith(
        name: name,
        unitPrice: unitPrice,
        vatRate: vatRate ?? _products[index].vatRate,
        updatedAt: DateTime.now(),
      );

      await _db.updateProduct(updatedProduct.toCompanion(true));
      _products[index] = updatedProduct;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Supprimer un produit (soft delete)
  Future<bool> deleteProduct(int id) async {
    _errorMessage = null;

    try {
      await _db.softDeleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Restaurer un produit
  Future<bool> restoreProduct(int id) async {
    _errorMessage = null;

    try {
      final success = await _db.restoreProduct(id);
      if (success) {
        // Recharger les produits pour inclure le produit restauré
        final userId = _products.isNotEmpty ? _products.first.userId : null;
        if (userId != null) {
          await loadProducts(userId);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la restauration: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Supprimer définitivement un produit
  Future<bool> permanentlyDeleteProduct(int id) async {
    _errorMessage = null;

    try {
      await _db.deleteProduct(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression définitive: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Récupérer un produit par son ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Rechercher des produits
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    final lowerQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery);
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