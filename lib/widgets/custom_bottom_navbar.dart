import 'package:flutter/material.dart';
import '../core/localization/localization_extension.dart';
import '../core/constants/mobile_constants.dart';
import '../core/utils/mobile_utils.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72, // Augmenté de 64 à 72 pour éviter les débordements
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.dashboard_rounded, context.tr('dashboard'), 0, primaryColor, isDark),
              _buildNavItem(context, Icons.inventory_2_rounded, context.tr('products'), 1, primaryColor, isDark),
              _buildNavItem(context, Icons.description_rounded, context.tr('quotes'), 2, primaryColor, isDark),
              _buildNavItem(context, Icons.people_rounded, context.tr('clients'), 3, primaryColor, isDark),
              _buildNavItem(context, Icons.settings_rounded, context.tr('settings'), 4, primaryColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, Color primaryColor, bool isDark) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? primaryColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return Expanded(
      child: InkWell(
        onTap: () {
          MobileUtils.selectionHaptic();
          onItemTapped(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0), // Réduit de MobileConstants.spacingS (8.0) à 4.0
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: MobileConstants.animationFast,
                padding: EdgeInsets.all(isSelected ? 8 : 4),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(MobileConstants.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
