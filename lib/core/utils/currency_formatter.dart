import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  /// Formate un montant en FCFA
  static String format(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final formattedAmount = formatter.format(amount);
    
    if (showSymbol) {
      return '$formattedAmount ${AppConstants.defaultCurrency}';
    }
    return formattedAmount;
  }
  
  /// Formate un montant avec décimales
  static String formatWithDecimals(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final formattedAmount = formatter.format(amount);
    
    if (showSymbol) {
      return '$formattedAmount ${AppConstants.defaultCurrency}';
    }
    return formattedAmount;
  }
  
  /// Parse une chaîne en double
  static double parse(String value) {
    try {
      // Enlever les espaces et le symbole FCFA
      String cleanValue = value
          .replaceAll(AppConstants.defaultCurrency, '')
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      
      return double.parse(cleanValue);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Calcule la TVA
  static double calculateVAT(double amountHT, double vatRate) {
    return amountHT * (vatRate / 100);
  }
  
  /// Calcule le montant TTC
  static double calculateTTC(double amountHT, double vatRate) {
    return amountHT + calculateVAT(amountHT, vatRate);
  }
  
  /// Calcule le montant HT à partir du TTC
  static double calculateHT(double amountTTC, double vatRate) {
    return amountTTC / (1 + (vatRate / 100));
  }
  
  /// Arrondit un montant à 2 décimales
  static double round(double value) {
    return (value * 100).round() / 100;
  }
}