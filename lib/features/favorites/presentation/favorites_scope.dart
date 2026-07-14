import 'package:flutter/material.dart';

import '../domain/favorites_repository.dart';

/// Fournit le [FavoritesRepository] partagé à toute l'application.
class FavoritesScope extends InheritedNotifier<FavoritesRepository> {
  const FavoritesScope({
    super.key,
    required FavoritesRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static FavoritesRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  /// Lecture sans écouter les mises à jour.
  static FavoritesRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
