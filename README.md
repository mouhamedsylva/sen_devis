# SenDevis 📱

Application mobile Flutter de génération de devis professionnels pour l'Afrique, avec support complet du mode **offline**.

## 🎯 Fonctionnalités

### Gestion complète

- ✅ **Entreprise** : Configuration des informations, logo, taux de TVA
- ✅ **Clients** : Gestion des contacts clients
- ✅ **Produits/Services** : Catalogue avec prix et TVA
- ✅ **Devis** : Création, modification, suivi des statuts
- ✅ **PDF** : Génération de devis professionnels
- ✅ **Partage** : Export via WhatsApp, Email, etc.

### Mode Offline 🔌

- 📵 **Fonctionnement 100% hors ligne**
- 💾 **Stockage local SQLite**
- 🔄 **Détection automatique de connectivité**
- 📊 **Indicateurs visuels d'état**
- 🚀 **Architecture prête pour synchronisation cloud**

## 🚀 Installation

### Prérequis

- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Android Studio / Xcode (pour émulateurs)

### Étapes

1. **Cloner le projet**

```bash
git clone <votre-repo>
cd devis
```

2. **Installer les dépendances**

```bash
flutter pub get
```

3. **Lancer l'application**

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (limité)
flutter run -d chrome
```

## 📦 Packages principaux

| Package                            | Version | Usage                   |
| ---------------------------------- | ------- | ----------------------- |
| `provider`                         | ^6.1.1  | Gestion d'état          |
| `sqflite`                          | ^2.3.0  | Base de données locale  |
| `pdf`                              | ^3.10.7 | Génération PDF          |
| `printing`                         | ^5.11.1 | Impression/Export PDF   |
| `share_plus`                       | ^7.2.1  | Partage de fichiers     |
| `connectivity_plus`                | ^6.1.2  | Détection réseau        |
| `internet_connection_checker_plus` | ^2.5.2  | Vérification internet   |
| `image_picker`                     | ^1.0.4  | Upload d'images         |
| `intl`                             | ^0.20.2 | Formatage dates/nombres |

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/      # Constantes (strings, colors)
│   ├── theme/          # Thème de l'app
│   └── utils/          # Utilitaires (formatters, etc.)
├── data/
│   ├── database/       # SQLite setup
│   └── models/         # Modèles de données
├── providers/          # State management (Provider)
├── screens/            # Écrans de l'app
│   ├── auth/          # Connexion/Inscription
│   ├── clients/       # Gestion clients
│   ├── company/       # Paramètres entreprise
│   ├── home/          # Écran d'accueil
│   ├── products/      # Gestion produits
│   └── quotes/        # Gestion devis
├── services/          # Services (PDF, partage, connectivité)
├── widgets/           # Composants réutilisables
└── main.dart          # Point d'entrée
```

## 🔌 Mode Offline

L'application fonctionne entièrement hors ligne. Voir [docs/OFFLINE_MODE.md](docs/OFFLINE_MODE.md) pour la documentation complète.

### Utilisation rapide

```dart
// Ajouter le banner de connectivité
ConnectivityBanner(
  child: Scaffold(
    appBar: AppBar(
      title: Text('Mon écran'),
      actions: [
        ConnectivityIndicator(showLabel: false),
      ],
    ),
    body: // ... contenu
  ),
)

// Vérifier l'état
final connectivity = context.watch<ConnectivityProvider>();
if (connectivity.isOffline) {
  // Action pour mode offline
}

// Bouton intelligent
OfflineAwareButton(
  requiresInternet: true,
  onPressed: () => _syncWithCloud(),
  child: Text('Synchroniser'),
)
```

## 💾 Base de données

Structure SQLite locale :

- **users** : Utilisateurs de l'app
- **companies** : Informations entreprises
- **clients** : Clients des utilisateurs
- **products** : Catalogue produits/services
- **quotes** : Devis générés
- **quote_items** : Lignes de devis

Toutes les données sont isolées par `user_id`.

## 🎨 Thème

- **Devise** : FCFA (Franc CFA)
- **Langue** : Français (fr_FR)
- **TVA par défaut** : 18%
- **Design** : Material Design 3

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/

# Analyser le code
flutter analyze
```

## 📱 Plateformes supportées

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ⚠️ Web (fonctionnalités limitées)
- ⚠️ Desktop (non testé)

## 🔐 Sécurité

- Mots de passe hashés avec `crypto` (SHA-256)
- Données stockées localement (pas de cloud par défaut)
- Isolation des données par utilisateur

## 🚀 Roadmap

- [ ] Synchronisation cloud (Firebase/Backend custom)
- [ ] Export Excel
- [ ] Statistiques avancées
- [ ] Multi-devises
- [ ] Templates de devis personnalisables
- [ ] Signature électronique
- [ ] Notifications push

## 📄 Licence

Projet privé - Non publié sur pub.dev

## 👨‍💻 Développement

### Ajouter une nouvelle fonctionnalité

1. Créer le modèle dans `lib/data/models/`
2. Ajouter la table dans `lib/data/database/tables.dart`
3. Créer le provider dans `lib/providers/`
4. Créer les écrans dans `lib/screens/`
5. Ajouter les routes dans `main.dart`

### Conventions de code

- Utiliser `flutter_lints` (activé)
- Nommer les fichiers en `snake_case`
- Classes en `PascalCase`
- Variables/fonctions en `camelCase`
- Constantes en `SCREAMING_SNAKE_CASE`

## 🐛 Problèmes connus

Aucun pour le moment.

## 📞 Support

Pour toute question ou problème, créer une issue sur le repo.

---

**Fait avec ❤️ pour l'Afrique**
