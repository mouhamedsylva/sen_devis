import '../database/app_database.dart';
import 'package:drift/drift.dart' as drift;

// Extensions pour garder la compatibilité avec l'ancien code
// Note : Les méthodes toCompanion() et copyWith() sont générées automatiquement par drift

// ==================== STRING STATUS EXTENSION ====================

extension QuoteStatusExtension on String {
  String get label {
    switch (this) {
      case 'draft':
        return 'Brouillon';
      case 'sent':
        return 'Envoyé';
      case 'accepted':
        return 'Accepté';
      default:
        return this;
    }
  }
}

// ==================== CLIENT ====================

extension ClientExtension on Client {
  String get displayName {
    if (phone != null && phone!.isNotEmpty) {
      return '$name ($phone)';
    }
    return name;
  }
}

// ==================== PRODUCT ====================

extension ProductExtension on Product {
  // Calcul du prix TTC
  double get priceTTC {
    return unitPrice * (1 + vatRate / 100);
  }

  // Calcul de la TVA
  double get vatAmount {
    return unitPrice * (vatRate / 100);
  }
}

// ==================== QUOTE ====================

extension QuoteExtension on Quote {
  // Calculer les totaux à partir des items
  Quote copyWithTotals(List<QuoteItem> items) {
    double totalHT = 0.0;
    double totalVAT = 0.0;
    double totalTTC = 0.0;

    for (var item in items) {
      totalHT += item.totalHT;
      totalVAT += item.totalVAT;
      totalTTC += item.totalTTC;
    }

    return copyWith(
      totalHT: totalHT,
      totalVAT: totalVAT,
      totalTTC: totalTTC,
    );
  }
  
  // Calculer la date d'expiration du devis
  DateTime get expirationDate {
    return quoteDate.add(Duration(days: validityDays));
  }
  
  // Vérifier si le devis est expiré
  bool get isExpired {
    return DateTime.now().isAfter(expirationDate);
  }
  
  // Calculer le montant de l'acompte
  double get depositAmount {
    if (!depositRequired) return 0.0;
    return totalTTC * (depositPercentage / 100);
  }
  
  // Calculer le solde restant
  double get remainingAmount {
    if (!depositRequired) return totalTTC;
    return totalTTC - depositAmount;
  }
}

// ==================== QUOTE ITEM ====================

extension QuoteItemExtension on QuoteItem {
  // Recalculer les totaux
  QuoteItem recalculate() {
    final ht = quantity * unitPrice;
    final vat = ht * vatRate / 100;
    final ttc = ht + vat;

    return copyWith(
      totalHT: ht,
      totalVAT: vat,
      totalTTC: ttc,
    );
  }
  
  // Créer un QuoteItem temporaire pour le formulaire (sans ID)
  static QuoteItem createTemp({
    required int productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    required double vatRate,
  }) {
    final ht = quantity * unitPrice;
    final vat = ht * vatRate / 100;
    final ttc = ht + vat;
    
    return QuoteItem(
      id: 0, // Temporaire
      quoteId: 0, // Temporaire
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      vatRate: vatRate,
      totalHT: ht,
      totalVAT: vat,
      totalTTC: ttc,
      createdAt: DateTime.now(),
    );
  }

  // Identifiant sentinel pour distinguer la main d'œuvre des produits
  static const int laborSentinelId = -1;

  static bool isLaborItem(QuoteItem item) => item.productId == laborSentinelId;

  static QuoteItem createLaborTemp({
    required String description,
    required double hours,
    required double hourlyRate,
    double vatRate = 0.0,
  }) {
    final ht = hours * hourlyRate;
    final vat = ht * vatRate / 100;
    final ttc = ht + vat;

    return QuoteItem(
      id: 0,
      quoteId: 0,
      productId: laborSentinelId, // ✅ sentinel -1 → identifie la MO
      productName: description,
      quantity: hours,
      unitPrice: hourlyRate,
      vatRate: vatRate,
      totalHT: ht,
      totalVAT: vat,
      totalTTC: ttc,
      createdAt: DateTime.now(),
    );
  }
}

