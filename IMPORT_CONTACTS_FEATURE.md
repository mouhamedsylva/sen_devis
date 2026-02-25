# ✅ Fonctionnalité d'Import de Contacts

## Vue d'ensemble

Ajout d'une fonctionnalité complète d'import de contacts pour les clients, permettant d'importer depuis :
1. **Les contacts du téléphone** (Android/iOS)
2. **Un fichier CSV**

## Packages Ajoutés

| Package | Version | Usage |
|---------|---------|-------|
| `contacts_service` | ^0.6.3 | Accès aux contacts du téléphone |
| `permission_handler` | ^11.3.1 | Gestion des permissions |
| `file_picker` | ^8.1.4 | Sélection de fichiers |
| `csv` | ^6.0.0 | Parsing de fichiers CSV |

## Fichiers Créés

### 1. Service d'Import
**`lib/services/contact_import_service.dart`**
- Singleton service pour gérer l'import
- Méthodes pour importer depuis téléphone et CSV
- Parsing intelligent du CSV
- Gestion des permissions

### 2. Modèle de Contact
**`lib/models/imported_contact.dart`**
- Modèle simple pour les contacts importés
- Champs : name, phone, address
- Validation basique

### 3. Écran d'Import
**`lib/screens/clients/import_contacts_screen.dart`**
- Interface utilisateur complète
- Sélection multiple de contacts
- Prévisualisation avant import
- Gestion des erreurs

## Fonctionnalités

### Import depuis le Téléphone

**Processus :**
1. Demande de permission d'accès aux contacts
2. Récupération de tous les contacts
3. Extraction des informations (nom, téléphone, adresse)
4. Affichage dans une liste sélectionnable
5. Import des contacts sélectionnés

**Permissions requises :**
- Android : `READ_CONTACTS`
- iOS : `NSContactsUsageDescription`

### Import depuis CSV

**Format CSV supporté :**
```csv
Nom,Téléphone,Adresse
Jean Dupont,+221 77 123 45 67,123 Rue de la Paix
Marie Martin,+221 76 987 65 43,456 Avenue du Commerce
```

**Caractéristiques :**
- Détection automatique du séparateur (`,` ou `;`)
- Reconnaissance intelligente des colonnes
- Colonnes acceptées :
  - Nom : `nom`, `name`, `client`, `contact`
  - Téléphone : `téléphone`, `telephone`, `phone`, `tel`, `mobile`
  - Adresse : `adresse`, `address`, `rue`, `street`

### Interface Utilisateur

#### État Vide
- Deux boutons d'import stylisés
- Instructions claires
- Messages d'erreur si nécessaire

#### Liste de Contacts
- Checkbox pour sélection multiple
- "Tout sélectionner" / "Tout désélectionner"
- Compteur de sélection
- Prévisualisation des informations
- Avatar avec initiale
- Icônes pour téléphone et adresse

#### Bouton d'Import
- Dans l'AppBar de la liste des clients
- Icône : `file_upload_outlined`
- Tooltip : "Importer des contacts"

## Utilisation

### 1. Accès à la Fonctionnalité

Depuis l'écran de liste des clients :
```dart
// Bouton dans l'AppBar
IconButton(
  onPressed: () => Navigator.pushNamed(context, '/import-contacts'),
  icon: Icon(Icons.file_upload_outlined),
)
```

### 2. Import depuis Téléphone

```dart
final service = ContactImportService.instance;

// Vérifier/demander permission
final hasPermission = await service.requestContactsPermission();

// Importer
final contacts = await service.importFromPhone();
```

### 3. Import depuis CSV

```dart
final service = ContactImportService.instance;

// Sélectionner et importer
final contacts = await service.importFromCSV();
```

### 4. Sauvegarder les Contacts

```dart
for (final contact in selectedContacts) {
  await clientProvider.addClient(
    userId: userId,
    name: contact.name,
    phone: contact.phone,
    address: contact.address,
  );
}
```

## Gestion des Erreurs

### Erreurs Possibles

| Erreur | Cause | Solution |
|--------|-------|----------|
| Permission refusée | Utilisateur refuse l'accès | Demander à nouveau ou expliquer |
| Aucun contact trouvé | Téléphone vide ou CSV vide | Message informatif |
| Format CSV invalide | Colonnes manquantes | Vérifier le format |
| Erreur de lecture | Fichier corrompu | Réessayer avec un autre fichier |

### Messages Utilisateur

```dart
// Succès
'$successCount contact(s) importé(s) avec succès'

// Erreur partielle
'$successCount contact(s) importé(s), $errorCount erreur(s)'

// Erreur complète
'Erreur lors de l\'import: ${error.toString()}'
```

## Sécurité et Permissions

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

### iOS (Info.plist)

```xml
<key>NSContactsUsageDescription</key>
<string>Cette application a besoin d'accéder à vos contacts pour importer vos clients</string>
```

## Nettoyage des Données

