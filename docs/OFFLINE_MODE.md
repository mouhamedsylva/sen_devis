# 📱 Mode Offline - Documentation

## Vue d'ensemble

L'application **SenDevis** fonctionne entièrement en mode **offline** (hors ligne). Toutes les données sont stockées localement sur l'appareil de l'utilisateur via SQLite.

## 🎯 Fonctionnalités

### 1. Détection de connectivité

L'application surveille en temps réel l'état de la connexion internet :

- **Connecté** : L'appareil a accès à internet
- **Hors ligne** : Pas d'accès internet (mais l'app fonctionne normalement)
- **Pas de réseau** : Aucune connexion réseau (WiFi/mobile désactivé)

### 2. Indicateurs visuels

#### ConnectivityBanner

Banner en haut de l'écran qui affiche l'état de connexion :

- 🟢 Vert : Connecté
- 🔴 Rouge : Hors ligne
- 🔵 Bleu : Vérification en cours

#### ConnectivityIndicator

Petit badge compact pour l'AppBar :

- Visible uniquement en mode hors ligne
- Affiche "Hors ligne" avec une icône

### 3. Fonctionnement offline

Toutes les fonctionnalités sont disponibles hors ligne :

✅ **Gestion des clients**

- Créer, modifier, supprimer des clients
- Rechercher dans la liste

✅ **Gestion des produits**

- Ajouter des produits/services
- Modifier les prix et taux de TVA

✅ **Création de devis**

- Générer des devis complets
- Calculs automatiques HT/TVA/TTC
- Numérotation automatique

✅ **Génération PDF**

- Création de PDF professionnels
- Stockage local des documents

✅ **Partage**

- Partage via applications installées (WhatsApp, Email, etc.)
- Pas besoin d'internet pour partager localement

## 🔧 Implémentation technique

### Architecture

```
ConnectivityService
    ↓
ConnectivityProvider (State Management)
    ↓
UI Components (Banner, Indicator, Snackbar)
```

### Packages utilisés

1. **connectivity_plus** (v6.1.5)
   - Détecte le type de connexion (WiFi, mobile, etc.)
   - Stream des changements de connectivité

2. **internet_connection_checker_plus** (v2.7.2)
   - Vérifie l'accès internet réel (pas juste la connexion réseau)
   - Ping vers des serveurs fiables

### Services

#### ConnectivityService

```dart
// Vérifier la connexion réseau
await connectivityService.isConnectedToNetwork();

// Vérifier l'accès internet réel
await connectivityService.hasInternetAccess();

// Vérification complète
await connectivityService.isFullyConnected();

// Type de connexion
await connectivityService.getConnectionType(); // "WiFi", "Données mobiles", etc.
```

#### ConnectivityProvider

```dart
// Dans un widget
final connectivity = Provider.of<ConnectivityProvider>(context);

// État
connectivity.isOnline      // true si internet accessible
connectivity.isOffline     // true si hors ligne
connectivity.statusMessage // Message pour l'utilisateur
connectivity.connectionType // "WiFi", "Données mobiles", etc.

// Actions
connectivity.checkConnectivity(); // Vérification manuelle
```

## 📱 Utilisation dans l'UI

### 1. Ajouter le ConnectivityBanner

Enveloppe un écran pour afficher le banner :

```dart
@override
Widget build(BuildContext context) {
  return ConnectivityBanner(
    child: Scaffold(
      appBar: AppBar(
        title: Text('Mon écran'),
      ),
      body: // ... votre contenu
    ),
  );
}
```

### 2. Ajouter l'indicateur dans l'AppBar

```dart
AppBar(
  title: Text('Mon écran'),
  actions: [
    ConnectivityIndicator(showLabel: false),
    // ... autres actions
  ],
)
```

### 3. Afficher des snackbars

```dart
// Écouter les changements
ConnectivityProvider connectivity = context.watch<ConnectivityProvider>();

// Dans initState ou didChangeDependencies
if (connectivity.isOffline) {
  ConnectivitySnackbar.show(context, false);
}
```

### 4. Conditionner des actions

```dart
ElevatedButton(
  onPressed: () {
    final connectivity = context.read<ConnectivityProvider>();

    if (connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette action nécessite une connexion internet'),
        ),
      );
      return;
    }

    // Action nécessitant internet
    _syncWithCloud();
  },
  child: Text('Synchroniser'),
)
```

## 🚀 Évolutions futures

### Synchronisation cloud (à venir)

Quand vous ajouterez un backend :

1. **Détection automatique**
   - L'app détecte quand la connexion revient
   - Lance la synchronisation automatiquement

2. **Queue de synchronisation**
   - Les actions offline sont mises en queue
   - Envoyées au serveur dès que possible

3. **Gestion des conflits**
   - Détection des modifications concurrentes
   - Résolution intelligente ou manuelle

### Structure préparée

```dart
class SyncService {
  final ConnectivityProvider _connectivity;

  Future<void> syncWhenOnline() async {
    if (_connectivity.isOnline) {
      await _syncClients();
      await _syncProducts();
      await _syncQuotes();
    }
  }
}
```

## 🧪 Tests

### Tester le mode offline

1. **Désactiver le WiFi/données mobiles**
   - Le banner rouge apparaît
   - L'indicateur "Hors ligne" s'affiche
   - Toutes les fonctionnalités restent accessibles

2. **Activer le mode avion**
   - Même comportement que ci-dessus

3. **Connexion WiFi sans internet**
   - L'app détecte l'absence d'internet réel
   - Affiche "Connecté mais pas d'accès internet"

4. **Rétablir la connexion**
   - Le banner devient vert
   - Message "Connexion rétablie"

## 📝 Bonnes pratiques

1. **Toujours vérifier avant les actions réseau**

   ```dart
   if (connectivity.isOnline) {
     // Action nécessitant internet
   }
   ```

2. **Informer l'utilisateur**
   - Utiliser les widgets fournis (Banner, Indicator)
   - Messages clairs et contextuels

3. **Graceful degradation**
   - Désactiver les fonctionnalités nécessitant internet
   - Proposer des alternatives offline

4. **Optimiser les vérifications**
   - Ne pas vérifier trop souvent
   - Utiliser les streams pour les mises à jour automatiques

## 🐛 Dépannage

### Le banner ne s'affiche pas

- Vérifier que `ConnectivityProvider` est dans le `MultiProvider`
- S'assurer que `ConnectivityBanner` enveloppe le Scaffold

### Faux positifs (dit "online" alors que hors ligne)

- `internet_connection_checker_plus` fait des pings réels
- Peut prendre quelques secondes pour détecter

### Permissions manquantes

- Android : `ACCESS_NETWORK_STATE` (ajouté automatiquement)
- iOS : Aucune permission spéciale requise

## 📚 Ressources

- [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- [internet_connection_checker_plus](https://pub.dev/packages/internet_connection_checker_plus)
- [Provider pattern](https://pub.dev/packages/provider)
