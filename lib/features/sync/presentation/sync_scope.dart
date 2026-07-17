import 'package:flutter/material.dart';

import '../data/syncing_user_preferences_repository.dart';

/// Expose le statut de synchronisation cloud.
class SyncScope extends InheritedNotifier<SyncingUserPreferencesRepository> {
  const SyncScope({
    super.key,
    required SyncingUserPreferencesRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static SyncingUserPreferencesRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SyncScope>();
    assert(scope != null, 'SyncScope introuvable');
    return scope!.notifier!;
  }

  static SyncingUserPreferencesRepository? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SyncScope>()?.notifier;
  }
}