### Numéros de Téléphone

Les numéros sont automatiquement nettoyés :
```dart
phone = phone?.replaceAll(RegExp(r'[^\d+]'), '');
```

**Avant :** `+221 77 123 45 67`  
**Après :** `+221771234567`

### Adresses

Les adresses sont formatées :
```dart
final parts = [street, city, postcode].where((p) => p.isNotEmpty);
address = parts.join(', ');
```

## Limitations

### Web
- ❌ Import depuis téléphone non disponible
- ✅ Import CSV fonctionne

### Mobile
- ✅ Import depuis téléphone
- ✅ Import CSV

### Taille des Fichiers
- CSV : Pas de limite technique
- Recommandé : < 1000 contacts pour performance

## Performance

### Optimisations

1. **Chargement asynchrone**
   - Pas de blocage de l'UI
   - Loading indicator pendant l'import

2. **Sélection multiple**
   - Set pour O(1) lookup
   - Pas de duplication

3. **Parsing CSV**
   - Détection intelligente des colonnes
   - Gestion des lignes vides

## Tests Recommandés

### Test 1 : Import Téléphone
1. Ouvrir l'écran d'import
2. Cliquer sur "Depuis le téléphone"
3. ✅ Vérifier la demande de permission
4. ✅ Vérifier l'affichage des contacts
5. ✅ Sélectionner quelques contacts
6. ✅ Importer et vérifier dans la liste

### Test 2 : Import CSV
1. Créer un fichier CSV de test
2. Ouvrir l'écran d'import
3. Cliquer sur "Depuis un fichier CSV"
4. ✅ Sélectionner le fichier
5. ✅ Vérifier le parsing
6. ✅ Importer et vérifier

### Test 3 : Sélection Multiple
1. Importer des contacts
2. ✅ Tester "Tout sélectionner"
3. ✅ Tester "Tout désélectionner"
4. ✅ Tester sélection individuelle
5. ✅ Vérifier le compteur

### Test 4 : Gestion d'Erreurs
1. ✅ Refuser la permission
2. ✅ Sélectionner un fichier invalide
3. ✅ Importer sans sélection
4. ✅ Vérifier les messages d'erreur

## Format CSV Recommandé

### Template Minimal
```csv
Nom,Téléphone,Adresse
```

### Template Complet
```csv
Nom,Téléphone,Adresse
Jean Dupont,+221771234567,123 Rue de la Paix, Dakar
Marie Martin,+221769876543,456 Avenue du Commerce, Thiès
Pierre Durand,+221785551234,789 Boulevard Central, Saint-Louis
```

### Avec Point-Virgule
```csv
Nom;Téléphone;Adresse
Jean Dupont;+221771234567;123 Rue de la Paix
```

## Évolutions Futures

### Court Terme
- [ ] Export de contacts en CSV
- [ ] Template CSV téléchargeable
- [ ] Validation des numéros de téléphone
- [ ] Détection des doublons

### Moyen Terme
- [ ] Import depuis Google Contacts
- [ ] Import depuis vCard (.vcf)
- [ ] Mapping personnalisé des colonnes CSV
- [ ] Prévisualisation du CSV avant import

### Long Terme
- [ ] Synchronisation bidirectionnelle
- [ ] Import depuis Excel
- [ ] Import depuis QR Code
- [ ] Import groupé avec photos

## Code Exemple

### Import Complet

```dart
// 1. Ouvrir l'écran d'import
Navigator.pushNamed(context, '/import-contacts');

// 2. Dans l'écran, importer depuis téléphone
final contacts = await ContactImportService.instance.importFromPhone();

// 3. Sélectionner les contacts
final selectedContacts = contacts.where((c) => isSelected(c)).toList();

// 4. Sauvegarder
for (final contact in selectedContacts) {
  await clientProvider.addClient(
    userId: userId,
    name: contact.name,
    phone: contact.phone,
    address: contact.address,
  );
}

// 5. Retour avec succès
Navigator.pop(context, true);
```

## Dépendances

### Graphe de Dépendances

```
ImportContactsScreen
    ├── ContactImportService
    │   ├── contacts_service (téléphone)
    │   ├── permission_handler (permissions)
    │   ├── file_picker (sélection fichier)
    │   └── csv (parsing)
    ├── ClientProvider (sauvegarde)
    └── AuthProvider (userId)
```

## Conclusion

Cette fonctionnalité permet d'importer rapidement des contacts existants dans l'application, évitant la saisie manuelle fastidieuse. Elle supporte deux sources principales (téléphone et CSV) et offre une interface intuitive avec sélection multiple.

**Impact utilisateur :** ⭐⭐⭐⭐⭐ (Très positif)  
**Complexité technique :** ⭐⭐⭐ (Moyenne)  
**Temps de développement :** ~2 heures  
**Gain de temps utilisateur :** Significatif (import vs saisie manuelle)

---

*Fonctionnalité implémentée le 10 février 2026*
