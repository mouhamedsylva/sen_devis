import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilitaires pour optimiser l'expérience mobile
class MobileUtils {
  /// Vibration haptique légère pour feedback tactile
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }
  
  /// Vibration haptique moyenne
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }
  
  /// Vibration haptique forte
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }
  
  /// Vibration pour sélection
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }
  
  /// Cacher le clavier
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  /// Afficher le clavier
  static void showKeyboard(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
  
  /// Vérifier si on est en mode portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Obtenir la hauteur disponible (sans status bar, app bar, etc.)
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - 
           mediaQuery.padding.top - 
           mediaQuery.padding.bottom;
  }
  
  /// Obtenir la largeur de l'écran
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Vérifier si c'est un petit écran (< 360dp)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Scroll vers le haut d'une liste
  static void scrollToTop(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  /// Afficher un snackbar optimisé mobile
  static void showMobileSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
  
  /// Afficher un bottom sheet optimisé mobile
  static Future<T?> showMobileBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pour indiquer qu'on peut glisser
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
