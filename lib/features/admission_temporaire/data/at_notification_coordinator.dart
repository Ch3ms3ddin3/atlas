import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notification_service.dart';
import '../domain/at_repository.dart';
import 'at_notification_scheduler.dart';

/// Orchestre les rappels d'échéance AT (opt-in, jamais auto-activés).
class AtNotificationCoordinator {
  AtNotificationCoordinator({
    required this._repository,
    LocalNotificationService? notificationService,
    AtNotificationScheduler? scheduler,
  })  : _notificationService =
            notificationService ?? LocalNotificationService(),
        _scheduler = scheduler ?? const AtNotificationScheduler();

  final AtRepository _repository;
  final LocalNotificationService _notificationService;
  final AtNotificationScheduler _scheduler;

  Future<void> bootstrap() async {
    await _notificationService.initialize();
    await sync(force: true);
  }

  /// Active les rappels après consentement explicite. Retourne false si refusé.
  Future<bool> enableNotifications() async {
    if (kIsWeb) return false;

    final granted = await _notificationService.requestPermission();
    if (!granted) return false;

    await _notificationService.requestExactAlarmsIfNeeded();
    await _repository.setNotificationsEnabled(true);
    await sync(force: true);
    return true;
  }

  Future<void> disableNotifications() async {
    await _repository.setNotificationsEnabled(false);
    await _notificationService.cancelAtNotifications();
  }

  Future<void> sync({bool force = false}) async {
    if (!_repository.isLoaded && !force) return;

    if (!_repository.notificationsEnabled) {
      await _notificationService.cancelAtNotifications();
      return;
    }

    if (kIsWeb) return;

    await _notificationService.initialize();
    await _notificationService.cancelAtNotifications();

    final scheduled = _scheduler.build(
      vehicles: _repository.activeVehicles,
      notificationsEnabled: true,
    );

    for (final notification in scheduled) {
      await _notificationService.scheduleAt(notification);
    }
  }
}
