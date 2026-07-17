import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/atlas_motion.dart';

/// Entrée discrète — fondu + léger glissement vers le haut, sans impact perf.
class AtlasReveal extends StatefulWidget {
  const AtlasReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AtlasMotion.revealDuration,
    this.offset = AtlasMotion.revealOffset,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<AtlasReveal> createState() => _AtlasRevealState();
}

class _AtlasRevealState extends State<AtlasReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AtlasMotion.curveDefault,
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AtlasMotion.curveDefault),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isCompleted || _controller.isAnimating) return;
    if (AtlasMotion.reduceMotionOf(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer ??= Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
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
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
