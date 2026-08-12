import 'package:flutter/widgets.dart';

import 'shell_navigation_scope.dart';
import 'shell_tab_scroll_registry.dart';

/// Registers [tabScrollController] with the shell while this [State] is mounted.
///
/// Call [bindShellTabScroll] from [State.didChangeDependencies] and
/// [unbindShellTabScroll] from [State.dispose] (before disposing the controller).
mixin ShellTabScrollBinding<T extends StatefulWidget> on State<T> {
  /// Shell tab index ([AtlasShellTab]).
  int get shellTabIndex;

  /// Primary vertical scroll controller for this tab's content.
  ScrollController get tabScrollController;

  ShellTabScrollRegistry? _shellScrollRegistry;

  void bindShellTabScroll() {
    final registry = ShellNavigationScope.maybeOf(context)?.scrollRegistry;
    if (identical(registry, _shellScrollRegistry)) {
      // Re-register in case another page briefly claimed the same index.
      registry?.register(shellTabIndex, tabScrollController);
      return;
    }
    _shellScrollRegistry?.unregister(shellTabIndex, tabScrollController);
    _shellScrollRegistry = registry;
    registry?.register(shellTabIndex, tabScrollController);
  }

  void unbindShellTabScroll() {
    _shellScrollRegistry?.unregister(shellTabIndex, tabScrollController);
    _shellScrollRegistry = null;
  }
}
