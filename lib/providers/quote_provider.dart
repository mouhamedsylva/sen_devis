import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/model_extensions.dart';
import 'package:drift/drift.dart' as drift;

class QuoteProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  List<QuoteWithClient> _quotesWithClients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Quote> get quotes => _quotesWithClients.map((qwc) => qwc.quote).toList();
  List<QuoteWithClient> get quotesWithClients => _quotesWithClients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger tous les devis avec leurs clients
  Future<void> loadQuotes(int userId) async {
    _isLoading = true;
    // Ne pas notifier immédiatement pour éviter setState pendant build

    try {
      _quotesWithClients = await _db.getQuotesWithClients(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger un devis avec ses articles
  Future<QuoteWithDetails?> loadQuoteWithItems(int quoteId) async {
    try {
      return await _db.getQuoteWithDetails(quoteId);
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du devis: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Créer un nouveau devis
  Future<QuoteWithDetails?> createQuote({
    required int userId,
    required int clientId,
    required DateTime quoteDate,
    required List<QuoteItem> items,
    String? notes,
    String? quoteNumber, // ✅ Paramètre optionnel pour le numéro de devis
    bool depositRequired = true,
    String depositType = 'percentage',
    double depositPercentage = 40.0,
    double depositAmount = 0.0,
    int validityDays = 30,
    String? deliveryDelay,
  }) async {
    _errorMessage = null;

    try {
      // Générer le numéro de devis si non fourni
      final finalQuoteNumber = quoteNumber ?? await _db.generateQuoteNumber();

      // Utiliser une transaction pour garantir la cohérence
      final quoteId = await _db.executeInTransaction(() async {
        // Créer le devis
        final quoteCompanion = CompanionHelpers.createQuote(
          userId: userId,
          quoteNumber: finalQuoteNumber,
          clientId: clientId,
          quoteDate: quoteDate,
          notes: notes,
          depositRequired: depositRequired,
          depositType: depositType,
          depositPercentage: depositPercentage,
          depositAmount: depositAmount,
          validityDays: validityDays,
          deliveryDelay: deliveryDelay,
        );

        final id = await _db.insertQuote(quoteCompanion);

        // Insérer les articles et calculer les totaux
        double totalHT = 0.0;
        double totalVAT = 0.0;
        double totalTTC = 0.0;

        for (var item in items) {
          final itemCompanion = CompanionHelpers.createQuoteItem(
            quoteId: id,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            vatRate: item.vatRate,
          );
          
          await _db.insertQuoteItem(itemCompanion);
          
          final ht = item.quantity * item.unitPrice;
          final vat = ht * item.vatRate / 100;
          final ttc = ht + vat;
          
          totalHT += ht;
          totalVAT += vat;
          totalTTC += ttc;
        }

        // Mettre à jour les totaux du devis
        final quote = (await _db.getQuoteById(id))!;
        final updatedQuote = quote.copyWith(
          totalHT: totalHT,
          totalVAT: totalVAT,
          totalTTC: totalTTC,
        );
        await _db.updateQuote(updatedQuote.toCompanion(true));

        return id;
      });

      // Recharger les devis
      await loadQuotes(userId);

      return await loadQuoteWithItems(quoteId);
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Mettre à jour un devis
  Future<bool> updateQuote({
    required int quoteId,
    required int clientId,
    required DateTime quoteDate,
    required List<QuoteItem> items,
    String? notes,
    String? status,
  }) async {
    _errorMessage = null;

    try {
      await _db.executeInTransaction(() async {
        // Supprimer les anciens articles
        await _db.deleteQuoteItemsByQuote(quoteId);

        // Insérer les nouveaux articles et calculer les totaux
        double totalHT = 0.0;
        double totalVAT = 0.0;
        double totalTTC = 0.0;

        for (var item in items) {
          final itemCompanion = CompanionHelpers.createQuoteItem(
            quoteId: quoteId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            vatRate: item.vatRate,
          );
          
          await _db.insertQuoteItem(itemCompanion);
          
          final ht = item.quantity * item.unitPrice;
          final vat = ht * item.vatRate / 100;
          final ttc = ht + vat;
          
          totalHT += ht;
          totalVAT += vat;
          totalTTC += ttc;
        }

        // Mettre à jour le devis
        final quote = (await _db.getQuoteById(quoteId))!;
        final updatedQuote = quote.copyWith(
          clientId: clientId,
          quoteDate: quoteDate,
          totalHT: totalHT,
          totalVAT: totalVAT,
          totalTTC: totalTTC,
          notes: drift.Value(notes),
          status: status ?? quote.status,
          updatedAt: DateTime.now(),
        );

        await _db.updateQuote(updatedQuote.toCompanion(true));
      });

      // Recharger le devis dans la liste
      final index = _quotesWithClients.indexWhere((qwc) => qwc.quote.id == quoteId);
      if (index != -1) {
        final updatedQuoteDetails = await loadQuoteWithItems(quoteId);
        if (updatedQuoteDetails != null) {
          _quotesWithClients[index] = QuoteWithClient(
            quote: updatedQuoteDetails.quote,
            client: updatedQuoteDetails.client,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Changer le statut d'un devis
  Future<bool> updateQuoteStatus(int quoteId, String status) async {
    _errorMessage = null;

    try {
      final quote = await _db.getQuoteById(quoteId);
      if (quote == null) return false;

      final updatedQuote = quote.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      await _db.updateQuote(updatedQuote.toCompanion(true));

      final index = _quotesWithClients.indexWhere((qwc) => qwc.quote.id == quoteId);
      if (index != -1) {
        _quotesWithClients[index] = QuoteWithClient(
          quote: updatedQuote,
          client: _quotesWithClients[index].client,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du statut';
      notifyListeners();
      return false;
    }
  }

  // Supprimer un devis (soft delete)
  Future<bool> deleteQuote(int id) async {
    _errorMessage = null;

    try {
      await _db.softDeleteQuote(id);
      _quotesWithClients.removeWhere((qwc) => qwc.quote.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Restaurer un devis
  Future<bool> restoreQuote(int id) async {
    _errorMessage = null;

    try {
      final success = await _db.restoreQuote(id);
      if (success) {
        // Recharger les devis pour inclure le devis restauré
        final userId = _quotesWithClients.isNotEmpty ? _quotesWithClients.first.quote.userId : null;
        if (userId != null) {
          await loadQuotes(userId);
        }
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erreur lors de la restauration: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Supprimer définitivement un devis
  Future<bool> permanentlyDeleteQuote(int id) async {
    _errorMessage = null;

    try {
      await _db.deleteQuote(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression définitive: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Filtrer par statut
  List<Quote> getQuotesByStatus(String status) {
    return _quotesWithClients
        .where((qwc) => qwc.quote.status == status)
        .map((qwc) => qwc.quote)
        .toList();
  }

  // Rechercher des devis
  List<Quote> searchQuotes(String query) {
    if (query.isEmpty) return quotes;
    
    final lowerQuery = query.toLowerCase();
    return _quotesWithClients.where((qwc) {
      return qwc.quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
             qwc.client?.name.toLowerCase().contains(lowerQuery) == true;
    }).map((qwc) => qwc.quote).toList();
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
