# 🚀 Guide de démarrage rapide - Mode Offline

## Installation rapide

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Lancer l'app
flutter run
```

## Utilisation en 3 étapes

### 1️⃣ Ajouter le banner à un écran

```dart
import '../widgets/connectivity_banner.dart';

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

### 2️⃣ Ajouter l'indicateur dans l'AppBar

```dart
import '../widgets/connectivity_banner.dart';

AppBar(
  title: Text('Mon écran'),
  actions: [
    ConnectivityIndicator(showLabel: false),
    // ... autres actions
  ],
)
```

### 3️⃣ Vérifier l'état avant une action

```dart
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

void _myAction() {
  final connectivity = context.read<ConnectivityProvider>();
  
  if (connectivity.isOffline) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action impossible hors ligne')),
    );
    return;
  }
  
  // Effectuer l'action
}
```

## Widgets disponibles

### ConnectivityBanner
Banner en haut d'écran qui affiche l'état de connexion.

```dart
ConnectivityBanner(
  showWhenOnline: false, // Masquer quand online
  child: Scaffold(...),
)
```

### ConnectivityIndicator
Badge compact pour l'AppBar.

```dart
ConnectivityIndicator(
  showLabel: true, // Afficher "Hors ligne"
)
```

### OfflineAwareButton
Bouton qui se désactive automatiquement hors ligne.

```dart
OfflineAwareButton(
  requiresInternet: true,
  offlineMessage: 'Cette action nécessite internet',
  onPressed: () => _syncData(),
  child: Text('Synchroniser'),
)
```

### OnlineOnly / OfflineOnly
Widgets conditionnels.

```dart
OnlineOnly(
  child: Text('Visible uniquement en ligne'),
  offlineWidget: Text('Message alternatif'),
)

OfflineOnly(
  child: Text('Visible uniquement hors ligne'),
)
```

## Propriétés du ConnectivityProvider

```dart
final connectivity = context.watch<ConnectivityProvider>();

// États booléens
connectivity.isOnline          // true si internet accessible
connectivity.isOffline         // true si hors ligne
connectivity.isConnectedToNetwork  // true si connecté au réseau
connectivity.hasInternetAccess // true si accès internet réel

// Informations
connectivity.connectionType    // "WiFi", "Données mobiles", etc.
connectivity.statusMessage     // Message pour l'utilisateur
connectivity.isChecking        // true pendant la vérification

// Actions
connectivity.checkConnectivity()  // Vérification manuelle
```

## Exemples rapides

### Écran complet

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mon écran'),
          actions: [
            ConnectivityIndicator(showLabel: false),
          ],
        ),
        body: Center(
          child: OfflineAwareButton(
            requiresInternet: true,
            onPressed: () => _syncData(),
            child: Text('Synchroniser'),
          ),
        ),
      ),
    );
  }
  
  Future<void> _syncData() async {
    // Logique de synchronisation
  }
}
```

### Vérification conditionnelle

```dart
ElevatedButton(
  onPressed: () {
    final connectivity = context.read<ConnectivityProvider>();
    
    if (connectivity.isOffline) {
      // Afficher un message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fonctionnalité disponible uniquement en ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Action nécessitant internet
    _uploadToCloud();
  },
  child: Text('Upload'),
)
```

### Écouter les changements

```dart
class SmartWidget extends StatefulWidget {
  @override
  _SmartWidgetState createState() => _SmartWidgetState();
}

class _SmartWidgetState extends State<SmartWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final connectivity = context.watch<ConnectivityProvider>();
    
    if (connectivity.isOnline) {
      // Synchroniser automatiquement
      _autoSync();
    }
  }

  Future<void> _autoSync() async {
    // Logique de sync
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Tests

### Tester le mode offline

1. **Désactiver WiFi/données mobiles**
   - Le banner rouge apparaît
   - L'indicateur "Hors ligne" s'affiche
   - Les boutons avec `requiresInternet` se désactivent

2. **Activer le mode avion**
   - Même comportement

3. **WiFi sans internet**
   - L'app détecte l'absence d'internet réel
   - Affiche "Connecté mais pas d'accès internet"

4. **Rétablir la connexion**
   - Le banner devient vert
   - Message "Connexion rétablie"

## Documentation complète

- **Mode Offline** : `docs/OFFLINE_MODE.md`
- **Exemples** : `docs/EXAMPLES.md`
- **Implémentation** : `IMPLEMENTATION_COMPLETE.md`
- **README** : `README.md`

## Support

Pour toute question :
1. Consulter `docs/OFFLINE_MODE.md`
2. Voir les exemples dans `docs/EXAMPLES.md`
3. Créer une issue sur le repo

---

**C'est tout ! Votre app est maintenant offline-ready ! 🎉**
