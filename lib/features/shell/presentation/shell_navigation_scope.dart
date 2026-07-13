import 'package:flutter/material.dart';

/// Accès UI à la navigation par onglets depuis les écrans enfants.
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    super.key,
    required this.navigateToTab,
    required super.child,
  });

  final void Function(int index) navigateToTab;

  static ShellNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellNavigationScope>();
  }

  static void goToProfile(BuildContext context) {
    maybeOf(context)?.navigateToTab(4);
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) => false;
}
