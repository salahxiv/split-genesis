import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumpadButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NumpadButton({
    super.key,
    this.label = '',
    this.icon,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<NumpadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onLongPress: widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withAlpha(15)
                : Colors.grey.shade100,
          ),
          alignment: Alignment.center,
          child: widget.icon != null
              ? Icon(widget.icon, size: 24)
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
