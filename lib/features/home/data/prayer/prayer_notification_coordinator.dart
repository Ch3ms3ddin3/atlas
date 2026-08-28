import 'package:flutter/foundation.dart';

import '../../../../core/location/atlas_city_source.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/notification_preferences_store.dart';
import '../../../../core/notifications/prayer_notification_lead_time.dart';
import '../../../explorer/domain/place_browse_filters.dart';
import '../../../profile/data/profile_preferences_store.dart';
import '../../../sync/data/user_preferences_store.dart';
import 'prayer_calculation_policy.dart';
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
    ProfilePreferencesStore? profilePreferencesStore,
    UserPreferencesStore? userPreferencesStore,
  }) : _preferencesStore =
           preferencesStore ?? const NotificationPreferencesStore(),
       _notificationService = notificationService ?? LocalNotificationService(),
       _prayerRepository = prayerRepository ?? PrayerRepository.instance,
       _locationRepository = locationRepository ?? LocationRepository(),
       _scheduler = scheduler ?? const PrayerNotificationScheduler(),
       _profilePreferencesStore =
           profilePreferencesStore ?? const ProfilePreferencesStore(),
       _userPreferencesStore =
           userPreferencesStore ?? const UserPreferencesStore();

  final NotificationPreferencesStore _preferencesStore;
  final LocalNotificationService _notificationService;
  final PrayerRepository _prayerRepository;
  final LocationRepository _locationRepository;
  final PrayerNotificationScheduler _scheduler;
  final ProfilePreferencesStore _profilePreferencesStore;
  final UserPreferencesStore _userPreferencesStore;

  /// Invoked after a local lead-time change so signed-in cloud prefs can push.
  /// Bound by AppShell to [SyncingUserPreferencesRepository.persistFromUi].
  Future<void> Function()? _cloudPersist;

  String? _lastSyncKey;

  /// Registers (or clears) the cloud prefs persist hook without rebuilding.
  void bindCloudPersist(Future<void> Function()? callback) {
    _cloudPersist = callback;
  }

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

      // Deterministic before deferred bootstrap: never silently no-op schedule.
      await _notificationService.initialize();
      final granted = await _notificationService.requestPermission();
      if (!granted) return false;

      await _notificationService.requestExactAlarmsIfNeeded();
    }

    await _preferencesStore.save(leadTime);
    // Stamp user-preferences metadata so a stale remote cannot overwrite this
    // change (same SharedPreferences prayer key; pending + localUpdatedAt matter).
    await _markUserPreferencesPending(leadTime);
    await sync(force: true);

    final persist = _cloudPersist;
    if (persist != null) {
      await persist();
    }
    return true;
  }

  /// Marks the syncable prefs blob pending after a prayer lead-time edit.
  @visibleForTesting
  Future<void> markUserPreferencesPendingForTests(
    PrayerNotificationLeadTime leadTime,
  ) {
    return _markUserPreferencesPending(leadTime);
  }

  Future<void> _markUserPreferencesPending(
    PrayerNotificationLeadTime leadTime,
  ) async {
    final current = await _userPreferencesStore.load();
    final filters = PlaceBrowseFilters.instance;
    await _userPreferencesStore.save(
      UserPreferencesSnapshot(
        prayerLeadTime: leadTime,
        atNotificationsEnabled: current.atNotificationsEnabled,
        explorerCity: filters.cityName.isNotEmpty
            ? filters.cityName
            : current.explorerCity,
        explorerCategory: filters.category ?? current.explorerCategory,
        explorerFavoritesOnly: filters.favoritesOnly,
        localUpdatedAt: DateTime.now().toUtc(),
      ),
    );
    await _userPreferencesStore.setSyncPending(true);
  }

  Future<void> sync({UserLocation? location, bool force = false}) async {
    final leadTime = await _preferencesStore.load();
    if (leadTime == PrayerNotificationLeadTime.disabled) {
      await _notificationService.cancelPrayerNotifications();
      _lastSyncKey = null;
      return;
    }

    if (kIsWeb) return;

    AtlasCitySource citySource;
    UserLocation resolvedLocation;
    try {
      final profileSnapshot = await _profilePreferencesStore.loadSnapshot();
      citySource = profileSnapshot.profile.citySource;
      resolvedLocation =
          location ??
          await _locationRepository.resolveForProfile(profileSnapshot.profile);
    } catch (_) {
      if (location == null) {
        await _notificationService.cancelPrayerNotifications();
        _lastSyncKey = null;
        return;
      }
      citySource = AtlasCitySource.auto;
      resolvedLocation = location;
    }
    final plan = PrayerCalculationPolicy.resolve(
      citySource: citySource,
      location: resolvedLocation,
    );
    if (!plan.canFetch) {
      await _notificationService.cancelPrayerNotifications();
      _lastSyncKey = null;
      return;
    }

    final now = citySource == AtlasCitySource.manual
        ? PrayerMapper.casablancaNow()
        : DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final syncKey =
        '${today.toIso8601String()}_'
        '${plan.latitude}_'
        '${plan.longitude}_'
        '${plan.methodId}_'
        '${leadTime.name}';
    if (!force && syncKey == _lastSyncKey) return;

    final todayTimings = await _prayerRepository.getTimingsForDate(
      latitude: plan.latitude!,
      longitude: plan.longitude!,
      date: today,
      method: plan.methodId,
      timeZoneString: plan.timeZoneString,
    );
    final tomorrowTimings = await _prayerRepository.getTimingsForDate(
      latitude: plan.latitude!,
      longitude: plan.longitude!,
      date: tomorrow,
      method: plan.methodId,
      timeZoneString: plan.timeZoneString,
    );

    // Pas d'horaires inventés : sans données réelles, on annule les rappels.
    if (todayTimings == null || tomorrowTimings == null) {
      await _notificationService.cancelPrayerNotifications();
      _lastSyncKey = null;
      return;
    }

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
}
