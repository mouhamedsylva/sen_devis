import '../constants/app_constants.dart';
import '../constants/strings.dart';

class Validators {
  /// Valide qu'un champ n'est pas vide
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? '$fieldName ${AppStrings.fieldRequired.toLowerCase()}'
          : AppStrings.fieldRequired;
    }
    return null;
  }
  
  /// Valide un numéro de téléphone
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    final phoneRegex = RegExp(AppConstants.phoneRegex);
    if (!phoneRegex.hasMatch(value.trim())) {
      return AppStrings.invalidPhone;
    }
    
    return null;
  }
  
  /// Valide un montant
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount < 0) {
      return AppStrings.invalidAmount;
    }
    
    return null;
  }
  
  /// Valide un mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return AppStrings.passwordTooShort;
    }
    
    return null;
  }
  
  /// Valide la confirmation de mot de passe
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value != password) {
      return AppStrings.passwordsNotMatch;
    }
    
    return null;
  }
  
  /// Valide une longueur maximale
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? "Ce champ"} ne doit pas dépasser $max caractères';
    }
    return null;
  }
  
  /// Valide une longueur minimale
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value != null && value.isNotEmpty && value.length < min) {
      return '${fieldName ?? "Ce champ"} doit contenir au moins $min caractères';
    }
    return null;
  }
  
  /// Valide un nombre positif
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'Le nombre doit être positif';
    }
    
    return null;
  }
  
  /// Valide un taux de TVA (0-100)
  static String? vatRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    final rate = double.tryParse(value.replaceAll(',', '.'));
    if (rate == null || rate < 0 || rate > 100) {
      return 'Le taux doit être entre 0 et 100';
    }
    
    return null;
  }
}