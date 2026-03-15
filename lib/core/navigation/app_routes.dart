import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route Transitions — Splitty Navigation System
// ─────────────────────────────────────────────────────────────────────────────

/// Slide-from-right (legacy, still used where explicit slide is desired)
Route<T> slideRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: duration ?? const Duration(milliseconds: 350),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 300),
  );
}

/// Fade transition — for detail screens and modals
Route<T> fadeRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: duration ?? const Duration(milliseconds: 280),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 220),
  );
}

/// Shared-axis horizontal — for top-level navigation transitions (Material You)
Route<T> sharedAxisRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeIn = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slideOut = Tween(
        begin: Offset.zero,
        end: const Offset(-0.04, 0.0),
      ).chain(CurveTween(curve: Curves.easeInCubic));
      final fadeOut = CurvedAnimation(
          parent: secondaryAnimation, curve: Curves.easeIn);

      return FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(fadeIn),
        child: SlideTransition(
          position: animation.drive(slideIn),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.85).animate(fadeOut),
            child: SlideTransition(
              position: secondaryAnimation.drive(slideOut),
              child: child,
            ),
          ),
        ),
      );
    },
    transitionDuration: duration ?? const Duration(milliseconds: 380),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 320),
  );
}

/// Bottom-sheet style slide-up — for add screens, forms
Route<T> slideUpRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0.0, 0.12),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      final fade =
          CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0).animate(fade),
        child: SlideTransition(position: animation.drive(tween), child: child),
      );
    },
    transitionDuration: duration ?? const Duration(milliseconds: 380),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 300),
  );
}
