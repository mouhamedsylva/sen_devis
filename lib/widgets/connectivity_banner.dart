import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

/// Banner qui affiche l'état de connectivité en haut de l'écran
class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  final bool showWhenOnline;

  const ConnectivityBanner({
    Key? key,
    required this.child,
    this.showWhenOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        // Ne rien afficher si online et showWhenOnline = false
        if (connectivity.isOnline && !showWhenOnline) {
          return child;
        }

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: connectivity.isOnline && !showWhenOnline ? 0 : 40,
              child: _buildBanner(context, connectivity),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, ConnectivityProvider connectivity) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (connectivity.isChecking) {
      backgroundColor = Colors.blue.shade700;
      textColor = Colors.white;
      icon = Icons.refresh;
    } else if (connectivity.isOffline) {
      backgroundColor = Colors.red.shade700;
      textColor = Colors.white;
      icon = Icons.cloud_off;
    } else {
      backgroundColor = Colors.green.shade700;
      textColor = Colors.white;
      icon = Icons.cloud_done;
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              connectivity.statusMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (connectivity.isOffline) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => connectivity.checkConnectivity(),
              child: Icon(
                Icons.refresh,
                color: textColor,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicateur de connectivité compact (pour AppBar ou autres)
class ConnectivityIndicator extends StatelessWidget {
  final bool showLabel;

  const ConnectivityIndicator({
    Key? key,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                const Text(
                  'Hors ligne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Snackbar pour notifier les changements de connectivité
class ConnectivitySnackbar {
  static void show(BuildContext context, bool isOnline) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnline
                  ? 'Connexion rétablie'
                  : 'Mode hors ligne - Les données sont sauvegardées localement',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      action: isOnline
          ? null
          : SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
