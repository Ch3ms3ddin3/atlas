import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/home/data/prayer/prayer_notification_coordinator.dart';
import '../../features/home/data/prayer/prayer_repository.dart';
import 'local_notification_service.dart';

PrayerNotificationCoordinator? _prayerNotificationCoordinator;
bool _prayerTimeZonesInitialized = false;
Future<void>? _prayerBootstrapInFlight;

/// Ensures Africa/Casablanca is registered before any TZDateTime scheduling.
///
/// Safe to call from synchronous UI paths (e.g. Profile build) — pure CPU work,
/// no plugins, no artificial delay.
void ensurePrayerTimeZonesInitialized() {
  if (_prayerTimeZonesInitialized) return;
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));
  _prayerTimeZonesInitialized = true;
}

/// Shared coordinator — constructed synchronously on first access.
///
/// Profile / Home may read this while [IndexedStack] builds, before the deferred
/// [bootstrapPrayerNotifications] future completes. Construction must never
/// throw [LateInitializationError].
PrayerNotificationCoordinator get prayerNotificationCoordinator {
  ensurePrayerTimeZonesInitialized();
  return _prayerNotificationCoordinator ??= PrayerNotificationCoordinator(
    prayerRepository: PrayerRepository.instance,
  );
}

/// Idempotent launch bootstrap: timezone + notification plugin + initial sync.
///
/// Concurrent callers share one in-flight future so Home/main do not race.
Future<void> bootstrapPrayerNotifications() async {
  ensurePrayerTimeZonesInitialized();
  PrayerRepository.registerInstance(PrayerRepository.instance);
  // Touch getter so the shared instance exists before await.
  final coordinator = prayerNotificationCoordinator;

  final inFlight = _prayerBootstrapInFlight;
  if (inFlight != null) {
    await inFlight;
    return;
  }

  final future = coordinator.bootstrap();
  _prayerBootstrapInFlight = future;
  try {
    await future;
  } finally {
    if (identical(_prayerBootstrapInFlight, future)) {
      _prayerBootstrapInFlight = null;
    }
  }
}

/// Provides a coordinator for widget tests without native notification plugins.
void ensurePrayerNotificationCoordinatorForTests({
  PrayerRepository? prayerRepository,
  LocalNotificationService? notificationService,
  Future<void> Function()? cloudPersist,
}) {
  ensurePrayerTimeZonesInitialized();
  final repository = prayerRepository ?? PrayerRepository();
  PrayerRepository.registerInstance(repository);
  _prayerNotificationCoordinator = PrayerNotificationCoordinator(
    prayerRepository: repository,
    notificationService: notificationService,
  );
  _prayerNotificationCoordinator!.bindCloudPersist(cloudPersist);
  _prayerBootstrapInFlight = null;
}

@visibleForTesting
void resetPrayerNotificationBootstrapForTests() {
  _prayerNotificationCoordinator = null;
  _prayerBootstrapInFlight = null;
  _prayerTimeZonesInitialized = false;
}
