import 'package:flutter/material.dart';

import '../domain/assistant_repository.dart';

/// Fournit le [AssistantRepository] à l'arbre UI.
class AssistantScope extends InheritedNotifier<AssistantRepository> {
  const AssistantScope({
    super.key,
    required AssistantRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static AssistantRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AssistantScope>();
    assert(scope != null, 'AssistantScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  static AssistantRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AssistantScope>()
        ?.notifier;
  }

  static AssistantRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AssistantScope>();
    assert(scope != null, 'AssistantScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
