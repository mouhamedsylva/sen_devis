# Système de Traduction

## Utilisation

### Dans les widgets

```dart
import '../../core/localization/localization_extension.dart';

// Utiliser context.tr() pour traduire
Text(context.tr('welcome'))

// Ou utiliser context.loc pour accéder à AppLocalizations
Text(context.loc.translate('welcome'))
```

### Ajouter de nouvelles traductions

Modifier le fichier `translations.dart` et ajouter les clés dans les 3 langues (fr, en, es):

```dart
const Map<String, Map<String, String>> translations = {
  'fr': {
    'my_key': 'Mon texte en français',
  },
  'en': {
    'my_key': 'My text in English',
  },
  'es': {
    'my_key': 'Mi texto en español',
  },
};
```

### Langues supportées

- Français (fr_FR) - Par défaut
- Anglais (en_US)
- Espagnol (es_ES)

### Changer de langue

L'utilisateur peut changer la langue depuis:
Paramètres → Langue → Sélectionner la langue

Le choix est persisté automatiquement via SharedPreferences.
