import 'package:flutter/material.dart';
import '../core/constants/mobile_constants.dart';
import '../core/utils/mobile_utils.dart';

/// Bouton optimisé pour mobile avec feedback haptique
class MobileButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double height;

  const MobileButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = MobileConstants.buttonHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final fgColor = textColor ?? Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : _handlePress,
              style: OutlinedButton.styleFrom(
                foregroundColor: bgColor,
                side: BorderSide(color: bgColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MobileConstants.radiusM),
                ),
              ),
              child: _buildContent(bgColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : _handlePress,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MobileConstants.radiusM),
                ),
              ),
              child: _buildContent(fgColor),
            ),
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: MobileConstants.fontSizeM,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: MobileConstants.fontSizeM,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _handlePress() {
    MobileUtils.lightHaptic();
    onPressed?.call();
  }
}
