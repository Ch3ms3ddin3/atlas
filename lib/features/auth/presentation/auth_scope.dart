import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';

/// Fournit le [AuthRepository] partagé à toute l'application.
class AuthScope extends InheritedNotifier<AuthRepository> {
  const AuthScope({
    super.key,
    required AuthRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static AuthRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  /// Lecture sans écouter les mises à jour.
  static AuthRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
