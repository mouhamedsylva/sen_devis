# Support Web - SenDevis

## Génération de PDF sur le Web

L'application SenDevis supporte maintenant la génération de PDF sur le web grâce à une implémentation multi-plateforme.

### Fonctionnalités

#### Sur Mobile/Desktop
- Génération de PDF dans un fichier temporaire
- Partage via les applications natives (WhatsApp, Email, etc.)
- Ouverture avec l'application PDF par défaut

#### Sur Web
- Génération de PDF en mémoire (Uint8List)
- Téléchargement automatique du PDF via le navigateur
- Ouverture du PDF dans un nouvel onglet
- Partage limité aux fonctionnalités web (mailto, WhatsApp web)

### Architecture Technique

#### Services Adaptés

**PdfService** (`lib/services/pdf_service.dart`)
- Utilise des imports conditionnels pour gérer `dart:io` vs `dart:html`
- Retourne `File` sur mobile/desktop, `Uint8List` sur web
- Méthode `_savePdf()` adaptée selon la plateforme

**ShareService** (`lib/services/share_service.dart`)
- Accepte `dynamic` (File ou Uint8List) pour `pdfData`
- Sur web : télécharge le PDF via `Blob` et `AnchorElement`
- Sur mobile : utilise `share_plus` pour le partage natif

### Imports Conditionnels

```dart
// Dans pdf_service.dart et share_service.dart
import 'dart:io' if (dart.library.html) 'dart:html' as io;
```

Cette syntaxe permet d'importer `dart:io` sur mobile/desktop et `dart:html` sur web.

### Détection de Plateforme

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Code spécifique web
} else {
  // Code mobile/desktop
}
```

### Limitations Web

1. **Partage natif** : Le web ne supporte pas le partage de fichiers comme sur mobile
2. **WhatsApp** : Ouvre WhatsApp Web mais ne peut pas attacher automatiquement le PDF
3. **Email** : Ouvre le client email mais ne peut pas attacher automatiquement le PDF
4. **Stockage** : Pas de système de fichiers, tout est en mémoire

### Dépendances

Les packages suivants sont compatibles web :
- `pdf: ^3.10.7` - Génération PDF (compatible web)
- `printing: ^5.11.1` - Impression et prévisualisation (compatible web)
- `share_plus: ^7.2.1` - Partage (fonctionnalités limitées sur web)
- `url_launcher: ^6.2.1` - Ouverture d'URLs (compatible web)

### Test sur Web

Pour tester l'application sur le web :

```bash
flutter run -d chrome
```

Ou pour build :

```bash
flutter build web
```

### Notes Importantes

1. La signature électronique fonctionne sur web (stockée en base64)
2. Les images de logo peuvent être chargées depuis des URLs ou data URLs
3. Le téléchargement du PDF se fait automatiquement via le navigateur
4. L'ouverture du PDF se fait dans un nouvel onglet du navigateur

### Améliorations Futures

- Utiliser le package `printing` pour une meilleure prévisualisation web
- Implémenter un viewer PDF intégré pour le web
- Ajouter la possibilité d'envoyer le PDF par API (email backend)
