import 'package:flutter/material.dart';

class SuccessDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Continuer',
    VoidCallback? onConfirm,
    bool autoDismiss = false,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _SuccessDialogContent(
          title: title,
          message: message,
          buttonText: buttonText,
          onConfirm: onConfirm,
          autoDismiss: autoDismiss,
          autoDismissDuration: autoDismissDuration,
        );
      },
    );
  }
}

class _SuccessDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onConfirm;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const _SuccessDialogContent({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onConfirm,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 2),
  });

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-dismiss si activé
    if (widget.autoDismiss) {
      Future.delayed(widget.autoDismissDuration, () {
        if (mounted) {
          Navigator.of(context).pop();
          if (widget.onConfirm != null) {
            widget.onConfirm!();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with animation
              _buildSuccessIcon(),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Button (masqué si autoDismiss)
              if (!widget.autoDismiss)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (widget.onConfirm != null) {
                        widget.onConfirm!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5C63),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated check mark
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(40, 40),
                painter: _CheckMarkPainter(
                  progress: _checkAnimation.value,
                  color: const Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckMarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Starting point
    final startX = size.width * 0.2;
    final startY = size.height * 0.5;

    // Middle point
    final middleX = size.width * 0.4;
    final middleY = size.height * 0.7;

    // End point
    final endX = size.width * 0.8;
    final endY = size.height * 0.3;

    path.moveTo(startX, startY);

    if (progress <= 0.5) {
      // First part of the check (going down)
      final t = progress * 2;
      final currentX = startX + (middleX - startX) * t;
      final currentY = startY + (middleY - startY) * t;
      path.lineTo(currentX, currentY);
    } else {
      // Complete first part
      path.lineTo(middleX, middleY);

      // Second part of the check (going up)
      final t = (progress - 0.5) * 2;
      final currentX = middleX + (endX - middleX) * t;
      final currentY = middleY + (endY - middleY) * t;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}