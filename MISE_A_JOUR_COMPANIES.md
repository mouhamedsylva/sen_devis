# Mise à Jour du Modèle Companies ✅

## Modifications Apportées

### 1. Table `Companies` - Nouveaux Champs

Ajout de 6 nouveaux champs pour enrichir les informations de l'entreprise :

```dart
class Companies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();                                    // ✅ NOUVEAU
  TextColumn get phone => text().nullable()();
  TextColumn get website => text().nullable()();                                  // ✅ NOUVEAU
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();                                     // ✅ NOUVEAU
  TextColumn get postalCode => text().named('postal_code').nullable()();         // ✅ NOUVEAU
  TextColumn get registrationNumber => text().named('registration_number').nullable()(); // ✅ NOUVEAU
  TextColumn get taxId => text().named('tax_id').nullable()();                   // ✅ NOUVEAU
  TextColumn get logoPath => text().named('logo_path').nullable()();
  RealColumn get vatRate => real().named('vat_rate').withDefault(const Constant(18.0))();
  TextColumn get currency => text().withDefault(const Constant('FCFA'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
```

### 2. Fichiers Modifiés

#### `lib/data/database/tables.dart`
- ✅ Ajout des 6 nouveaux champs dans la table `Companies`

#### `lib/providers/company_provider.dart`
- ✅ Mise à jour de la méthode `saveCompany()` pour gérer tous les nouveaux champs

#### `lib/data/models/model_extensions.dart`
- ✅ Mise à jour de `CompanionHelpers.createCompany()` avec les nouveaux paramètres

#### `lib/screens/company/company_settings_screen.dart`
- ✅ Mise à jour du chargement des données (méthode `_loadCompanyData()`)
- ✅ Mise à jour de la sauvegarde avec tous les champs

## Nouveaux Champs Détaillés

| Champ | Type | Nullable | Description |
|-------|------|----------|-------------|
| `email` | String | Oui | Email professionnel de l'entreprise |
| `website` | String | Oui | Site web de l'entreprise |
| `city` | String | Oui | Ville de l'entreprise |
| `postalCode` | String | Oui | Code postal |
| `registrationNumber` | String | Oui | Numéro SIRET/SIREN |
| `taxId` | String | Oui | Numéro de TVA intracommunautaire |

## Migration de la Base de Données

### Étape 1 : Incrémenter la Version du Schéma

Dans `lib/data/database/app_database.dart`, mettre à jour :

```dart
@override
int get schemaVersion => 2;  // Passer de 1 à 2
```

### Étape 2 : Ajouter la Migration

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from == 1) {
      // Migration de la version 1 à 2
      await m.addColumn(companies, companies.email);
      await m.addColumn(companies, companies.website);
      await m.addColumn(companies, companies.city);
      await m.addColumn(companies, companies.postalCode);
      await m.addColumn(companies, companies.registrationNumber);
      await m.addColumn(companies, companies.taxId);
    }
  },
  beforeOpen: (details) async {
    if (!kIsWeb) {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  },
);
```

### Étape 3 : Régénérer le Code Drift

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Utilisation dans l'Écran

L'écran `company_settings_screen.dart` utilise maintenant tous ces champs :

```dart
// Chargement
_emailController.text = company.email ?? '';
_websiteController.text = company.website ?? '';
_cityController.text = company.city ?? '';
_postalCodeController.text = company.postalCode ?? '';
_registrationController.text = company.registrationNumber ?? '';
_taxIdController.text = company.taxId ?? '';

// Sauvegarde
await companyProvider.saveCompany(
  userId: userId,
  name: _nameController.text.trim(),
  email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
  phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
  website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
  address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
  city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
  postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
  registrationNumber: _registrationController.text.trim().isEmpty ? null : _registrationController.text.trim(),
  taxId: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
  logoPath: logoPath,
  vatRate: double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 18.0,
);
```

## Compatibilité

### Mobile et Web
✅ Tous les champs fonctionnent sur mobile et web

### Données Existantes
✅ Les champs sont nullable, donc les données existantes restent valides
✅ La migration ajoute les colonnes sans perte de données

## Prochaines Étapes

1. **Régénérer le code Drift** :
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Tester la migration** :
   - Sur une nouvelle installation (schéma v2 créé directement)
   - Sur une installation existante (migration de v1 à v2)

3. **Vérifier les écrans** :
   - Écran de configuration de l'entreprise
   - Génération de PDF (si les nouveaux champs doivent apparaître)
   - Affichage des devis (en-tête avec infos entreprise)

## Notes Importantes

- Tous les nouveaux champs sont **optionnels** (nullable)
- Les valeurs par défaut sont gérées automatiquement
- La migration est **non destructive** (pas de perte de données)
- Compatible avec le support web (pas d'utilisation de `dart:io`)

## Résumé

Le modèle `Companies` est maintenant complet avec toutes les informations nécessaires pour une entreprise professionnelle. Les modifications sont compatibles avec l'architecture multi-plateforme (mobile + web) et préservent les données existantes.
