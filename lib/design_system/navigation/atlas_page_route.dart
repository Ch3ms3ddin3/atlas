import 'package:flutter/material.dart';

import '../theme/atlas_motion.dart';

/// Transition premium pour les écrans de détail — fade + scale + léger glissement.
class AtlasPageRoute<T> extends PageRouteBuilder<T> {
  AtlasPageRoute({
    required Widget page,
    Widget Function(Widget page)? wrapPage,
    super.settings,
  }) : super(
          transitionDuration: AtlasMotion.pageTransitionDuration,
          reverseTransitionDuration: AtlasMotion.pageTransitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) {
            return wrapPage != null ? wrapPage(page) : page;
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (AtlasMotion.reduceMotionOf(context)) {
              return child;
            }
            final curved = CurvedAnimation(
              parent: animation,
              curve: AtlasMotion.curveDefault,
              reverseCurve: AtlasMotion.curveExit,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}
