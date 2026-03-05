import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables.dart';
import 'database_connection.dart';
import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Companies,
  Clients,
  Products,
  Quotes,
  QuoteItems,
])
class AppDatabase extends _$AppDatabase {
  // Singleton pattern
  static AppDatabase? _instance;
  
  AppDatabase._internal() : super(connect());
  
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // Migration de la version 1 à 2 : Ajout des nouveaux champs Companies
        await m.addColumn(companies, companies.email);
        await m.addColumn(companies, companies.website);
        await m.addColumn(companies, companies.city);
        await m.addColumn(companies, companies.postalCode);
        await m.addColumn(companies, companies.registrationNumber);
        await m.addColumn(companies, companies.taxId);
      }
      if (from <= 2) {
        // Migration de la version 2 à 3 : Ajout du champ signature
        await m.addColumn(companies, companies.signaturePath);
      }
      if (from <= 3) {
        // Migration de la version 3 à 4 : Ajout du champ email pour les clients
        await m.addColumn(clients, clients.email);
      }
      if (from <= 4) {
        // Migration de la version 4 à 5 : Ajout des conditions de devis
        await m.addColumn(quotes, quotes.depositRequired);
        await m.addColumn(quotes, quotes.depositPercentage);
        await m.addColumn(quotes, quotes.validityDays);
        await m.addColumn(quotes, quotes.deliveryDelay);
      }
      if (from <= 5) {
        // Migration de la version 5 à 6 : Ajout du soft delete
        await m.addColumn(quotes, quotes.deletedAt);
        await m.addColumn(products, products.deletedAt);
      }
    },
    beforeOpen: (details) async {
      // Activer les foreign keys sur mobile/desktop
      if (!kIsWeb) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
  );

  // ==================== USERS ====================
  
  Future<List<User>> getAllUsers() => select(users).get();
  
  Future<User?> getUserByPhone(String phone) =>
      (select(users)..where((u) => u.phone.equals(phone))).getSingleOrNull();
  
  Future<User?> getUserById(int id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
  
  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);
  
  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  // ==================== COMPANIES ====================
  
  Future<Company?> getCompanyByUser(int userId) =>
      (select(companies)..where((c) => c.userId.equals(userId))).getSingleOrNull();
  
  Future<Company?> getCompanyById(int id) =>
      (select(companies)..where((c) => c.id.equals(id))).getSingleOrNull();
  
  Future<int> insertCompany(CompaniesCompanion company) => into(companies).insert(company);
  
  Future<bool> updateCompany(CompaniesCompanion company) => update(companies).replace(company);
  
  Future<int> deleteCompany(int id) =>
      (delete(companies)..where((c) => c.id.equals(id))).go();

  // ==================== CLIENTS ====================
  
  Future<List<Client>> getClientsByUser(int userId) =>
      (select(clients)
        ..where((c) => c.userId.equals(userId))
        ..orderBy([(c) => OrderingTerm.asc(c.name)])).get();
  
  Future<Client?> getClientById(int id) =>
      (select(clients)..where((c) => c.id.equals(id))).getSingleOrNull();
  
  Future<int> insertClient(ClientsCompanion client) => into(clients).insert(client);
  
  Future<bool> updateClient(ClientsCompanion client) => update(clients).replace(client);
  
  Future<int> deleteClient(int id) =>
      (delete(clients)..where((c) => c.id.equals(id))).go();
  
  Future<List<Client>> searchClients(int userId, String query) =>
      (select(clients)
        ..where((c) => c.userId.equals(userId) & c.name.like('%$query%'))
        ..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  // ==================== PRODUCTS ====================
  
  Future<List<Product>> getProductsByUser(int userId) =>
      (select(products)
        ..where((p) => p.userId.equals(userId) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
  
  Future<Product?> getProductById(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);
  
  Future<bool> updateProduct(ProductsCompanion product) => update(products).replace(product);
  
  // Soft delete
  Future<bool> softDeleteProduct(int id) async {
    final product = await getProductById(id);
    if (product == null) return false;
    
    final updated = product.copyWith(deletedAt: Value(DateTime.now()));
    return await update(products).replace(updated);
  }
  
  // Restaurer un produit
  Future<bool> restoreProduct(int id) async {
    final product = await getProductById(id);
    if (product == null) return false;
    
    final updated = product.copyWith(deletedAt: Value(null));
    return await update(products).replace(updated);
  }
  
  // Suppression définitive
  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();
  
  // Récupérer les produits supprimés
  Future<List<Product>> getDeletedProducts(int userId) =>
      (select(products)
        ..where((p) => p.userId.equals(userId) & p.deletedAt.isNotNull())
        ..orderBy([(p) => OrderingTerm.desc(p.deletedAt)])).get();
  
  Future<List<Product>> searchProducts(int userId, String query) =>
      (select(products)
        ..where((p) => p.userId.equals(userId) & p.name.like('%$query%') & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)])).get();

  // ==================== QUOTES ====================
  
  Future<List<Quote>> getQuotesByUser(int userId) =>
      (select(quotes)
        ..where((q) => q.userId.equals(userId) & q.deletedAt.isNull())
        ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();
  
  Future<Quote?> getQuoteById(int id) =>
      (select(quotes)..where((q) => q.id.equals(id))).getSingleOrNull();
  
  Future<Quote?> getQuoteByNumber(String quoteNumber) =>
      (select(quotes)..where((q) => q.quoteNumber.equals(quoteNumber))).getSingleOrNull();
  
  Future<int> insertQuote(QuotesCompanion quote) => into(quotes).insert(quote);
  
  Future<bool> updateQuote(QuotesCompanion quote) => update(quotes).replace(quote);
  
  // Soft delete
  Future<bool> softDeleteQuote(int id) async {
    final quote = await getQuoteById(id);
    if (quote == null) return false;
    
    final updated = quote.copyWith(deletedAt: Value(DateTime.now()));
    return await update(quotes).replace(updated);
  }
  
  // Restaurer un devis
  Future<bool> restoreQuote(int id) async {
    final quote = await getQuoteById(id);
    if (quote == null) return false;
    
    final updated = quote.copyWith(deletedAt: Value(null));
    return await update(quotes).replace(updated);
  }
  
  // Suppression définitive
  Future<int> deleteQuote(int id) =>
      (delete(quotes)..where((q) => q.id.equals(id))).go();
  
  // Récupérer les devis supprimés
  Future<List<Quote>> getDeletedQuotes(int userId) =>
      (select(quotes)
        ..where((q) => q.userId.equals(userId) & q.deletedAt.isNotNull())
        ..orderBy([(q) => OrderingTerm.desc(q.deletedAt)])).get();
  
  Future<List<Quote>> getQuotesByStatus(int userId, String status) =>
      (select(quotes)
        ..where((q) => q.userId.equals(userId) & q.status.equals(status) & q.deletedAt.isNull())
        ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();
  
  Future<List<Quote>> getQuotesByClient(int clientId) =>
      (select(quotes)
        ..where((q) => q.clientId.equals(clientId) & q.deletedAt.isNull())
        ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();

  // ==================== QUOTE ITEMS ====================
  
  Future<List<QuoteItem>> getQuoteItems(int quoteId) =>
      (select(quoteItems)..where((qi) => qi.quoteId.equals(quoteId))).get();
  
  Future<QuoteItem?> getQuoteItemById(int id) =>
      (select(quoteItems)..where((qi) => qi.id.equals(id))).getSingleOrNull();
  
  Future<int> insertQuoteItem(QuoteItemsCompanion item) => into(quoteItems).insert(item);
  
  Future<bool> updateQuoteItem(QuoteItemsCompanion item) => update(quoteItems).replace(item);
  
  Future<int> deleteQuoteItem(int id) =>
      (delete(quoteItems)..where((qi) => qi.id.equals(id))).go();
  
  Future<int> deleteQuoteItemsByQuote(int quoteId) =>
      (delete(quoteItems)..where((qi) => qi.quoteId.equals(quoteId))).go();

  // ==================== REQUÊTES COMPLEXES ====================
  
  // Devis avec client
  Future<List<QuoteWithClient>> getQuotesWithClients(int userId) {
    final query = select(quotes).join([
      leftOuterJoin(clients, clients.id.equalsExp(quotes.clientId))
    ])..where(quotes.userId.equals(userId) & quotes.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(quotes.createdAt)]);

    return query.map((row) {
      return QuoteWithClient(
        quote: row.readTable(quotes),
        client: row.readTableOrNull(clients),
      );
    }).get();
  }
  
  // Devis avec client et items
  Future<QuoteWithDetails?> getQuoteWithDetails(int quoteId) async {
    final quote = await getQuoteById(quoteId);
    if (quote == null) return null;
    
    final client = await getClientById(quote.clientId);
    final items = await getQuoteItems(quoteId);
    
    return QuoteWithDetails(
      quote: quote,
      client: client,
      items: items,
    );
  }

  // ==================== GÉNÉRATION NUMÉRO DE DEVIS ====================
  
  Future<String> generateQuoteNumber() async {
    final result = await customSelect(
      'SELECT MAX(CAST(SUBSTR(quote_number, ${AppConstants.quoteNumberPrefix.length + 1}) AS INTEGER)) as max_num FROM quotes',
      readsFrom: {quotes},
    ).getSingleOrNull();
    
    int nextNumber = 1;
    if (result != null && result.data['max_num'] != null) {
      nextNumber = (result.data['max_num'] as int) + 1;
    }
    
    return '${AppConstants.quoteNumberPrefix}${nextNumber.toString().padLeft(AppConstants.quoteNumberLength, '0')}';
  }

  // ==================== TRANSACTIONS ====================
  
  Future<T> executeInTransaction<T>(Future<T> Function() action) {
    return transaction(() => action());
  }
}

// Classes helper pour les jointures
class QuoteWithClient {
  final Quote quote;
  final Client? client;

  QuoteWithClient({required this.quote, this.client});
}

class QuoteWithDetails {
  final Quote quote;
  final Client? client;
  final List<QuoteItem> items;

  QuoteWithDetails({
    required this.quote,
    this.client,
    required this.items,
  });
}
