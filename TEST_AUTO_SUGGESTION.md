# 🧪 Guide de Test - Auto-suggestion de Produits

## ✅ Fonctionnalité implémentée

L'auto-suggestion de produits est maintenant fonctionnelle ! Les suggestions s'affichent directement dans la modale et les clics sont détectés correctement.

## 📋 Comment tester

### 1. Prérequis
- Avoir au moins 2-3 produits existants dans la base de données
- Ouvrir l'application Flutter

### 2. Étapes de test

#### Test 1 : Affichage des suggestions
1. Aller dans "Devis" → Créer un nouveau devis
2. Sélectionner un client
3. Cliquer sur le bouton "+" pour ajouter un produit
4. Cliquer sur "Créer un nouveau produit"
5. Dans le champ "Nom du produit", commencer à taper (ex: "cim" si vous avez un produit "Ciment")
6. ✅ **Vérifier** : Les suggestions apparaissent sous le champ dans un container gris

#### Test 2 : Clic sur une suggestion
1. Continuer depuis Test 1
2. Cliquer sur une des suggestions affichées
3. ✅ **Vérifier dans la console** :
   ```
   === onSuggestionsChanged CALLBACK ===
   Suggestions count: X
   === SUGGESTION TAPPED ===
   Product: [nom du produit]
   Price: [prix]
   VAT: [tva]
   === FIELDS UPDATED ===
   ```
4. ✅ **Vérifier dans l'interface** :
   - Le champ "Nom du produit" est pré-rempli
   - Le champ "Prix unitaire" est pré-rempli
   - Le champ "Taux de TVA" est pré-rempli
   - Le toggle "Taxable" est activé/désactivé selon le produit
   - Les suggestions disparaissent

#### Test 3 : Ajuster les valeurs
1. Continuer depuis Test 2
2. Modifier le prix ou la TVA si nécessaire
3. Saisir une quantité
4. Cliquer sur "Créer"
5. ✅ **Vérifier** : Le produit est ajouté au devis avec les valeurs ajustées

#### Test 4 : Créer un nouveau produit
1. Dans la modale de création
2. Taper un nom qui n'existe pas (ex: "Nouveau Produit Test")
3. ✅ **Vérifier** : Aucune suggestion n'apparaît
4. Remplir prix, TVA, quantité
5. Cliquer sur "Créer"
6. ✅ **Vérifier** : Le nouveau produit est créé en base ET ajouté au devis

#### Test 5 : Effacer la recherche
1. Dans la modale de création
2. Taper quelques lettres pour afficher des suggestions
3. Cliquer sur l'icône "X" dans le champ de recherche
4. ✅ **Vérifier** : Le champ est vidé ET les suggestions disparaissent

#### Test 6 : Recherche insensible à la casse
1. Taper en minuscules (ex: "ciment")
2. ✅ **Vérifier** : Les produits avec majuscules sont trouvés ("Ciment")

#### Test 7 : Limite de suggestions
1. Si vous avez plus de 5 produits avec des noms similaires
2. Taper une recherche qui correspond à beaucoup de produits
3. ✅ **Vérifier** : Maximum 5 suggestions sont affichées

## 🐛 Que vérifier dans la console

Quand vous tapez dans le champ :
```
=== onSuggestionsChanged CALLBACK ===
Suggestions count: 3
```

Quand vous cliquez sur une suggestion :
```
=== SUGGESTION TAPPED ===
Product: Ciment Portland
Price: 5000.0
VAT: 18.0
=== FIELDS UPDATED ===
```

## ❌ Problèmes possibles

### Les suggestions n'apparaissent pas
- Vérifier que vous avez des produits en base
- Vérifier que le nom tapé correspond à un produit existant
- Regarder la console pour voir si `onSuggestionsChanged` est appelé

### Les clics ne fonctionnent pas
- Vérifier dans la console si `SUGGESTION TAPPED` apparaît
- Si non, il y a un problème avec le ListTile.onTap
- Essayer de redémarrer l'application

### Les champs ne se remplissent pas
- Vérifier dans la console si `FIELDS UPDATED` apparaît
- Si oui mais les champs ne changent pas, problème avec setSheet()

## 🎉 Résultat attendu

Après tous les tests, vous devriez avoir :
- ✅ Suggestions qui apparaissent en temps réel
- ✅ Clics détectés sur les suggestions
- ✅ Champs pré-remplis automatiquement
- ✅ Possibilité d'ajuster les valeurs
- ✅ Création de nouveaux produits toujours possible
- ✅ Logs visibles dans la console

## 📱 Commande pour lancer l'app

```bash
flutter run
```

Ou si vous utilisez un émulateur spécifique :
```bash
flutter run -d chrome  # Pour le web
flutter run -d windows # Pour Windows
```

---

**Note** : Si vous rencontrez des problèmes, vérifiez d'abord les logs dans la console. Tous les événements importants sont loggés avec `debugPrint`.
