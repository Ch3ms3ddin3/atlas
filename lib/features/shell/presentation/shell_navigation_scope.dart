import 'package:flutter/material.dart';

/// Indices des onglets du shell (ordre de [AppShell]).
abstract final class AtlasShellTab {
  static const home = 0;
  static const explorer = 1;
  static const map = 2;
  static const procedures = 3;
  static const prices = 4;
  static const profile = 5;
}

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

  static void goToTab(BuildContext context, int index) {
    maybeOf(context)?.navigateToTab(index);
  }

  static void goToHome(BuildContext context) =>
      goToTab(context, AtlasShellTab.home);

  static void goToExplorer(BuildContext context) =>
      goToTab(context, AtlasShellTab.explorer);

  static void goToMap(BuildContext context) =>
      goToTab(context, AtlasShellTab.map);

  static void goToProcedures(BuildContext context) =>
      goToTab(context, AtlasShellTab.procedures);

  static void goToPrices(BuildContext context) =>
      goToTab(context, AtlasShellTab.prices);

  static void goToProfile(BuildContext context) =>
      goToTab(context, AtlasShellTab.profile);

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) => false;
}
