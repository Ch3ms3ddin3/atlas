import '../../domain/models/home_models.dart';
import '../../domain/models/weather_snapshot.dart';
import 'open_meteo_client.dart';
import 'weather_cache_store.dart';

/// Orchestre Open-Meteo + cache durable — jamais de météo inventée.
class WeatherRepository {
  WeatherRepository({
    OpenMeteoClient? client,
    WeatherCacheStore? cacheStore,
  })  : _client = client ?? const OpenMeteoClient(),
        _cacheStore = cacheStore ?? const WeatherCacheStore();

  final OpenMeteoClient _client;
  final WeatherCacheStore _cacheStore;

  WeatherData? _memory;
  double? _memoryLat;
  double? _memoryLng;

  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final live = await _client.fetchCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      final stamped = WeatherData(
        temperature: live.temperature,
        feelsLike: live.feelsLike,
        condition: live.condition,
        icon: live.icon,
        weatherCode: live.weatherCode,
        fetchedAt: live.fetchedAt ?? DateTime.now(),
        observedAtIso: live.observedAtIso,
        windKmh: live.windKmh,
        uvIndex: live.uvIndex,
        rainProbabilityPercent: live.rainProbabilityPercent,
      );
      await _cacheStore.save(
        latitude: latitude,
        longitude: longitude,
        data: stamped,
      );
      _remember(
        latitude: latitude,
        longitude: longitude,
        data: stamped,
      );
      return WeatherSnapshot(
        state: WeatherLoadState.success,
        data: stamped,
      );
    } catch (_) {
      return _snapshotFromCache(latitude: latitude, longitude: longitude);
    }
  }

  Future<WeatherSnapshot> _snapshotFromCache({
    required double latitude,
    required double longitude,
  }) async {
    final cached = await _cacheStore.load(
          latitude: latitude,
          longitude: longitude,
        ) ??
        (_sameLocation(latitude, longitude) ? _memory : null);

    if (cached == null) {
      if (_sameLocation(latitude, longitude)) {
        _memory = null;
      }
      return const WeatherSnapshot.unavailable();
    }

    _remember(
      latitude: latitude,
      longitude: longitude,
      data: cached,
    );
    return WeatherSnapshot(
      state: WeatherLoadState.stale,
      data: cached,
    );
  }

  void _remember({
    required double latitude,
    required double longitude,
    required WeatherData data,
  }) {
    _memoryLat = latitude;
    _memoryLng = longitude;
    _memory = data;
  }

  bool _sameLocation(double latitude, double longitude) {
    return _memoryLat == latitude && _memoryLng == longitude;
  }
}
