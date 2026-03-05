import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/model_extensions.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/utils/senegal_phone_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  static const String _keyUserId = 'user_id';
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyLastRoute = 'last_route';
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _lastRoute = '/home';

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _currentUser?.id;
  String get lastRoute => _lastRoute;

  // Sauvegarder la session
  Future<void> _saveSession(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, userId);
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyLastRoute, _lastRoute);
      debugPrint('AUTH: Session saved for user $userId with route $_lastRoute');
    } catch (e) {
      debugPrint('AUTH: Error saving session: $e');
    }
  }

  // Sauvegarder la dernière route visitée
  Future<void> saveLastRoute(String route) async {
    try {
      _lastRoute = route;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRoute, route);
      debugPrint('AUTH: Last route saved: $route');
    } catch (e) {
      debugPrint('AUTH: Error saving last route: $e');
    }
  }

  // Charger la session
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt(_keyUserId);
      final isAuth = prefs.getBool(_keyIsAuthenticated) ?? false;
      final savedRoute = prefs.getString(_keyLastRoute) ?? '/home';

      if (savedUserId != null && isAuth) {
        debugPrint('AUTH: Loading session for user $savedUserId');
        final user = await _db.getUserById(savedUserId);
        
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
          _lastRoute = savedRoute;
          notifyListeners();
          debugPrint('AUTH: Session restored successfully with route $savedRoute');
          return true;
        } else {
          debugPrint('AUTH: User not found in database, clearing session');
          await _clearSession();
        }
      }
    } catch (e) {
      debugPrint('AUTH: Error loading session: $e');
    }
    
    return false;
  }

  // Effacer la session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyIsAuthenticated);
      await prefs.remove(_keyLastRoute);
      _lastRoute = '/home';
      debugPrint('AUTH: Session cleared');
    } catch (e) {
      debugPrint('AUTH: Error clearing session: $e');
    }
  }

  // Hash du mot de passe
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  String get displayName {
    if (_currentUser == null) return 'Utilisateur';

    final phone = _currentUser!.phone;

    // Exemple : +221771234567 → 77****567
    if (phone.length >= 9) {
      return '${phone.substring(0, 2)}****${phone.substring(phone.length - 3)}';
    }

    return 'Utilisateur';
  }


  // Inscription
  Future<bool> register({
    required String phone,
    required String password,
    String? companyName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedPhone = SenegalPhoneFormatter.normalize(phone);
      final hashedPassword = _hashPassword(password);
      
      debugPrint('AUTH_REG: Original Phone: $phone');
      debugPrint('AUTH_REG: Normalized Phone: $normalizedPhone');
      debugPrint('AUTH_REG: Hashed Password: $hashedPassword');

      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _db.getUserByPhone(normalizedPhone);

      if (existingUser != null) {
        _errorMessage = 'Ce numéro de téléphone est déjà utilisé';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Créer le nouvel utilisateur
      final userCompanion = CompanionHelpers.createUser(
        phone: normalizedPhone,
        password: _hashPassword(password),
      );

      final userId = await _db.insertUser(userCompanion);
      
      _currentUser = await _db.getUserById(userId);
      _isAuthenticated = true;
      _isLoading = false;
      
      // ✅ Créer une entreprise de base avec les informations fournies
      if (companyName != null && companyName.isNotEmpty) {
        try {
          debugPrint('AUTH_REG: Creating company with name: $companyName');
          final companyCompanion = CompanionHelpers.createCompany(
            userId: userId,
            name: companyName,
            phone: normalizedPhone,
            vatRate: 18.0, // TVA par défaut pour l'Afrique
          );
          final companyId = await _db.insertCompany(companyCompanion);
          debugPrint('AUTH_REG: Entreprise créée avec succès, ID: $companyId');
        } catch (e) {
          debugPrint('AUTH_REG: Erreur création entreprise: $e');
          // Ne pas bloquer l'inscription si la création de l'entreprise échoue
        }
      } else {
        debugPrint('AUTH_REG: No company name provided, skipping company creation');
      }
      
      // Sauvegarder la session
      await _saveSession(userId);
      
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'inscription: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedPhone = SenegalPhoneFormatter.normalize(phone);
      final hashedPassword = _hashPassword(password);

      debugPrint('AUTH_LOGIN: Original Phone: $phone');
      debugPrint('AUTH_LOGIN: Normalized Phone: $normalizedPhone');
      debugPrint('AUTH_LOGIN: Hashed Password: $hashedPassword');

      var user = await _db.getUserByPhone(normalizedPhone);
      
      // Fallback : Si non trouvé, on cherche en mode "flou" (pour réparer les anciens comptes)
      if (user == null) {
        debugPrint('AUTH_LOGIN: Direct lookup failed, searching fuzzy...');
        final allUsers = await _db.getAllUsers();
        for (var u in allUsers) {
          if (SenegalPhoneFormatter.normalize(u.phone) == normalizedPhone) {
            debugPrint('AUTH_LOGIN: Found match by normalizing DB value: ${u.phone} -> $normalizedPhone');
            user = u;
            
            // Réparation automatique en base
            try {
              final healedUser = u.copyWith(phone: normalizedPhone);
              await _db.updateUser(healedUser.toCompanion(true));
              debugPrint('AUTH_LOGIN: Database record HEALED for $normalizedPhone');
            } catch (e) {
              debugPrint('AUTH_LOGIN: Failed to heal record: $e');
            }
            break;
          }
        }
      }

      if (user == null) {
        debugPrint('AUTH_LOGIN: User NOT found in DB even after fuzzy search for $normalizedPhone');
        
        // Debug: Lister tous les utilisateurs pour voir ce qui est en base
        final allUsers = await _db.getAllUsers();
        debugPrint('AUTH_LOGIN: Total users in DB: ${allUsers.length}');
        for (var u in allUsers) {
          debugPrint('AUTH_LOGIN: Existing User in DB: ${u.phone}');
        }

        _errorMessage = 'Aucun compte trouvé avec ce numéro';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (user.password != hashedPassword) {
        debugPrint('AUTH_LOGIN: Password mismatch');
        debugPrint('AUTH_LOGIN: Expected: ${user.password}');
        debugPrint('AUTH_LOGIN: Got: $hashedPassword');
        _errorMessage = 'Mot de passe incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      
      // Sauvegarder la session
      await _saveSession(user.id!);
      
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la connexion: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _clearSession();
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> checkAuth() async {
    // Charger la session sauvegardée
    return await loadSession();
  }

  // Mettre à jour le mot de passe
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    try {
      // Vérifier l'ancien mot de passe
      if (_currentUser!.password != _hashPassword(currentPassword)) {
        _errorMessage = 'Mot de passe actuel incorrect';
        notifyListeners();
        return false;
      }

      // Mettre à jour le mot de passe
      final updatedUser = _currentUser!.copyWith(
        password: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      await _db.updateUser(updatedUser.toCompanion(true));
      _currentUser = updatedUser;
      
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    // Ne pas fermer la base de données car c'est un singleton partagé
    super.dispose();
  }
}