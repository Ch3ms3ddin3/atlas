import 'package:flutter/widgets.dart';

import '../../../design_system/theme/atlas_motion.dart';

/// Registers each shell tab's primary [ScrollController] for active-tab retap.
///
/// Owned by [AppShell]; tabs register while mounted and unregister on dispose.
class ShellTabScrollRegistry {
  final Map<int, ScrollController> _controllers = <int, ScrollController>{};

  void register(int tabIndex, ScrollController controller) {
    _controllers[tabIndex] = controller;
  }

  void unregister(int tabIndex, ScrollController controller) {
    if (identical(_controllers[tabIndex], controller)) {
      _controllers.remove(tabIndex);
    }
  }

  /// Smoothly scrolls [tabIndex] to top. No-op if missing, detached, or near top.
  Future<void> scrollToTop(int tabIndex) async {
    final controller = _controllers[tabIndex];
    if (controller == null || !controller.hasClients) return;

    final pixels = controller.position.pixels;
    if (pixels <= _nearTopPixels) return;

    await controller.animateTo(
      0,
      duration: AtlasMotion.durationStandard,
      curve: AtlasMotion.curveDefault,
    );
  }

  @visibleForTesting
  ScrollController? controllerForTest(int tabIndex) => _controllers[tabIndex];

  static const double _nearTopPixels = 8;
}
