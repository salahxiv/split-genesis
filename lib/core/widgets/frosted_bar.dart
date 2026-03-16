import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedBar extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final Color? backgroundColor;
  final double opacity;

  const FrostedBar({
    super.key,
    required this.child,
    this.sigmaX = 25,
    this.sigmaY = 25,
    this.backgroundColor,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0xFF0A0A0A).withOpacity(opacity)
            : const Color(0xFFF2F2F7).withOpacity(opacity));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          color: bgColor,
          child: child,
        ),
      ),
    );
  }
}
