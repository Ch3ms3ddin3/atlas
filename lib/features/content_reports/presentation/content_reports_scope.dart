import 'package:flutter/material.dart';

import '../domain/content_reports_repository.dart';

/// Fournit le [ContentReportsRepository] partagé à toute l'application.
class ContentReportsScope extends InheritedNotifier<ContentReportsRepository> {
  const ContentReportsScope({
    super.key,
    required ContentReportsRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static ContentReportsRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ContentReportsScope>();
    assert(
      scope != null,
      'ContentReportsScope introuvable dans l\'arbre de widgets.',
    );
    return scope!.notifier!;
  }

  /// Lecture sans écouter les mises à jour.
  static ContentReportsRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ContentReportsScope>();
    assert(
      scope != null,
      'ContentReportsScope introuvable dans l\'arbre de widgets.',
    );
    return scope!.notifier!;
  }
}
