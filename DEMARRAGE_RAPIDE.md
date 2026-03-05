# 🚀 Démarrage Rapide - SenDevis avec Corbeille

## 📋 Prérequis

- Flutter SDK 3.9.2 ou supérieur
- Android Studio ou VS Code
- Un émulateur Android ou un appareil physique

## 🔧 Installation

### 1. Cloner le Projet
```bash
cd /chemin/vers/le/projet/devis
```

### 2. Installer les Dépendances
```bash
flutter pub get
```

### 3. Générer les Fichiers Drift
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## ▶️ Lancer l'Application

### Sur Android
```bash
flutter run
```

### Sur un Émulateur Spécifique
```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>
```

### En Mode Debug
```bash
flutter run --debug
```

### En Mode Release
```bash
flutter run --release
```

## 🧪 Tester la Corbeille

### Accès Rapide
1. Lancez l'application
2. Connectez-vous ou créez un compte
3. Allez dans **Paramètres** (icône ⚙️)
4. Cliquez sur **Corbeille** dans la section "Gestion des données"

### Test Rapide
1. Créez un devis de test
2. Supprimez-le
3. Allez dans la corbeille
4. Vérifiez qu'il apparaît
5. Restaurez-le
6. Vérifiez qu'il réapparaît dans la liste des devis

## 🔍 Vérification de l'Installation

### Vérifier Flutter
```bash
flutter doctor
```

### Vérifier les Dépendances
```bash
flutter pub get
```

### Analyser le Code
```bash
flutter analyze
```

### Vérifier les Tests
```bash
flutter test
```

## 📱 Fonctionnalités de la Corbeille

### Accès
- **Chemin** : Paramètres → Gestion des données → Corbeille
- **Badge** : Affiche le nombre d'éléments supprimés

### Actions Disponibles
- ♻️ **Restaurer** : Récupère un élément supprimé
- 🗑️ **Supprimer définitivement** : Supprime sans possibilité de récupération
- 🧹 **Vider la corbeille** : Supprime tous les éléments

### Filtres
- **Tout** : Affiche tous les éléments
- **Devis** : Affiche uniquement les devis
- **Produits** : Affiche uniquement les produits

## 🐛 Dépannage

### Erreur de Build
```bash
# Nettoyer le projet
flutter clean

# Réinstaller les dépendances
flutter pub get

# Régénérer les fichiers Drift
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur de Base de Données
```bash
# Supprimer l'app de l'émulateur
# Relancer l'app pour recréer la base de données
flutter run
```

### Problème de Traduction
```bash
# Vérifier que toutes les clés sont présentes
grep -r "context.tr('trash')" lib/
```

## 📚 Documentation

### Guides Disponibles
- `GUIDE_CORBEILLE.md` : Guide utilisateur complet
- `IMPLEMENTATION_CORBEILLE.md` : Documentation technique
- `TESTS_CORBEILLE.md` : Plan de tests détaillé
- `RESUME_IMPLEMENTATION.md` : Résumé de l'implémentation

### Code Source
- `lib/screens/trash/trash_screen.dart` : Écran de la corbeille
- `lib/providers/trash_provider.dart` : Logique métier
- `lib/data/database/app_database.dart` : Méthodes de base de données

## 🎯 Checklist de Démarrage

- [ ] Flutter installé et configuré
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Fichiers Drift générés (`build_runner`)
- [ ] Application lancée sans erreur
- [ ] Compte créé ou connexion réussie
- [ ] Corbeille accessible depuis les paramètres
- [ ] Test de suppression/restauration effectué

## 💡 Conseils

### Développement
- Utilisez le hot reload (R) pour voir les changements rapidement
- Utilisez le hot restart (Shift+R) si nécessaire
- Activez le mode debug pour voir les logs

### Tests
- Testez d'abord en mode clair, puis en mode sombre
- Testez dans les 3 langues (FR / EN / ES)
- Testez sur différentes tailles d'écran

### Performance
- Utilisez le mode release pour tester les performances réelles
- Surveillez la mémoire avec Flutter DevTools
- Vérifiez les temps de chargement

## 🔗 Liens Utiles

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Drift](https://drift.simonbinder.eu/)
- [Documentation Provider](https://pub.dev/packages/provider)

## 📞 Support

Si vous rencontrez des problèmes :
1. Consultez la documentation
2. Vérifiez les logs avec `flutter logs`
3. Nettoyez et reconstruisez le projet
4. Créez une issue sur GitHub

---

**Bon développement ! 🎉**
