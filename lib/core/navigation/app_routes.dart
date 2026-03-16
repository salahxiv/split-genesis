import 'package:flutter/cupertino.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route Transitions — iOS-inspired Navigation
// ─────────────────────────────────────────────────────────────────────────────

/// iOS slide-from-right — default push transition (CupertinoPageRoute style)
Route<T> slideRoute<T>(Widget page, {Duration? duration}) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

/// Shared-axis / detail push — iOS slide with subtle parallax
Route<T> sharedAxisRoute<T>(Widget page, {Duration? duration}) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

/// Fade transition — for tab switches and overlays
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

/// Bottom-sheet style slide-up — for add screens, forms, modals
Route<T> slideUpRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: duration ?? const Duration(milliseconds: 400),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 320),
    fullscreenDialog: true,
  );
}
