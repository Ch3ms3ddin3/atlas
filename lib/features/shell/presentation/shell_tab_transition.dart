import 'package:flutter/material.dart';

import '../../../design_system/theme/atlas_motion.dart';

/// Fondu discret à l'activation d'un onglet — préserve l'état via IndexedStack.
class ShellTabTransition extends StatefulWidget {
  const ShellTabTransition({
    super.key,
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  State<ShellTabTransition> createState() => _ShellTabTransitionState();
}

class _ShellTabTransitionState extends State<ShellTabTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AtlasMotion.pageTransitionDuration,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: AtlasMotion.curveDefault,
    );
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(curve);

    if (widget.isActive) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(ShellTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (AtlasMotion.reduceMotionOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AtlasMotion.reduceMotionOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
