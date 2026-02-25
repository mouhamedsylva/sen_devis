# Guide de Traduction - SenDevis

## ✅ Ce qui est déjà traduit

- `login_screen.dart` - Écran de connexion
- `settings_screen.dart` - Écran des paramètres  
- `language_selection_screen.dart` - Sélection de langue

## 🔧 Comment traduire un nouvel écran

### Étape 1: Ajouter l'import

```dart
import '../../core/localization/localization_extension.dart';
```

### Étape 2: Remplacer les textes en dur

**Avant:**
```dart
Text('Bienvenue')
```

**Après:**
```dart
Text(context.tr('welcome'))
```

### Étape 3: Ajouter les traductions manquantes

Dans `lib/core/localization/translations.dart`, ajouter les clés pour les 3 langues:

```dart
const Map<String, Map<String, String>> translations = {
  'fr': {
    'ma_nouvelle_cle': 'Mon texte en français',
  },
  'en': {
    'ma_nouvelle_cle': 'My text in English',
  },
  'es': {
    'ma_nouvelle_cle': 'Mi texto en español',
  },
};
```

### Étape 4: Supprimer les `const` devant les Text

**Avant:**
```dart
const Text('Bienvenue')
```

**Après:**
```dart
Text(context.tr('welcome'))
```

⚠️ **Important**: Ne pas utiliser `const` avec `context.tr()` car cela empêche la reconstruction lors du changement de langue.

## 📝 Traductions déjà disponibles

Voici les clés de traduction déjà définies que vous pouvez utiliser:

### Application
- `app_name` - SenDevis
- `app_subtitle` - Gestion de devis / Quote Management / Gestión de Presupuestos

### Authentification
- `welcome` - Bienvenue / Welcome / Bienvenido
- `login_subtitle` - Connectez-vous pour... / Sign in to... / Inicie sesión para...
- `phone_number` - Numéro de téléphone / Phone Number / Número de Teléfono
- `password` - Mot de passe / Password / Contraseña
- `forgot_password` - Mot de passe oublié ? / Forgot password? / ¿Olvidó su contraseña?
- `login` - Se connecter / Sign In / Iniciar Sesión
- `no_account` - Vous n'avez pas de compte ? / Don't have an account? / ¿No tiene una cuenta?
- `sign_up` - S'inscrire / Sign Up / Registrarse
- `enter_password` - Entrez votre mot de passe / Enter your password / Ingrese su contraseña
- `invalid_phone` - Numéro de téléphone invalide / Invalid phone number / Número de teléfono inválido

### Navigation
- `dashboard` - Tableau de bord / Dashboard / Panel
- `products` - Produits / Products / Productos
- `quotes` - Devis / Quotes / Presupuestos
- `clients` - Clients / Clients / Clientes
- `settings` - Paramètres / Settings / Configuración

### Accueil
- `quote_management` - Gestion de devis / Quote Management / Gestión de Presupuestos
- `total_quotes` - Total Devis / Total Quotes / Total Presupuestos
- `pending` - En attente / Pending / Pendientes
- `accepted` - Acceptés / Accepted / Aceptados
- `revenue` - Revenus / Revenue / Ingresos
- `quick_actions` - Actions rapides / Quick Actions / Acciones Rápidas
- `add_client` - Ajouter Client / Add Client / Agregar Cliente
- `add_product` - Ajouter Produit / Add Product / Agregar Producto
- `recent_activity` - Activité récente / Recent Activity / Actividad Reciente
- `see_all` - Voir tout / See All / Ver Todo
- `no_quotes` - Aucun devis / No quotes / Sin presupuestos
- `create_first_quote` - Créez votre premier devis / Create your first quote / Cree su primer presupuesto

### Clients
- `search_client` - Rechercher une entreprise... / Search company... / Buscar empresa...
- `total_clients` - TOTAL CLIENTS / TOTAL CLIENTS / TOTAL CLIENTES
- `no_clients` - Aucun client / No clients / Sin clientes
- `add_first_client` - Ajoutez votre premier client / Add your first client / Agregue su primer cliente
- `no_client_found` - Aucun client trouvé / No client found / Cliente no encontrado
- `try_another_search` - Essayez une autre recherche / Try another search / Intente otra búsqueda
- `main_contact` - Contact principal / Main contact / Contacto principal
- `view` - Voir / View / Ver
- `edit` - Modifier / Edit / Editar
- `delete` - Supprimer / Delete / Eliminar
- `import_contacts` - Importer des contacts / Import contacts / Importar contactos

### Devis
- `generate_quote` - Générer un devis / Generate Quote / Generar Presupuesto
- `no_quotes_yet` - Aucun devis généré pour l'instant / No quotes generated yet / Aún no hay presupuestos generados

### Paramètres
- `company_management` - GESTION D'ENTREPRISE / COMPANY MANAGEMENT / GESTIÓN DE EMPRESA
- `company_profile` - Profil d'entreprise / Company Profile / Perfil de Empresa
- `branding_logos` - Image de marque & Logos / Branding & Logos / Marca y Logos
- `preferences` - PRÉFÉRENCES / PREFERENCES / PREFERENCIAS
- `language` - Langue / Language / Idioma
- `currency` - Devise / Currency / Moneda
- `dark_mode` - Mode sombre / Dark Mode / Modo Oscuro
- `security` - SÉCURITÉ / SECURITY / SEGURIDAD
- `change_password` - Changer mot de passe / Change Password / Cambiar Contraseña
- `logout` - Se déconnecter / Sign Out / Cerrar Sesión
- `manage_account` - Gérer compte & profil / Manage account & profile / Gestionar cuenta y perfil
- `my_company` - Mon Entreprise / My Company / Mi Empresa

### Langues
- `french` - Français / French / Francés
- `english` - Anglais / English / Inglés
- `spanish` - Espagnol / Spanish / Español

### Commun
- `cancel` - Annuler / Cancel / Cancelar
- `save` - Enregistrer / Save / Guardar
- `confirm` - Confirmer / Confirm / Confirmar
- `yes` - Oui / Yes / Sí
- `no` - Non / No / No
- `ok` - OK / OK / OK
- `error` - Erreur / Error / Error
- `success` - Succès / Success / Éxito
- `loading` - Chargement... / Loading... / Cargando...

### Dialogues
- `confirm_logout` - Voulez-vous vraiment vous déconnecter ? / Do you really want to sign out? / ¿Realmente desea cerrar sesión?
- `confirm_delete` - Êtes-vous sûr de vouloir supprimer cet élément ? / Are you sure you want to delete this item? / ¿Está seguro de que desea eliminar este elemento?
- `delete_success` - Suppression réussie / Successfully deleted / Eliminado exitosamente
- `error_occurred` - Une erreur s'est produite / An error occurred / Ocurrió un error

## 🚀 Test du changement de langue

1. Lancer l'application
2. Aller dans Paramètres → Langue
3. Sélectionner Anglais ou Espagnol
4. Vérifier que TOUS les textes changent

## ⚠️ Problème connu

Si certains écrans ne se traduisent pas:
1. Vérifier que l'import `localization_extension.dart` est présent
2. Vérifier qu'aucun `const` n'est utilisé avec `context.tr()`
3. Redémarrer l'application (hot reload peut ne pas suffire)

## 📚 Fichiers du système de traduction

- `lib/core/localization/app_localizations.dart` - Classe principale
- `lib/core/localization/translations.dart` - Toutes les traductions
- `lib/core/localization/localization_extension.dart` - Extension pour `context.tr()`
- `lib/providers/locale_provider.dart` - Gestion de la langue sélectionnée
