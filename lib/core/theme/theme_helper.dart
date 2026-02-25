import 'package:flutter/material.dart';

/// Helper centralisé pour accéder aux couleurs du thème actuel.
/// Utiliser `AppThemeHelper.of(context)` dans les widgets.
class AppThemeHelper {
  final BuildContext context;
  late final ThemeData _theme;
  late final bool isDark;

  AppThemeHelper._(this.context) {
    _theme = Theme.of(context);
    isDark = _theme.brightness == Brightness.dark;
  }

  factory AppThemeHelper.of(BuildContext context) => AppThemeHelper._(context);

  // Couleurs de fond
  Color get scaffoldBg => _theme.scaffoldBackgroundColor;
  Color get cardBg => isDark ? const Color(0xFF2C2C2C) : Colors.white;
  Color get surfaceBg => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);
  Color get inputBg => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);

  // Couleurs de texte
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A3B5D);
  Color get textSecondary => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get textBody => isDark ? Colors.white : const Color(0xFF1A1A1A);

  // Couleur primaire
  Color get primary => _theme.primaryColor;

  // Bordures et dividers
  Color get border => isDark ? Colors.grey.shade800 : Colors.grey.shade200;
  Color get divider => isDark ? Colors.grey.shade800 : Colors.grey.shade200;

  // Chevron / icônes secondaires
  Color get chevron => isDark ? Colors.grey.shade600 : Colors.grey.shade400;
}
