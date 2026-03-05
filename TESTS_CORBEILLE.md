# 🧪 Plan de Tests - Fonctionnalité Corbeille

## 📋 Vue d'Ensemble

Ce document décrit les tests à effectuer pour valider la fonctionnalité de corbeille dans SenDevis.

## ✅ Tests Fonctionnels

### 1. Suppression et Affichage dans la Corbeille

#### Test 1.1 : Supprimer un Devis
**Objectif :** Vérifier qu'un devis supprimé apparaît dans la corbeille

**Étapes :**
1. Créer un nouveau devis
2. Supprimer le devis depuis la liste des devis
3. Aller dans Paramètres → Corbeille
4. Vérifier que le devis apparaît dans la corbeille

**Résultat attendu :**
- ✅ Le devis apparaît dans l'onglet "Tout"
- ✅ Le devis apparaît dans l'onglet "Devis"
- ✅ Le badge de la corbeille affiche "1"
- ✅ La date de suppression est affichée

#### Test 1.2 : Supprimer un Produit
**Objectif :** Vérifier qu'un produit supprimé apparaît dans la corbeille

**Étapes :**
1. Créer un nouveau produit
2. Supprimer le produit depuis la liste des produits
3. Aller dans Paramètres → Corbeille
4. Vérifier que le produit apparaît dans la corbeille

**Résultat attendu :**
- ✅ Le produit apparaît dans l'onglet "Tout"
- ✅ Le produit apparaît dans l'onglet "Produits"
- ✅ Le badge de la corbeille s'incrémente
- ✅ La date de suppression est affichée

#### Test 1.3 : Supprimer Plusieurs Éléments
**Objectif :** Vérifier que plusieurs éléments peuvent être dans la corbeille

**Étapes :**
1. Supprimer 2 devis
2. Supprimer 3 produits
3. Aller dans la corbeille

**Résultat attendu :**
- ✅ L'onglet "Tout" affiche 5 éléments
- ✅ L'onglet "Devis" affiche 2 éléments
- ✅ L'onglet "Produits" affiche 3 éléments
- ✅ Le badge affiche "5"

### 2. Restauration d'Éléments

#### Test 2.1 : Restaurer un Devis
**Objectif :** Vérifier qu'un devis peut être restauré

**Étapes :**
1. Supprimer un devis
2. Aller dans la corbeille
3. Cliquer sur "Restaurer" pour le devis
4. Confirmer la restauration
5. Retourner dans la liste des devis

**Résultat attendu :**
- ✅ Dialogue de confirmation affiché
- ✅ Message de succès "Élément restauré avec succès"
- ✅ Le devis disparaît de la corbeille
- ✅ Le devis réapparaît dans la liste des devis
- ✅ Le badge de la corbeille se décrémente

#### Test 2.2 : Restaurer un Produit
**Objectif :** Vérifier qu'un produit peut être restauré

**Étapes :**
1. Supprimer un produit
2. Aller dans la corbeille
3. Cliquer sur "Restaurer" pour le produit
4. Confirmer la restauration
5. Retourner dans la liste des produits

**Résultat attendu :**
- ✅ Dialogue de confirmation affiché
- ✅ Message de succès "Élément restauré avec succès"
- ✅ Le produit disparaît de la corbeille
- ✅ Le produit réapparaît dans la liste des produits
- ✅ Le badge de la corbeille se décrémente

#### Test 2.3 : Annuler une Restauration
**Objectif :** Vérifier que l'annulation fonctionne

**Étapes :**
1. Aller dans la corbeille
2. Cliquer sur "Restaurer"
3. Cliquer sur "Annuler" dans le dialogue

**Résultat attendu :**
- ✅ Le dialogue se ferme
- ✅ L'élément reste dans la corbeille
- ✅ Aucun message affiché

### 3. Suppression Définitive

#### Test 3.1 : Supprimer Définitivement un Devis
**Objectif :** Vérifier qu'un devis peut être supprimé définitivement

**Étapes :**
1. Supprimer un devis
2. Aller dans la corbeille
3. Cliquer sur "Supprimer définitivement"
4. Confirmer la suppression
5. Vérifier dans la base de données

**Résultat attendu :**
- ✅ Dialogue d'avertissement affiché
- ✅ Message "Élément supprimé définitivement"
- ✅ Le devis disparaît de la corbeille
- ✅ Le devis n'existe plus dans la base de données
- ✅ Le badge de la corbeille se décrémente

#### Test 3.2 : Supprimer Définitivement un Produit
**Objectif :** Vérifier qu'un produit peut être supprimé définitivement

