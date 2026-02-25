# Guide de Migration vers les Composants Mobile-First

## 🎯 Objectif

Remplacer progressivement les composants standards par les composants mobile-optimisés.

---

## 📝 Migrations Recommandées

### 1. Remplacer les ElevatedButton par MobileButton

**Avant :**
```dart
ElevatedButton(
  onPressed: () => save(),
  child: Text('Enregistrer'),
)
```

**Après :**
```dart
MobileButton(
  text: 'Enregistrer',
  onPressed: () => save(),
)
```

**Avec icône :**
```dart
MobileButton(
  text: 'Enregistrer',
  icon: Icons.save,
  onPressed: () => save(),
)
```

**Avec loading :**
```dart
MobileButton(
  text: 'Enregistrer',
  isLoading: _isLoading,
  onPressed: () => save(),
)
```

---

### 2. Remplacer les TextFormField par MobileTextField

**Avant :**
```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Nom',
    hintText: 'Entrez votre nom',
  ),
)
```

**Après :**
```dart
MobileTextField(
  controller: _nameController,
  label: 'Nom',
  hint: 'Entrez votre nom',
)
```

**Avec icône :**
```dart
MobileTextField(
  controller: _emailController,
  label: 'Email',
  hint: 'votre@email.com',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
)
```

---

### 3. Ajouter du Feedback Haptique

**Sur les boutons :**
```dart
onTap: () {
  MobileUtils.lightHaptic();
  // Votre action
}
```

**Sur les sélections :**
```dart
onTap: () {
  MobileUtils.selectionHaptic();
  setState(() => _selected = item);
}
```

**Sur les actions importantes :**
```dart
onPressed: () {
  MobileUtils.mediumHaptic();
  _deleteItem();
}
```

---

### 4. Utiliser les Constantes Mobile

**Spacing :**
```dart
// Avant
padding: EdgeInsets.all(16)

// Après
padding: EdgeInsets.all(MobileConstants.spacingM)
```

**Border Radius :**
```dart
// Avant
borderRadius: BorderRadius.circular(12)

// Après
borderRadius: BorderRadius.circular(MobileConstants.radiusM)
```

**Font Size :**
```dart
// Avant
fontSize: 15

// Après
fontSize: MobileConstants.fontSizeM
```

---

### 5. Remplacer les SnackBar

**Avant :**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Enregistré')),
)
```

**Après :**
```dart
MobileUtils.showMobileSnackBar(
  context,
  message: 'Enregistré avec succès',
  icon: Icons.check_circle,
  backgroundColor: Colors.green,
)
```

---

### 6. Remplacer les showModalBottomSheet

**Avant :**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => YourWidget(),
)
```

**Après :**
```dart
MobileUtils.showMobileBottomSheet(
  context: context,
  child: YourWidget(),
)
```

---

## 🔄 Plan de Migration par Écran

### Priorité 1 - Écrans Critiques

1. **LoginScreen** ✅
   - [ ] Remplacer TextFormField → MobileTextField
   - [ ] Remplacer ElevatedButton → MobileButton
   - [ ] Ajouter feedback haptique

2. **QuoteFormScreen** ✅
   - [ ] Remplacer tous les champs
   - [ ] Utiliser MobileConstants pour spacing
   - [ ] Ajouter feedback haptique sur boutons

3. **ClientFormScreen** ✅
   - [ ] Remplacer TextFormField → MobileTextField
   - [ ] Utiliser MobileButton
   - [ ] Feedback haptique

### Priorité 2 - Écrans Secondaires

4. **ProductFormScreen**
5. **SettingsScreen**
6. **CompanySettingsScreen**

### Priorité 3 - Écrans de Liste

7. **ClientsListScreen**
8. **ProductsListScreen**
9. **QuotesListScreen**

---

## 📋 Checklist par Écran

Pour chaque écran, vérifier :

- [ ] Tous les boutons utilisent MobileButton
- [ ] Tous les champs utilisent MobileTextField
- [ ] Feedback haptique sur interactions
- [ ] Spacing avec MobileConstants
- [ ] Border radius avec MobileConstants
- [ ] Font sizes avec MobileConstants
- [ ] SnackBar avec MobileUtils
- [ ] Bottom sheets avec MobileUtils

---

## 🎨 Exemple Complet de Migration

### Avant (Écran Login)

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'votre@email.com',
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => login(),
              child: Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Après (Mobile-Optimized)

```dart
import 'package:devis/core/constants/mobile_constants.dart';
import 'package:devis/core/utils/mobile_utils.dart';
import 'package:devis/widgets/mobile_text_field.dart';
import 'package:devis/widgets/mobile_button.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(MobileConstants.spacingM),
        child: Column(
          children: [
            MobileTextField(
              label: 'Email',
              hint: 'votre@email.com',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: MobileConstants.spacingM),
            MobileTextField(
              label: 'Mot de passe',
              hint: 'Entrez votre mot de passe',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            SizedBox(height: MobileConstants.spacingL),
            MobileButton(
              text: 'Se connecter',
              icon: Icons.login,
              onPressed: () {
                MobileUtils.lightHaptic();
                login();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ✅ Avantages de la Migration

1. **Cohérence** : Tous les écrans ont le même look & feel
2. **Maintenabilité** : Changements centralisés dans les composants
3. **UX** : Feedback haptique et animations fluides
4. **Performance** : Composants optimisés
5. **Accessibilité** : Zones tactiles optimales

---

## 🚀 Commencer la Migration

1. Importer les nouveaux composants dans un écran
2. Remplacer progressivement les composants
3. Tester le feedback haptique
4. Vérifier les zones tactiles
5. Passer à l'écran suivant

**Temps estimé par écran : 15-30 minutes**

---

## 📞 Support

Si tu as besoin d'aide pour migrer un écran spécifique, demande-moi !
