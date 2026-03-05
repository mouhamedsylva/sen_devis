import 'package:flutter/material.dart';
import '../data/database/app_database.dart';

// Classe pour représenter un élément dans la corbeille
class TrashItem {
  final int id;
  final String type; // 'quote' ou 'product'
  final String title;
  final String subtitle;
  final DateTime deletedAt;
  final dynamic data; // Quote ou Product

  TrashItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.deletedAt,
    required this.data,
  });
}

class TrashProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  List<TrashItem> _trashItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TrashItem> get trashItems => _trashItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _trashItems.isEmpty;
  int get count => _trashItems.length;

  // Charger tous les éléments de la corbeille
  Future<void> loadTrash(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deletedQuotes = await _db.getDeletedQuotes(userId);
      final deletedProducts = await _db.getDeletedProducts(userId);

      _trashItems = [
        // Devis supprimés
        ...deletedQuotes.map((quote) => TrashItem(
          id: quote.id!,
          type: 'quote',
          title: 'Devis ${quote.quoteNumber}',
          subtitle: 'Supprimé le ${_formatDate(quote.deletedAt!)}',
          deletedAt: quote.deletedAt!,
          data: quote,
        )),
        
        // Produits supprimés
        ...deletedProducts.map((product) => TrashItem(
          id: product.id!,
          type: 'product',
          title: product.name,
          subtitle: 'Supprimé le ${_formatDate(product.deletedAt!)}',
          deletedAt: product.deletedAt!,
          data: product,
        )),
      ];

      // Trier par date de suppression (plus récent en premier)
      _trashItems.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restaurer un élément
  Future<bool> restoreItem(TrashItem item) async {
    _errorMessage = null;

    try {
      bool success = false;
      
      if (item.type == 'quote') {
        success = await _db.restoreQuote(item.id);
      } else if (item.type == 'product') {
        success = await _db.restoreProduct(item.id);
      }

      if (success) {
        _trashItems.removeWhere((i) => i.id == item.id && i.type == item.type);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la restauration: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Supprimer définitivement un élément
  Future<bool> permanentlyDeleteItem(TrashItem item) async {
    _errorMessage = null;

    try {
      if (item.type == 'quote') {
        await _db.deleteQuote(item.id);
      } else if (item.type == 'product') {
        await _db.deleteProduct(item.id);
      }

      _trashItems.removeWhere((i) => i.id == item.id && i.type == item.type);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Vider toute la corbeille
  Future<bool> emptyTrash() async {
    _errorMessage = null;

    try {
      for (var item in _trashItems) {
        if (item.type == 'quote') {
          await _db.deleteQuote(item.id);
        } else if (item.type == 'product') {
          await _db.deleteProduct(item.id);
        }
      }

      _trashItems.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du vidage: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Auto-nettoyage : supprimer les éléments de plus de X jours
  Future<int> autoCleanup(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    int deletedCount = 0;

    try {
      final itemsToDelete = _trashItems
          .where((item) => item.deletedAt.isBefore(cutoffDate))
          .toList();

      for (var item in itemsToDelete) {
        if (item.type == 'quote') {
          await _db.deleteQuote(item.id);
        } else if (item.type == 'product') {
          await _db.deleteProduct(item.id);
        }
        deletedCount++;
      }

      _trashItems.removeWhere((item) => item.deletedAt.isBefore(cutoffDate));
      notifyListeners();

      return deletedCount;
    } catch (e) {
      _errorMessage = 'Erreur lors du nettoyage automatique: ${e.toString()}';
      notifyListeners();
      return deletedCount;
    }
  }

  // Filtrer par type
  List<TrashItem> filterByType(String type) {
    return _trashItems.where((item) => item.type == type).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
