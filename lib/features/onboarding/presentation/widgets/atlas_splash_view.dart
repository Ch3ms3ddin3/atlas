import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_mark.dart';

/// Splash Atlas — The Threshold. Pas de délai artificiel après init.
class AtlasSplashView extends StatefulWidget {
  const AtlasSplashView({
    super.key,
    this.reduceMotion = false,
  });

  final bool reduceMotion;

  @override
  State<AtlasSplashView> createState() => _AtlasSplashViewState();
}

class _AtlasSplashViewState extends State<AtlasSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markOpacity;
  late final Animation<double> _wordOpacity;
  late final Animation<Offset> _wordOffset;
  late final Animation<double> _horizonOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 1000),
    );

    if (widget.reduceMotion) {
      _markOpacity = const AlwaysStoppedAnimation(1);
      _wordOpacity =
          CurvedAnimation(parent: _controller, curve: Curves.easeOut);
      _wordOffset = const AlwaysStoppedAnimation(Offset.zero);
      _horizonOpacity = _wordOpacity;
    } else {
      _markOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      );
      _wordOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
      );
      _wordOffset = Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
        ),
      );
      _horizonOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Atlas',
      child: ColoredBox(
        color: AtlasColors.warmOffWhite,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _markOpacity.value,
                          child: const AtlasMark(size: 64),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        SlideTransition(
                          position: _wordOffset,
                          child: Opacity(
                            opacity: _wordOpacity.value,
                            child: Text(
                              'ATLAS',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                letterSpacing: 2.16,
                                fontWeight: FontWeight.w600,
                                color: AtlasColors.midnightBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 48,
                    right: 48,
                    bottom: MediaQuery.sizeOf(context).height * 0.22,
                    child: Opacity(
                      opacity: _horizonOpacity.value,
                      child: const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0x99D9CDB8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
