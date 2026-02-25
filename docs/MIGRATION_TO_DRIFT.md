# 🔄 Migration de sqflite vers drift

## Pourquoi migrer ?

### Problèmes avec sqflite
- ❌ Pas de support web natif
- ❌ Requêtes non type-safe (String SQL brut)
- ❌ Pas de validation à la compilation
- ❌ Migrations manuelles complexes
- ❌ Code verbeux et répétitif

### Avantages de drift
- ✅ Support mobile + web + desktop
- ✅ Type-safe avec génération de code
- ✅ Validation à la compilation
- ✅ Migrations automatiques
- ✅ Requêtes en Dart (pas de SQL brut)
- ✅ Meilleure maintenabilité

## 📋 Plan de migration

### Phase 1 : Installation de drift

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.1
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

### Phase 2 : Définition des tables

**Avant (sqflite)** :
```dart
// lib/data/database/tables.dart
class Tables {
  static const String clients = '''
    CREATE TABLE clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';
}
```

**Après (drift)** :
```dart
// lib/data/database/tables.dart
import 'package:drift/drift.dart';

class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id')();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id')();
  TextColumn get name => text()();
  RealColumn get unitPrice => real().named('unit_price')();
  RealColumn get vatRate => real().named('vat_rate')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id')();
  TextColumn get quoteNumber => text().named('quote_number')();
  IntColumn get clientId => integer().named('client_id')();
  DateTimeColumn get quoteDate => dateTime().named('quote_date')();
  TextColumn get status => text()();
  RealColumn get totalHT => real().named('total_ht')();
  RealColumn get totalVAT => real().named('total_vat')();
  RealColumn get totalTTC => real().named('total_ttc')();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class QuoteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quoteId => integer().named('quote_id')();
  IntColumn get productId => integer().named('product_id').nullable()();
  TextColumn get productName => text().named('product_name')();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real().named('unit_price')();
  RealColumn get vatRate => real().named('vat_rate')();
  RealColumn get totalHT => real().named('total_ht')();
  RealColumn get totalVAT => real().named('total_vat')();
  RealColumn get totalTTC => real().named('total_ttc')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}

class Companies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id')();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get logoPath => text().named('logo_path').nullable()();
  RealColumn get vatRate => real().named('vat_rate')();
  TextColumn get currency => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phoneNumber => text().named('phone_number').unique()();
  TextColumn get passwordHash => text().named('password_hash')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}
```

### Phase 3 : Création de la base de données

```dart
// lib/data/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables.dart';

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
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Méthodes CRUD pour Users
  Future<List<User>> getAllUsers() => select(users).get();
  Future<User?> getUserByPhone(String phone) =>
      (select(users)..where((u) => u.phoneNumber.equals(phone))).getSingleOrNull();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  // Méthodes CRUD pour Clients
  Future<List<Client>> getClientsByUser(int userId) =>
      (select(clients)..where((c) => c.userId.equals(userId))).get();
  Future<Client?> getClient(int id) =>
      (select(clients)..where((c) => c.id.equals(id))).getSingleOrNull();
  Future<int> insertClient(ClientsCompanion client) => into(clients).insert(client);
  Future<bool> updateClient(ClientsCompanion client) => update(clients).replace(client);
  Future<int> deleteClient(int id) =>
      (delete(clients)..where((c) => c.id.equals(id))).go();

  // Méthodes CRUD pour Products
  Future<List<Product>> getProductsByUser(int userId) =>
      (select(products)..where((p) => p.userId.equals(userId))).get();
  Future<Product?> getProduct(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);
  Future<bool> updateProduct(ProductsCompanion product) => update(products).replace(product);
  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // Méthodes CRUD pour Quotes
  Future<List<Quote>> getQuotesByUser(int userId) =>
      (select(quotes)
        ..where((q) => q.userId.equals(userId))
        ..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();
  Future<Quote?> getQuote(int id) =>
      (select(quotes)..where((q) => q.id.equals(id))).getSingleOrNull();
  Future<int> insertQuote(QuotesCompanion quote) => into(quotes).insert(quote);
  Future<bool> updateQuote(QuotesCompanion quote) => update(quotes).replace(quote);
  Future<int> deleteQuote(int id) =>
      (delete(quotes)..where((q) => q.id.equals(id))).go();

  // Méthodes CRUD pour QuoteItems
  Future<List<QuoteItem>> getQuoteItems(int quoteId) =>
      (select(quoteItems)..where((qi) => qi.quoteId.equals(quoteId))).get();
  Future<int> insertQuoteItem(QuoteItemsCompanion item) => into(quoteItems).insert(item);
  Future<bool> updateQuoteItem(QuoteItemsCompanion item) => update(quoteItems).replace(item);
  Future<int> deleteQuoteItem(int id) =>
      (delete(quoteItems)..where((qi) => qi.id.equals(id))).go();
  Future<int> deleteQuoteItemsByQuote(int quoteId) =>
      (delete(quoteItems)..where((qi) => qi.quoteId.equals(quoteId))).go();

  // Méthodes CRUD pour Companies
  Future<Company?> getCompanyByUser(int userId) =>
      (select(companies)..where((c) => c.userId.equals(userId))).getSingleOrNull();
  Future<int> insertCompany(CompaniesCompanion company) => into(companies).insert(company);
  Future<bool> updateCompany(CompaniesCompanion company) => update(companies).replace(company);

  // Requêtes complexes avec jointures
  Future<List<QuoteWithClient>> getQuotesWithClients(int userId) {
    final query = select(quotes).join([
      leftOuterJoin(clients, clients.id.equalsExp(quotes.clientId))
    ])..where(quotes.userId.equals(userId));

    return query.map((row) {
      return QuoteWithClient(
        quote: row.readTable(quotes),
        client: row.readTableOrNull(clients),
      );
    }).get();
  }
}

// Classe helper pour les jointures
class QuoteWithClient {
  final Quote quote;
  final Client? client;

  QuoteWithClient({required this.quote, this.client});
}

// Connexion adaptative (mobile vs web)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web : utilise sql.js
      return WebDatabase.withStorage(
        await DriftWebStorage.indexedDbIfSupported('devis_db'),
      );
    } else {
      // Mobile/Desktop : utilise SQLite natif
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'devis.db'));
      return NativeDatabase(file);
    }
  });
}
```