**Étapes :**
1. Supprimer un produit
2. Aller dans la corbeille
3. Cliquer sur "Supprimer définitivement"
4. Confirmer la suppression

**Résultat attendu :**
- ✅ Dialogue d'avertissement affiché
- ✅ Message "Élément supprimé définitivement"
- ✅ Le produit disparaît de la corbeille
- ✅ Le produit n'existe plus dans la base de données

#### Test 3.3 : Annuler une Suppression Définitive
**Objectif :** Vérifier que l'annulation fonctionne

**Étapes :**
1. Aller dans la corbeille
2. Cliquer sur "Supprimer définitivement"
3. Cliquer sur "Annuler" dans le dialogue

**Résultat attendu :**
- ✅ Le dialogue se ferme
- ✅ L'élément reste dans la corbeille
- ✅ Aucun message affiché

### 4. Vider la Corbeille

#### Test 4.1 : Vider une Corbeille avec Plusieurs Éléments
**Objectif :** Vérifier que tous les éléments sont supprimés

**Étapes :**
1. Supprimer 3 devis et 2 produits
2. Aller dans la corbeille
3. Cliquer sur ⋮ → "Vider la corbeille"
4. Confirmer l'action

**Résultat attendu :**
- ✅ Dialogue d'avertissement affiché
- ✅ Message "Corbeille vidée avec succès"
- ✅ La corbeille est vide
- ✅ Message "Corbeille vide" affiché
- ✅ Le badge disparaît

#### Test 4.2 : Annuler le Vidage de la Corbeille
**Objectif :** Vérifier que l'annulation fonctionne

**Étapes :**
1. Aller dans la corbeille avec des éléments
2. Cliquer sur ⋮ → "Vider la corbeille"
3. Cliquer sur "Annuler"

**Résultat attendu :**
- ✅ Le dialogue se ferme
- ✅ Les éléments restent dans la corbeille
- ✅ Aucun message affiché

### 5. Filtrage par Onglets

#### Test 5.1 : Onglet "Tout"
**Objectif :** Vérifier que tous les éléments sont affichés

**Étapes :**
1. Supprimer 2 devis et 2 produits
2. Aller dans la corbeille
3. Vérifier l'onglet "Tout"

**Résultat attendu :**
- ✅ 4 éléments affichés
- ✅ Devis et produits mélangés
- ✅ Triés par date de suppression (plus récent en premier)

#### Test 5.2 : Onglet "Devis"
**Objectif :** Vérifier que seuls les devis sont affichés

**Étapes :**
1. Supprimer 2 devis et 2 produits
2. Aller dans la corbeille
3. Cliquer sur l'onglet "Devis"

**Résultat attendu :**
- ✅ 2 éléments affichés
- ✅ Uniquement des devis
- ✅ Aucun produit visible

#### Test 5.3 : Onglet "Produits"
**Objectif :** Vérifier que seuls les produits sont affichés

**Étapes :**
1. Supprimer 2 devis et 2 produits
2. Aller dans la corbeille
3. Cliquer sur l'onglet "Produits"

**Résultat attendu :**
- ✅ 2 éléments affichés
- ✅ Uniquement des produits
- ✅ Aucun devis visible

## 🎨 Tests d'Interface Utilisateur

### 6. Mode Clair / Mode Sombre

#### Test 6.1 : Mode Clair
**Étapes :**
1. Activer le mode clair
2. Aller dans la corbeille

**Résultat attendu :**
- ✅ Fond blanc
- ✅ Texte sombre
- ✅ Cartes avec ombre légère
- ✅ Couleurs cohérentes avec le reste de l'app

#### Test 6.2 : Mode Sombre
**Étapes :**
1. Activer le mode sombre
2. Aller dans la corbeille

**Résultat attendu :**
- ✅ Fond sombre
- ✅ Texte clair
- ✅ Cartes avec fond gris foncé
- ✅ Couleurs cohérentes avec le reste de l'app

### 7. Multilingue

#### Test 7.1 : Français
**Étapes :**
1. Changer la langue en Français
2. Aller dans la corbeille

**Résultat attendu :**
- ✅ Tous les textes en français
- ✅ Dates au format français
- ✅ Messages de confirmation en français

#### Test 7.2 : Anglais
**Étapes :**
1. Changer la langue en Anglais
2. Aller dans la corbeille

**Résultat attendu :**
- ✅ Tous les textes en anglais
- ✅ Dates au format anglais
- ✅ Messages de confirmation en anglais

