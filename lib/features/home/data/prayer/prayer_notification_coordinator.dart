import 'package:flutter/foundation.dart';

import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/notification_preferences_store.dart';
import '../../../../core/notifications/prayer_notification_lead_time.dart';
import 'prayer_mapper.dart';
import 'prayer_notification_scheduler.dart';
import 'prayer_repository.dart';

/// Orchestre la synchronisation des rappels de prière avec la localisation.
class PrayerNotificationCoordinator {
  PrayerNotificationCoordinator({
    NotificationPreferencesStore? preferencesStore,
    LocalNotificationService? notificationService,
    PrayerRepository? prayerRepository,
    LocationRepository? locationRepository,
    PrayerNotificationScheduler? scheduler,
  })  : _preferencesStore =
            preferencesStore ?? const NotificationPreferencesStore(),
        _notificationService =
            notificationService ?? LocalNotificationService(),
        _prayerRepository = prayerRepository ?? PrayerRepository(),
        _locationRepository = locationRepository ?? LocationRepository(),
        _scheduler = scheduler ?? const PrayerNotificationScheduler();

  final NotificationPreferencesStore _preferencesStore;
  final LocalNotificationService _notificationService;
  final PrayerRepository _prayerRepository;
  final LocationRepository _locationRepository;
  final PrayerNotificationScheduler _scheduler;

  String? _lastSyncKey;

  Future<void> bootstrap() async {
    await _notificationService.initialize();
    await sync();
  }

  Future<PrayerNotificationLeadTime> currentLeadTime() {
    return _preferencesStore.load();
  }

  /// Active ou modifie le rappel ; demande la permission uniquement si nécessaire.
  Future<bool> setLeadTime(PrayerNotificationLeadTime leadTime) async {
    if (leadTime != PrayerNotificationLeadTime.disabled) {
      if (kIsWeb) return false;

      final granted = await _notificationService.requestPermission();
      if (!granted) return false;

      await _notificationService.requestExactAlarmsIfNeeded();
    }

    await _preferencesStore.save(leadTime);
    await sync(force: true);
    return true;
  }

  Future<void> sync({UserLocation? location, bool force = false}) async {
    final leadTime = await _preferencesStore.load();
    if (leadTime == PrayerNotificationLeadTime.disabled) {
      await _notificationService.cancelPrayerNotifications();
      _lastSyncKey = null;
      return;
    }

    if (kIsWeb) return;

    final resolvedLocation = location ?? await _resolveLocationForSync();
    final now = PrayerMapper.casablancaNow();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final syncKey =
        '${today.toIso8601String()}_'
        '${resolvedLocation.latitude}_'
        '${resolvedLocation.longitude}_'
        '${leadTime.name}';
    if (!force && syncKey == _lastSyncKey) return;

    final todayTimings = await _prayerRepository.getTimingsForDate(
      latitude: resolvedLocation.latitude,
      longitude: resolvedLocation.longitude,
      date: today,
    );
    final tomorrowTimings = await _prayerRepository.getTimingsForDate(
      latitude: resolvedLocation.latitude,
      longitude: resolvedLocation.longitude,
      date: tomorrow,
    );

    final notifications = _scheduler.build(
      todayTimings: todayTimings,
      tomorrowTimings: tomorrowTimings,
      leadTime: leadTime,
      now: now,
    );

    await _notificationService.cancelPrayerNotifications();
    for (final notification in notifications) {
      await _notificationService.schedule(notification);
    }

    _lastSyncKey = syncKey;
  }

  Future<UserLocation> _resolveLocationForSync() async {
    try {
      return await _locationRepository.resolveLocation();
    } catch (_) {
      return const UserLocation(
        latitude: LocationConstants.fallbackLatitude,
        longitude: LocationConstants.fallbackLongitude,
        cityName: LocationConstants.fallbackCity,
        isFromGps: false,
      );
    }
  }
}