### Phase 4 : Génération du code

```bash
# Générer les classes
flutter pub run build_runner build

# Ou en mode watch (regénère automatiquement)
flutter pub run build_runner watch
```

### Phase 5 : Adaptation des modèles

**Avant (sqflite)** :
```dart
class Client {
  final int? id;
  final int userId;
  final String name;
  // ...
  
  Map<String, dynamic> toMap() { /* ... */ }
  factory Client.fromMap(Map<String, dynamic> map) { /* ... */ }
}
```

**Après (drift)** :
```dart
// Les classes sont générées automatiquement !
// Client, Product, Quote, etc. sont créés par drift

// Extension pour compatibilité avec l'ancien code
extension ClientExtension on Client {
  // Méthodes utilitaires si nécessaire
  String get displayName {
    if (phone != null && phone!.isNotEmpty) {
      return '$name ($phone)';
    }
    return name;
  }
}
```

### Phase 6 : Mise à jour des providers

**Avant (sqflite)** :
```dart
class ClientProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  Future<void> loadClients(int userId) async {
    final db = await _db.database;
    final result = await db.query(
      'clients',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    _clients = result.map((map) => Client.fromMap(map)).toList();
    notifyListeners();
  }
}
```

**Après (drift)** :
```dart
class ClientProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  Future<void> loadClients(int userId) async {
    _clients = await _db.getClientsByUser(userId);
    notifyListeners();
  }
  
  Future<void> addClient(ClientsCompanion client) async {
    await _db.insertClient(client);
    await loadClients(client.userId.value);
  }
  
  Future<void> updateClient(Client client) async {
    await _db.updateClient(client.toCompanion(true));
    await loadClients(client.userId);
  }
}
```

### Phase 7 : Migrations (si nécessaire)

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from == 1) {
      // Ajouter une colonne email aux clients
      await m.addColumn(clients, clients.email);
    }
  },
  beforeOpen: (details) async {
    // Activer les foreign keys
    if (!kIsWeb) {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  },
);
```

## 📊 Comparaison des approches

| Critère | sqflite | drift | Gagnant |
|---------|---------|-------|---------|
| Support web | ❌ Non | ✅ Oui | drift |
| Type-safety | ❌ Non | ✅ Oui | drift |
| Génération code | ❌ Non | ✅ Oui | drift |
| Requêtes complexes | ⚠️ SQL brut | ✅ Dart | drift |
| Migrations | ⚠️ Manuelles | ✅ Assistées | drift |
| Performance | ✅ Excellente | ✅ Excellente | Égalité |
| Courbe d'apprentissage | ✅ Simple | ⚠️ Moyenne | sqflite |
| Maintenabilité | ⚠️ Moyenne | ✅ Excellente | drift |

## 🎯 Recommandation finale

### ✅ Utiliser drift pour :
- ✅ Support cross-platform (mobile + web)
- ✅ Type-safety et moins d'erreurs
- ✅ Requêtes complexes simplifiées
- ✅ Meilleure maintenabilité long terme
- ✅ Migrations automatiques

### ❌ Ne PAS utiliser sqflite + drift si :
- ❌ Complexité inutile (2 implémentations)
- ❌ Code dupliqué
- ❌ Maintenance difficile
- ❌ Risque d'incohérences

## 🚀 Étapes de migration

1. **Installer drift** (30 min)
2. **Définir les tables** (1h)
3. **Générer le code** (5 min)
4. **Créer AppDatabase** (1h)
5. **Adapter les providers** (2-3h)
6. **Tester** (2h)
7. **Déployer** (30 min)

**Total estimé** : 1 journée de travail

## 💡 Conseils

1. **Migration progressive**
   - Commencer par une table (ex: clients)
   - Tester complètement
   - Migrer les autres tables

2. **Garder les anciens modèles temporairement**
   - Créer des extensions sur les classes drift
   - Facilite la transition

3. **Tests**
   - Tester chaque opération CRUD
   - Vérifier les migrations
   - Tester sur mobile ET web

4. **Documentation**
   - Documenter les changements
   - Mettre à jour le README
   - Former l'équipe

## 📚 Ressources

- [drift documentation](https://drift.simonbinder.eu/)
- [drift examples](https://github.com/simolus3/drift/tree/develop/examples)
- [Migration guide](https://drift.simonbinder.eu/docs/advanced-features/migrations/)
- [Web support](https://drift.simonbinder.eu/web/)

---

**Conclusion** : Migrer vers drift est un investissement qui en vaut la peine pour une app cross-platform moderne et maintenable.
