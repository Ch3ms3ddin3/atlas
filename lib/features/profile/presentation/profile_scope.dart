import 'package:flutter/material.dart';

import '../data/profile_repository.dart';

/// Fournit le [ProfileRepository] partagé à toute l'application.
class ProfileScope extends InheritedNotifier<ProfileRepository> {
  const ProfileScope({
    super.key,
    required ProfileRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static ProfileRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'ProfileScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  /// Lecture sans écouter les mises à jour.
  static ProfileRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'ProfileScope introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
