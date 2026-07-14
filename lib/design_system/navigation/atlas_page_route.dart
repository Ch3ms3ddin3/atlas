import 'package:flutter/material.dart';

import '../theme/atlas_motion.dart';

/// Transition premium pour les écrans de détail — fade + léger glissement.
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
                child: child,
              ),
            );
          },
        );
}
