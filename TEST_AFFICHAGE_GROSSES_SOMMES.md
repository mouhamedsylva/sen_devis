# 🧪 Guide de Test - Affichage Intelligent des Grosses Sommes

## ✅ Fonctionnalité implémentée

L'affichage des montants s'adapte maintenant automatiquement selon leur taille pour garantir une lisibilité optimale.

## 📋 Comment tester

### 1. Prérequis
- Avoir des produits avec différents prix dans la base de données
- Ouvrir l'application Flutter

### 2. Scénarios de test

#### Test 1 : Petit montant (< 1M FCFA)
**Objectif** : Vérifier l'affichage normal

1. Créer un devis avec des produits pour un total < 1 000 000 FCFA
2. Exemple : 3 produits à 200 000 FCFA chacun = 600 000 FCFA HT
3. ✅ **Vérifier** :
   - Sous-total : `508 475 FCFA` (taille normale, 14px)
   - TVA : `91 525 FCFA` (taille normale, 14px)
   - Total : `600 000 FCFA` (taille normale, 20px, couleur verte)
   - Pas d'icône info
   - Tout tient sur une ligne

#### Test 2 : Montant moyen (1M - 10M FCFA)
**Objectif** : Vérifier la réduction légère

1. Créer un devis pour un total entre 1M et 10M FCFA
2. Exemple : 10 produits à 500 000 FCFA = 5 000 000 FCFA HT
3. ✅ **Vérifier** :
   - Sous-total : `4 237 288 FCFA` (légèrement réduit, 14px)
   - TVA : `762 712 FCFA` (taille normale, 14px)
   - Total : `5 000 000 FCFA` (légèrement réduit, 18px, couleur verte)
   - Pas d'icône info
   - Tout tient sur une ligne

#### Test 3 : Gros montant (10M - 100M FCFA)
**Objectif** : Vérifier la réduction importante

1. Créer un devis pour un total entre 10M et 100M FCFA
2. Exemple : 20 produits à 2 500 000 FCFA = 50 000 000 FCFA HT
3. ✅ **Vérifier** :
   - Sous-total : `42 372 881 FCFA` (réduit, 13px)
   - TVA : `7 627 119 FCFA` (légèrement réduit, 13px)
   - Total : `50 000 000 FCFA` (réduit, 16px, couleur verte)
   - Pas d'icône info
   - Tout tient sur une ligne

#### Test 4 : Très gros montant (100M - 1Mrd FCFA)
**Objectif** : Vérifier le format abrégé avec tooltip

1. Créer un devis pour un total > 100M FCFA
2. Exemple : 50 produits à 10 000 000 FCFA = 500 000 000 FCFA HT
3. ✅ **Vérifier** :
   - Sous-total : `ℹ️ 423,7M FCFA` (format abrégé, 14px)
   - TVA : `ℹ️ 76,3M FCFA` (format abrégé, 14px)
   - Total : `ℹ️ 500M FCFA` (format abrégé, 20px, couleur verte)
   - Icône info visible avant chaque montant
   - Cliquer/survoler l'icône → Tooltip avec montant complet
   - Tooltip Sous-total : "423 728 814 FCFA"
   - Tooltip TVA : "76 271 186 FCFA"
   - Tooltip Total : "500 000 000 FCFA"

#### Test 5 : Montant en milliards (> 1Mrd FCFA)
**Objectif** : Vérifier le format "Mrd"

1. Créer un devis pour un total > 1 000 000 000 FCFA
2. Exemple : 100 produits à 25 000 000 FCFA = 2 500 000 000 FCFA HT
3. ✅ **Vérifier** :
   - Sous-total : `ℹ️ 2,1Mrd FCFA` (format abrégé, 14px)
   - TVA : `ℹ️ 381,4M FCFA` (format abrégé, 14px)
   - Total : `ℹ️ 2,5Mrd FCFA` (format abrégé, 20px, couleur verte)
   - Icône info visible
   - Tooltip avec montant complet en FCFA

