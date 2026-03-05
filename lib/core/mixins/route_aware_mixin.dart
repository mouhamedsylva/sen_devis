import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Mixin pour sauvegarder automatiquement la route actuelle
/// À utiliser sur les écrans principaux de navigation
mixin RouteAwareMixin<T extends StatefulWidget> on State<T> {
  String get routeName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveCurrentRoute();
    });
  }

  void _saveCurrentRoute() {
    try {
      context.read<AuthProvider>().saveLastRoute(routeName);
    } catch (e) {
      debugPrint('RouteAwareMixin: Error saving route: $e');
    }
  }
}
