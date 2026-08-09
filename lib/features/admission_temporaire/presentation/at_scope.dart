import 'package:flutter/material.dart';

import '../domain/at_repository.dart';

/// Fournit le [AtRepository] partagé à toute l'application.
class AtScope extends InheritedNotifier<AtRepository> {
  const AtScope({
    super.key,
    required AtRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static AtRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AtScope>();
    final repository = scope?.notifier;
    if (repository == null) {
      throw StateError(
        'AtScope introuvable dans l\'arbre de widgets. '
        'Utilisez wrapWithAtScope pour les routes poussées hors du shell.',
      );
    }
    return repository;
  }

  static AtRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AtScope>();
    final repository = scope?.notifier;
    if (repository == null) {
      throw StateError(
        'AtScope introuvable dans l\'arbre de widgets. '
        'Utilisez wrapWithAtScope pour les routes poussées hors du shell.',
      );
    }
    return repository;
  }
}
