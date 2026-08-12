import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';

/// Compact, non-interactive scroll-progress thumb for long Prices lists.
///
/// Position maps clamped scroll progress (top → bottom). Thumb length is fixed
/// for elegance and does not stretch with content ratio or iOS bounce.
class PricesScrollProgressIndicator extends StatefulWidget {
  const PricesScrollProgressIndicator({
    super.key,
    required this.controller,
    this.contentRevision = 0,
  });

  final ScrollController controller;

  /// Bumps when list filters/content change so metrics re-sync after layout.
  final int contentRevision;

  static const double thickness = 4;
  static const double thumbLength = 44;
  static const double trackVerticalInset = 10;

  /// Negative = sit in [AtlasContentContainer] horizontal gutter, clear of cards.
  static const double rightOffset = -10;
  static const Duration fadeInDuration = Duration(milliseconds: 120);
  static const Duration fadeOutDuration = Duration(milliseconds: 280);
  static const Duration hideAfterIdle = Duration(milliseconds: 700);

  @override
  State<PricesScrollProgressIndicator> createState() =>
      PricesScrollProgressIndicatorState();
}

@visibleForTesting
class PricesScrollProgressIndicatorState
    extends State<PricesScrollProgressIndicator> {
  double _progress = 0;
  bool _scrollable = false;
  bool _visible = false;
  Timer? _hideTimer;

  @visibleForTesting
  double get debugProgress => _progress;

  @visibleForTesting
  bool get debugScrollable => _scrollable;

  @visibleForTesting
  bool get debugVisible => _visible;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMetrics());
  }

  @override
  void didUpdateWidget(covariant PricesScrollProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.contentRevision != widget.contentRevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMetrics();
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _syncMetrics(fromScroll: true);
  }

  void _syncMetrics({bool fromScroll = false}) {
    final controller = widget.controller;
    if (!controller.hasClients) {
      if (_scrollable || _visible) {
        setState(() {
          _scrollable = false;
          _visible = false;
        });
      }
      return;
    }

    final position = controller.position;
    if (!position.hasContentDimensions) return;

    final max = position.maxScrollExtent;
    final scrollable = max > 0.5;
    // Clamp out iOS bounce / pull-to-refresh overscroll so the thumb never
    // stretches or jumps past the ends.
    final pixels = position.pixels.clamp(0.0, max);
    final progress = scrollable ? (pixels / max).clamp(0.0, 1.0) : 0.0;

    final progressChanged = (progress - _progress).abs() > 0.0005;
    final scrollableChanged = scrollable != _scrollable;

    if (fromScroll && scrollable && progressChanged) {
      _showTemporarily();
    }

    if (progressChanged || scrollableChanged) {
      setState(() {
        _progress = progress;
        _scrollable = scrollable;
        if (!scrollable) _visible = false;
      });
    }
  }

  void _showTemporarily() {
    _hideTimer?.cancel();
    if (!_visible) {
      setState(() => _visible = true);
    }
    _hideTimer = Timer(PricesScrollProgressIndicator.hideAfterIdle, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_scrollable) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: PricesScrollProgressIndicator.rightOffset,
      top: PricesScrollProgressIndicator.trackVerticalInset,
      bottom: PricesScrollProgressIndicator.trackVerticalInset,
      width: PricesScrollProgressIndicator.thickness,
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackHeight = constraints.maxHeight;
            final thumbHeight = PricesScrollProgressIndicator.thumbLength
                .clamp(0.0, trackHeight)
                .toDouble();
            final travel = (trackHeight - thumbHeight).clamp(
              0.0,
              double.infinity,
            );
            final top = travel * _progress;

            return AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _visible
                  ? PricesScrollProgressIndicator.fadeInDuration
                  : PricesScrollProgressIndicator.fadeOutDuration,
              curve: Curves.easeOut,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    height: thumbHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AtlasColors.midnightBlueFaint.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(
                          PricesScrollProgressIndicator.thickness / 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
