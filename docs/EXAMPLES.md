# 📚 Exemples d'utilisation - Mode Offline

Ce document contient des exemples pratiques d'intégration du mode offline dans différents scénarios.

## 1. Écran de base avec banner

```dart
import 'package:flutter/material.dart';
import '../widgets/connectivity_banner.dart';

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
          child: Text('Contenu de l\'écran'),
        ),
      ),
    );
  }
}
```

## 2. Vérifier l'état avant une action

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class SyncButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final connectivity = context.read<ConnectivityProvider>();
        
        if (connectivity.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synchronisation impossible hors ligne'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Effectuer la synchronisation
        await _performSync();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation réussie'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Text('Synchroniser'),
    );
  }
  
  Future<void> _performSync() async {
    // Logique de synchronisation
  }
}
```

## 3. Afficher du contenu conditionnel

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class ConditionalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        if (connectivity.isOffline) {
          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mode hors ligne : Les modifications seront '
                      'synchronisées lors de la prochaine connexion',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'Connecté - Synchronisation automatique active',
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## 4. Bouton avec état offline

```dart
import 'package:flutter/material.dart';
import '../widgets/offline_aware_button.dart';

class UploadButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OfflineAwareButton(
      requiresInternet: true,
      offlineMessage: 'L\'upload nécessite une connexion internet',
      onPressed: () {
        // Logique d'upload
        _uploadFile();
      },
      child: Text('Uploader le fichier'),
    );
  }
  
  Future<void> _uploadFile() async {
    // Logique d'upload
  }
}
```

## 5. Écouter les changements de connectivité

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/connectivity_banner.dart';

class SmartScreen extends StatefulWidget {
  @override
  _SmartScreenState createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen> {
  bool _wasOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final connectivity = context.watch<ConnectivityProvider>();
    
    // Détecter le retour en ligne
    if (_wasOffline && connectivity.isOnline) {
      _onBackOnline();
    }
    
    _wasOffline = connectivity.isOffline;
  }

  void _onBackOnline() {
    // Actions à effectuer quand la connexion revient
    print('Connexion rétablie - Lancement de la synchronisation');
    _syncData();
    
    ConnectivitySnackbar.show(context, true);
  }

  Future<void> _syncData() async {
    // Logique de synchronisation
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        appBar: AppBar(title: Text('Smart Screen')),
        body: Center(child: Text('Contenu')),
      ),
    );
  }
}
```

## 6. Widget qui se désactive automatiquement

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class CloudFeature extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        final isEnabled = connectivity.isOnline;
        
        return Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Card(
            child: ListTile(
              leading: Icon(
                Icons.cloud_upload,
                color: isEnabled ? Colors.blue : Colors.grey,
              ),
              title: Text('Backup cloud'),
              subtitle: Text(
                isEnabled 
                  ? 'Disponible' 
                  : 'Nécessite une connexion',
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: isEnabled ? (value) {
                  // Activer/désactiver le backup
                } : null,
              ),
              enabled: isEnabled,
            ),
          ),
        );
      },
    );
  }
}
```

## 7. Pull-to-refresh avec vérification

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class RefreshableList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final connectivity = context.read<ConnectivityProvider>();
        
        // Vérifier la connectivité
        await connectivity.checkConnectivity();
        
        if (connectivity.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible de rafraîchir hors ligne'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Rafraîchir les données depuis le serveur
        await _fetchDataFromServer();
      },
      child: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
          );
        },
      ),
    );
  }
  
  Future<void> _fetchDataFromServer() async {
    // Logique de récupération
  }
}
```

## 8. Afficher l'état dans un Dialog

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

void showConnectivityDialog(BuildContext context) {
  final connectivity = context.read<ConnectivityProvider>();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: connectivity.isOnline ? Colors.green : Colors.red,
          ),
          SizedBox(width: 12),
          Text('État de connexion'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Réseau', connectivity.isConnectedToNetwork ? 'Connecté' : 'Déconnecté'),
          _buildInfoRow('Internet', connectivity.hasInternetAccess ? 'Accessible' : 'Inaccessible'),
          _buildInfoRow('Type', connectivity.connectionType),
          SizedBox(height: 16),
          Text(
            connectivity.statusMessage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: connectivity.isOnline ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            connectivity.checkConnectivity();
          },
          child: Text('Vérifier'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    ),
  );
}
```

## 9. Service de synchronisation (préparation future)

```dart
import 'package:flutter/foundation.dart';
import '../providers/connectivity_provider.dart';

class SyncService {
  final ConnectivityProvider _connectivity;
  bool _isSyncing = false;
  
  SyncService(this._connectivity) {
    // Écouter les changements de connectivité
    _connectivity.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    if (_connectivity.isOnline && !_isSyncing) {
      syncAll();
    }
  }
  
  Future<void> syncAll() async {
    if (_isSyncing || _connectivity.isOffline) return;
    
    _isSyncing = true;
    
    try {
      debugPrint('🔄 Début de la synchronisation...');
      
      await _syncClients();
      await _syncProducts();
      await _syncQuotes();
      
      debugPrint('✅ Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ Erreur de synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _syncClients() async {
    // TODO: Implémenter la sync clients
    await Future.delayed(Duration(seconds: 1));
  }
  
  Future<void> _syncProducts() async {
    // TODO: Implémenter la sync produits
    await Future.delayed(Duration(seconds: 1));
  }
  
  Future<void> _syncQuotes() async {
    // TODO: Implémenter la sync devis
    await Future.delayed(Duration(seconds: 1));
  }
  
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
  }
}
```

## 10. Test de connectivité manuel

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class ConnectivityTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test de connectivité')),
      body: Consumer<ConnectivityProvider>(
        builder: (context, connectivity, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          connectivity.isOnline ? Icons.check_circle : Icons.cancel,
                          size: 64,
                          color: connectivity.isOnline ? Colors.green : Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          connectivity.statusMessage,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Type: ${connectivity.connectionType}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: connectivity.isChecking 
                    ? null 
                    : () => connectivity.checkConnectivity(),
                  icon: connectivity.isChecking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh),
                  label: Text(
                    connectivity.isChecking 
                      ? 'Vérification...' 
                      : 'Vérifier la connexion',
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Informations détaillées:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                _buildInfoCard('Réseau', connectivity.isConnectedToNetwork),
                _buildInfoCard('Internet', connectivity.hasInternetAccess),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoCard(String label, bool isActive) {
    return Card(
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          color: isActive ? Colors.green : Colors.red,
        ),
        title: Text(label),
        trailing: Text(
          isActive ? 'Actif' : 'Inactif',
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

---

Ces exemples couvrent la plupart des cas d'usage du mode offline. N'hésite pas à les adapter selon tes besoins !
