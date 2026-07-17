import 'package:flutter/material.dart';

import '../theme/atlas_motion.dart';

/// Remplace un contenu sans saut — fade entre états (loading → ready).
class AtlasFadeSwitcher extends StatelessWidget {
  const AtlasFadeSwitcher({
    super.key,
    required this.child,
    this.duration = AtlasMotion.contentSwapDuration,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AtlasMotion.resolve(context, duration),
      switchInCurve: AtlasMotion.curveEnter,
      switchOutCurve: AtlasMotion.curveExit,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}
