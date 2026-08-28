import 'package:flutter/foundation.dart';

import '../../domain/models/prayer_times_snapshot.dart';
import 'aladhan_client.dart';
import 'prayer_calculation_policy.dart';
import 'prayer_mapper.dart';
import 'prayer_timings_cache_store.dart';

/// Orchestre AlAdhan + cache durable — jamais d'horaires inventés.
class PrayerRepository {
  PrayerRepository({AladhanClient? client, PrayerTimingsCacheStore? cacheStore})
    : _client = client ?? const AladhanClient(),
      _cacheStore = cacheStore ?? const PrayerTimingsCacheStore();

  static PrayerRepository? _instance;

  /// Instance partagée Home ↔ notifications.
  static PrayerRepository get instance {
    return _instance ??= PrayerRepository();
  }

  static void registerInstance(PrayerRepository repository) {
    _instance = repository;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  final AladhanClient _client;
  final PrayerTimingsCacheStore _cacheStore;

  Map<String, String>? _todayTimings;
  Map<String, String>? _tomorrowTimings;
  double? _cachedLatitude;
  double? _cachedLongitude;
  DateTime? _cachedDay;
  String _methodLabel = PrayerCalculationPolicy.moroccoLabel;
  PrayerLoadState _memoryState = PrayerLoadState.unavailable;

  /// Charge (réseau puis cache) les horaires pour les coordonnées données.
  Future<PrayerTimesSnapshot> getPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    DateTime? referenceTime,
    String? timeZoneString,
    String? calculationMethodLabel,
  }) async {
    final now = referenceTime ?? PrayerMapper.casablancaNow();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final label =
        calculationMethodLabel ??
        PrayerCalculationPolicy.labelForMethod(method);

    try {
      final todayTimings = await _client.fetchTimingsForDate(
        latitude: latitude,
        longitude: longitude,
        date: today,
        method: method,
        timeZoneString: timeZoneString,
      );
      final tomorrowTimings = await _client.fetchTimingsForDate(
        latitude: latitude,
        longitude: longitude,
        date: tomorrow,
        method: method,
        timeZoneString: timeZoneString,
      );

      await _cacheStore.save(
        latitude: latitude,
        longitude: longitude,
        date: today,
        timings: todayTimings,
      );
      await _cacheStore.save(
        latitude: latitude,
        longitude: longitude,
        date: tomorrow,
        timings: tomorrowTimings,
      );

      _remember(
        latitude: latitude,
        longitude: longitude,
        day: today,
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        state: PrayerLoadState.success,
        methodLabel: label,
      );

      return PrayerTimesSnapshot(
        state: PrayerLoadState.success,
        data: PrayerMapper.fromTimings(
          todayTimings: todayTimings,
          tomorrowTimings: tomorrowTimings,
          referenceTime: now,
          calculationMethod: label,
        ),
      );
    } catch (_) {
      return _snapshotFromCache(
        latitude: latitude,
        longitude: longitude,
        referenceTime: now,
        methodLabel: label,
      );
    }
  }

  /// Recalcule la prochaine prière depuis le cache mémoire (compte à rebours).
  PrayerTimesSnapshot buildForNow({DateTime? referenceTime}) {
    final today = _todayTimings;
    final tomorrow = _tomorrowTimings;
    if (today == null || tomorrow == null) {
      return const PrayerTimesSnapshot.unavailable();
    }

    final now = referenceTime ?? PrayerMapper.casablancaNow();
    return PrayerTimesSnapshot(
      state: _memoryState == PrayerLoadState.success
          ? PrayerLoadState.success
          : PrayerLoadState.stale,
      data: PrayerMapper.fromTimings(
        todayTimings: today,
        tomorrowTimings: tomorrow,
        referenceTime: now,
        calculationMethod: _memoryState == PrayerLoadState.success
            ? _methodLabel
            : 'Horaires enregistrés',
      ),
    );
  }

  /// Horaires bruts pour une date — API puis cache, sinon `null` (pas de mock).
  Future<Map<String, String>?> getTimingsForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
    required int method,
    String? timeZoneString,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    try {
      final timings = await _client.fetchTimingsForDate(
        latitude: latitude,
        longitude: longitude,
        date: day,
        method: method,
        timeZoneString: timeZoneString,
      );
      await _cacheStore.save(
        latitude: latitude,
        longitude: longitude,
        date: day,
        timings: timings,
      );
      return timings;
    } catch (_) {
      return _cacheStore.load(
        latitude: latitude,
        longitude: longitude,
        date: day,
      );
    }
  }

  Future<PrayerTimesSnapshot> _snapshotFromCache({
    required double latitude,
    required double longitude,
    required DateTime referenceTime,
    required String methodLabel,
  }) async {
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final tomorrow = today.add(const Duration(days: 1));

    final todayTimings = await _cacheStore.load(
      latitude: latitude,
      longitude: longitude,
      date: today,
    );
    final tomorrowTimings = await _cacheStore.load(
      latitude: latitude,
      longitude: longitude,
      date: tomorrow,
    );

    if (todayTimings == null || tomorrowTimings == null) {
      _clearMemory();
      return const PrayerTimesSnapshot.unavailable();
    }

    _remember(
      latitude: latitude,
      longitude: longitude,
      day: today,
      todayTimings: todayTimings,
      tomorrowTimings: tomorrowTimings,
      state: PrayerLoadState.stale,
      methodLabel: methodLabel,
    );

    return PrayerTimesSnapshot(
      state: PrayerLoadState.stale,
      data: PrayerMapper.fromTimings(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        referenceTime: referenceTime,
        calculationMethod: 'Horaires enregistrés',
      ),
    );
  }

  void _remember({
    required double latitude,
    required double longitude,
    required DateTime day,
    required Map<String, String> todayTimings,
    required Map<String, String> tomorrowTimings,
    required PrayerLoadState state,
    required String methodLabel,
  }) {
    _cachedLatitude = latitude;
    _cachedLongitude = longitude;
    _cachedDay = day;
    _todayTimings = todayTimings;
    _tomorrowTimings = tomorrowTimings;
    _memoryState = state;
    _methodLabel = methodLabel;
  }

  void _clearMemory() {
    _todayTimings = null;
    _tomorrowTimings = null;
    _cachedLatitude = null;
    _cachedLongitude = null;
    _cachedDay = null;
    _memoryState = PrayerLoadState.unavailable;
    _methodLabel = PrayerCalculationPolicy.moroccoLabel;
  }

  @visibleForTesting
  double? get debugCachedLatitude => _cachedLatitude;

  @visibleForTesting
  double? get debugCachedLongitude => _cachedLongitude;

  @visibleForTesting
  DateTime? get debugCachedDay => _cachedDay;
}
