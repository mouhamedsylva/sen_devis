import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

/// Bouton qui s'adapte automatiquement au mode offline
/// Peut être désactivé ou afficher un message si hors ligne
class OfflineAwareButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool requiresInternet;
  final String offlineMessage;
  final ButtonStyle? style;

  const OfflineAwareButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.requiresInternet = false,
    this.offlineMessage = 'Cette action nécessite une connexion internet',
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!requiresInternet) {
      // Bouton normal si internet pas requis
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        final isDisabled = connectivity.isOffline;

        return ElevatedButton(
          onPressed: isDisabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(child: Text(offlineMessage)),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade700,
                      action: SnackBarAction(
                        label: 'Réessayer',
                        textColor: Colors.white,
                        onPressed: () {
                          connectivity.checkConnectivity();
                        },
                      ),
                    ),
                  );
                }
              : onPressed,
          style: style?.copyWith(
            backgroundColor: isDisabled
                ? MaterialStateProperty.all(Colors.grey)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDisabled) ...[
                const Icon(Icons.cloud_off, size: 18),
                const SizedBox(width: 8),
              ],
              child,
            ],
          ),
        );
      },
    );
  }
}

/// Widget qui affiche son contenu uniquement si online
class OnlineOnly extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;

  const OnlineOnly({
    Key? key,
    required this.child,
    this.offlineWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) {
          return child;
        }

        return offlineWidget ??
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fonctionnalité disponible uniquement en ligne',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
      },
    );
  }
}

/// Widget qui affiche son contenu uniquement si offline
class OfflineOnly extends StatelessWidget {
  final Widget child;

  const OfflineOnly({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOffline) {
          return child;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