#### Test 7.3 : Espagnol
**Étapes :**
1. Changer la langue en Espagnol
2. Aller dans la corbeille

**Résultat attendu :**
- ✅ Tous les textes en espagnol
- ✅ Dates au format espagnol
- ✅ Messages de confirmation en espagnol

### 8. États de l'Interface

#### Test 8.1 : État Vide
**Étapes :**
1. Vider complètement la corbeille
2. Vérifier l'affichage

**Résultat attendu :**
- ✅ Icône de corbeille vide
- ✅ Message "Corbeille vide"
- ✅ Sous-titre "Les éléments supprimés apparaîtront ici"
- ✅ Pas de menu ⋮ visible

#### Test 8.2 : État de Chargement
**Étapes :**
1. Ouvrir la corbeille
2. Observer pendant le chargement

**Résultat attendu :**
- ✅ Indicateur de chargement affiché
- ✅ Pas de contenu visible pendant le chargement

#### Test 8.3 : État d'Erreur
**Étapes :**
1. Simuler une erreur de base de données
2. Ouvrir la corbeille

**Résultat attendu :**
- ✅ Icône d'erreur affichée
- ✅ Message d'erreur affiché
- ✅ Bouton "Réessayer" visible
- ✅ Clic sur "Réessayer" recharge les données

### 9. Interactions

#### Test 9.1 : Pull-to-Refresh
**Étapes :**
1. Aller dans la corbeille
2. Tirer vers le bas pour actualiser

**Résultat attendu :**
- ✅ Animation de rafraîchissement
- ✅ Données rechargées
- ✅ Liste mise à jour

#### Test 9.2 : Feedback Haptique
**Étapes :**
1. Cliquer sur différents boutons
2. Vérifier les vibrations

**Résultat attendu :**
- ✅ Vibration légère sur les clics normaux
- ✅ Vibration moyenne sur les actions importantes
- ✅ Cohérent avec le reste de l'app

#### Test 9.3 : Navigation
**Étapes :**
1. Aller dans la corbeille
2. Cliquer sur le bouton retour

**Résultat attendu :**
- ✅ Retour aux paramètres
- ✅ Pas de crash
- ✅ Navigation fluide

## 🔄 Tests de Flux Complets

### 10. Scénario Complet : Suppression Accidentelle

**Étapes :**
1. Créer un devis important
2. Supprimer le devis par erreur
3. Réaliser l'erreur
4. Aller dans la corbeille
5. Restaurer le devis
6. Vérifier que le devis est intact

**Résultat attendu :**
- ✅ Le devis est restauré avec toutes ses données
- ✅ Aucune perte d'information
- ✅ Le devis est utilisable immédiatement

### 11. Scénario Complet : Nettoyage de Printemps

**Étapes :**
1. Supprimer 5 vieux devis
2. Supprimer 3 vieux produits
3. Aller dans la corbeille
4. Vérifier les éléments
5. Vider la corbeille
6. Confirmer que tout est supprimé

**Résultat attendu :**
- ✅ Tous les éléments sont supprimés définitivement
- ✅ La corbeille est vide
- ✅ L'espace de stockage est libéré

## 📊 Résumé des Tests

| Catégorie | Nombre de Tests | Priorité |
|-----------|----------------|----------|
| Fonctionnels | 15 | Haute |
| Interface | 9 | Moyenne |
| Flux Complets | 2 | Haute |
| **Total** | **26** | - |

## ✅ Checklist de Validation

Avant de considérer la fonctionnalité comme terminée, vérifier :

- [ ] Tous les tests fonctionnels passent
- [ ] Tous les tests d'interface passent
- [ ] Les deux scénarios complets fonctionnent
- [ ] Aucune erreur de compilation
- [ ] Aucun warning critique
- [ ] Performance acceptable (< 1s pour charger la corbeille)
- [ ] Pas de fuite mémoire
- [ ] Fonctionne hors ligne
- [ ] Compatible avec tous les appareils testés

## 🐛 Rapport de Bugs

Si vous trouvez un bug, documentez :
1. **Titre** : Description courte du bug
2. **Étapes** : Comment reproduire le bug
3. **Résultat attendu** : Ce qui devrait se passer
4. **Résultat obtenu** : Ce qui se passe réellement
5. **Captures d'écran** : Si applicable
6. **Appareil** : Modèle et version Android/iOS
7. **Version de l'app** : Version de SenDevis

---

**Date de création :** 5 mars 2026  
**Statut :** ✅ Prêt pour les tests