// ==================== HELPERS ====================

// Helper pour créer des Companions facilement
class CompanionHelpers {
  static ClientsCompanion createClient({
    required int userId,
    required String name,
    drift.Value<String?> phone = const drift.Value.absent(),
    drift.Value<String?> email = const drift.Value.absent(),
    drift.Value<String?> address = const drift.Value.absent(),
  }) {
    final now = DateTime.now();
    return ClientsCompanion.insert(
      userId: userId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      createdAt: now,
      updatedAt: now,
    );
  }

  static ProductsCompanion createProduct({
    required int userId,
    required String name,
    required double unitPrice,
    double vatRate = 18.0,
  }) {
    final now = DateTime.now();
    return ProductsCompanion.insert(
      userId: userId,
      name: name,
      unitPrice: unitPrice,
      vatRate: drift.Value(vatRate),
      createdAt: now,
      updatedAt: now,
    );
  }

  static QuotesCompanion createQuote({
    required int userId,
    required String quoteNumber,
    required int clientId,
    required DateTime quoteDate,
    String status = 'draft',
    String? notes,
    bool depositRequired = true,
    double depositPercentage = 40.0,
    int validityDays = 30,
    String? deliveryDelay,
  }) {
    final now = DateTime.now();
    return QuotesCompanion.insert(
      userId: userId,
      quoteNumber: quoteNumber,
      clientId: clientId,
      quoteDate: quoteDate,
      status: drift.Value(status),
      notes: drift.Value(notes),
      depositRequired: drift.Value(depositRequired),
      depositPercentage: drift.Value(depositPercentage),
      validityDays: drift.Value(validityDays),
      deliveryDelay: drift.Value(deliveryDelay),
      createdAt: now,
      updatedAt: now,
    );
  }

  static QuoteItemsCompanion createQuoteItem({
    required int quoteId,
    int? productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    required double vatRate,
  }) {
    final totalHT = quantity * unitPrice;
    final totalVAT = totalHT * vatRate / 100;
    final totalTTC = totalHT + totalVAT;

    return QuoteItemsCompanion.insert(
      quoteId: quoteId,
      productId: drift.Value(productId),
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      vatRate: vatRate,
      totalHT: totalHT,
      totalVAT: totalVAT,
      totalTTC: totalTTC,
      createdAt: DateTime.now(),
    );
  }

  static CompaniesCompanion createCompany({
    required int userId,
    required String name,
    drift.Value<String?> email = const drift.Value.absent(),
    dynamic phone, // Accepte String ou drift.Value<String?>
    drift.Value<String?> website = const drift.Value.absent(),
    drift.Value<String?> address = const drift.Value.absent(),
    drift.Value<String?> city = const drift.Value.absent(),
    drift.Value<String?> postalCode = const drift.Value.absent(),
    drift.Value<String?> registrationNumber = const drift.Value.absent(),
    drift.Value<String?> taxId = const drift.Value.absent(),
    drift.Value<String?> logoPath = const drift.Value.absent(),
    drift.Value<String?> signaturePath = const drift.Value.absent(),
    double vatRate = 18.0,
    String currency = 'FCFA',
  }) {
    final now = DateTime.now();
    
    // Convertir phone en drift.Value si c'est une String
    final phoneValue = phone is String 
        ? drift.Value(phone) 
        : (phone as drift.Value<String?>? ?? const drift.Value.absent());
    
    return CompaniesCompanion.insert(
      userId: userId,
      name: name,
      email: email,
      phone: phoneValue,
      website: website,
      address: address,
      city: city,
      postalCode: postalCode,
      registrationNumber: registrationNumber,
      taxId: taxId,
      logoPath: logoPath,
      signaturePath: signaturePath,
      vatRate: drift.Value(vatRate),
      currency: drift.Value(currency),
      createdAt: now,
      updatedAt: now,
    );
  }

  static UsersCompanion createUser({
    required String phone,
    required String password,
  }) {
    final now = DateTime.now();
    return UsersCompanion.insert(
      phone: phone,
      password: password,
      createdAt: now,
      updatedAt: now,
    );
  }
}
