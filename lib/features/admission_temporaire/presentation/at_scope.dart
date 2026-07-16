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
    assert(scope != null, 'AtScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  static AtRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AtScope>();
    assert(scope != null, 'AtScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
