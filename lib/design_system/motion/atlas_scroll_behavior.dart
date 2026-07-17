import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Comportement de scroll Atlas — overscroll fluide, mobile + desktop.
class AtlasScrollBehavior extends MaterialScrollBehavior {
  const AtlasScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
