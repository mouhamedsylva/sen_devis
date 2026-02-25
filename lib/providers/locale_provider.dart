import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('fr', 'FR');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'fr';
      final countryCode = prefs.getString('country_code') ?? 'FR';
      _locale = Locale(languageCode, countryCode);
      notifyListeners();
    } catch (e) {
      // En cas d'erreur (par exemple sur web sans plugin), utiliser la locale par défaut
      _locale = const Locale('fr', 'FR');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('country_code', locale.countryCode ?? '');
  }

  void clearLocale() {
    _locale = const Locale('fr', 'FR');
    notifyListeners();
  }
}
