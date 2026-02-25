import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/models/model_extensions.dart';
import 'package:drift/drift.dart' as drift;

class CompanyProvider with ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  
  Company? _company;
  bool _isLoading = false;
  String? _errorMessage;

  Company? get company => _company;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCompany => _company != null;

  // Charger les informations de l'entreprise
  Future<void> loadCompany(int userId) async {
    try {
      _company = await _db.getCompanyByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer ou mettre à jour l'entreprise
  Future<bool> saveCompany({
    required int userId,
    required String name,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? postalCode,
    String? registrationNumber,
    String? taxId,
    String? logoPath,
    String? signaturePath,
    double? vatRate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_company == null) {
        // Créer une nouvelle entreprise
        final companyCompanion = CompanionHelpers.createCompany(
          userId: userId,
          name: name,
          email: drift.Value(email),
          phone: drift.Value(phone),
          website: drift.Value(website),
          address: drift.Value(address),
          city: drift.Value(city),
          postalCode: drift.Value(postalCode),
          registrationNumber: drift.Value(registrationNumber),
          taxId: drift.Value(taxId),
          logoPath: drift.Value(logoPath),
          signaturePath: drift.Value(signaturePath),
          vatRate: vatRate ?? 18.0,
        );

        final id = await _db.insertCompany(companyCompanion);
        _company = await _db.getCompanyById(id);
      } else {
        // Mettre à jour l'entreprise existante
        final updatedCompany = _company!.copyWith(
          name: name,
          email: drift.Value(email),
          phone: drift.Value(phone),
          website: drift.Value(website),
          address: drift.Value(address),
          city: drift.Value(city),
          postalCode: drift.Value(postalCode),
          registrationNumber: drift.Value(registrationNumber),
          taxId: drift.Value(taxId),
          logoPath: drift.Value(logoPath),
          signaturePath: drift.Value(signaturePath),
          vatRate: vatRate ?? _company!.vatRate,
          updatedAt: DateTime.now(),
        );

        await _db.updateCompany(updatedCompany.toCompanion(true));
        _company = updatedCompany;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour le logo
  Future<bool> updateLogo(String logoPath) async {
    if (_company == null) return false;

    try {
      final updatedCompany = _company!.copyWith(
        logoPath: drift.Value(logoPath),
        updatedAt: DateTime.now(),
      );

      await _db.updateCompany(updatedCompany.toCompanion(true));
      _company = updatedCompany;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du logo';
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour la signature
  Future<bool> updateSignature(String signaturePath) async {
    if (_company == null) return false;

    try {
      final updatedCompany = _company!.copyWith(
        signaturePath: drift.Value(signaturePath),
        updatedAt: DateTime.now(),
      );

      await _db.updateCompany(updatedCompany.toCompanion(true));
      _company = updatedCompany;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la signature';
      notifyListeners();
      return false;
    }
  }

  // Mettre à jour le taux de TVA
  Future<bool> updateVatRate(double vatRate) async {
    if (_company == null) return false;

    try {
      final updatedCompany = _company!.copyWith(
        vatRate: vatRate,
        updatedAt: DateTime.now(),
      );

      await _db.updateCompany(updatedCompany.toCompanion(true));
      _company = updatedCompany;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du taux de TVA';
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
