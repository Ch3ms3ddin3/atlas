import '../mock/home_mock_data.dart';
import '../../domain/models/home_models.dart';
import 'aladhan_client.dart';
import 'prayer_mapper.dart';

/// Orchestre la récupération des horaires de prière et le repli sur les mocks.
class PrayerRepository {
  PrayerRepository({AladhanClient? client})
      : _client = client ?? const AladhanClient();

  final AladhanClient _client;

  Map<String, String>? _cachedTimings;
  String _calculationMethod = PrayerMapper.liveCalculationMethod;
  bool _usingFallback = false;

  /// Tente l'API ; en cas d'échec, conserve les horaires fictifs.
  Future<PrayerTimeData> getPrayerTimes() async {
    try {
      final timings = await _client.fetchTodayTimings();
      _cachedTimings = timings;
      _calculationMethod = PrayerMapper.liveCalculationMethod;
      _usingFallback = false;
      return buildForNow();
    } catch (_) {
      return _fallbackPrayerTimes();
    }
  }

  /// Recalcule la prochaine prière à partir du cache ou du mock.
  PrayerTimeData buildForNow() {
    if (_cachedTimings != null && !_usingFallback) {
      return PrayerMapper.fromTimings(
        _cachedTimings!,
        calculationMethod: _calculationMethod,
      );
    }
    return _fallbackPrayerTimes();
  }

  PrayerTimeData _fallbackPrayerTimes() {
    _usingFallback = true;
    _calculationMethod = PrayerMapper.fallbackCalculationMethod;
    _cachedTimings = {
      for (final item in HomeMockData.prayerTime.schedule)
        item.name: item.time,
    };
    return PrayerMapper.fromTimings(
      _cachedTimings!,
      calculationMethod: _calculationMethod,
    );
  }
}