#### Test 6 : Montants mixtes
**Objectif** : Vérifier la cohérence avec différents montants

1. Créer plusieurs devis avec des montants variés
2. Naviguer entre les devis
3. ✅ **Vérifier** :
   - Chaque montant s'affiche correctement selon sa taille
   - Pas de bug d'affichage lors du changement
   - Les tooltips fonctionnent pour tous les montants > 100M

#### Test 7 : Responsive
**Objectif** : Vérifier sur différentes tailles d'écran

1. Tester sur mobile (petit écran)
2. Tester sur tablette (écran moyen)
3. Tester sur desktop (grand écran)
4. ✅ **Vérifier** :
   - Les montants restent lisibles sur tous les écrans
   - Pas de débordement de texte
   - Les tooltips s'affichent correctement

### 3. Points de vérification détaillés

#### Affichage visuel
- [ ] Les montants sont alignés à droite
- [ ] La couleur du total final est verte (primaryColor)
- [ ] Les autres montants sont en couleur texte standard
- [ ] L'icône info est visible uniquement pour les montants > 100M
- [ ] L'icône info est de taille 14px et de couleur grise

#### Tooltip
- [ ] Le tooltip apparaît au survol de l'icône info (desktop)
- [ ] Le tooltip apparaît au clic sur l'icône info (mobile)
- [ ] Le tooltip affiche le montant complet avec séparateurs
- [ ] Le tooltip a un fond sombre avec texte blanc
- [ ] Le tooltip se positionne au-dessus du montant

#### Formats abrégés
- [ ] 150 000 000 → "150M FCFA"
- [ ] 2 500 000 → "2,5M FCFA"
- [ ] 25 000 000 → "25M FCFA"
- [ ] 1 500 000 000 → "1,5Mrd FCFA"
- [ ] 15 000 000 000 → "15Mrd FCFA"

#### Tailles de police
- [ ] Montant < 1M : 20px (final) / 14px (sous-total)
- [ ] Montant 1M-10M : 18px (final) / 14px (sous-total)
- [ ] Montant 10M-100M : 16px (final) / 13px (sous-total)
- [ ] Montant > 100M : 20px (final) / 14px (sous-total) avec format abrégé

## 🐛 Problèmes possibles

### Les montants débordent encore
- Vérifier que vous avez bien redémarré l'application
- Vérifier que le code a été compilé correctement
- Essayer un hot restart complet

### Les tooltips ne s'affichent pas
- Sur mobile : essayer de maintenir le doigt sur l'icône info
- Sur desktop : essayer de survoler l'icône info
- Vérifier que l'icône info est bien visible

### Le format abrégé ne s'affiche pas
- Vérifier que le montant est bien > 100M FCFA
- Vérifier dans la console s'il y a des erreurs
- Essayer de recréer le devis

## 📱 Commande pour lancer l'app

```bash
flutter run
```

Pour un hot restart complet :
```bash
# Dans la console Flutter, taper :
R
```

## ✅ Résultat attendu

Après tous les tests, vous devriez avoir :
- ✅ Tous les montants lisibles quelle que soit leur taille
- ✅ Tailles de police adaptées automatiquement
- ✅ Format abrégé pour les montants > 100M
- ✅ Tooltips fonctionnels avec montants complets
- ✅ Icônes info visibles uniquement pour les montants abrégés
- ✅ Affichage cohérent sur tous les écrans
- ✅ Pas de débordement de texte

## 💡 Astuce

Pour tester rapidement les gros montants :
1. Créer un produit avec un prix élevé (ex: 50 000 000 FCFA)
2. Ajouter plusieurs fois ce produit au devis
3. Observer comment l'affichage s'adapte automatiquement

---

**Note** : Cette fonctionnalité est automatique et ne nécessite aucune configuration. Elle s'active dès que les montants dépassent les seuils définis.
