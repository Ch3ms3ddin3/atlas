import '../mock/home_mock_data.dart';
import '../../domain/models/home_models.dart';
import 'holiday_entry.dart';
import 'holiday_mapper.dart';
import 'islamic_holiday_client.dart';
import 'nager_date_client.dart';

/// Orchestre la récupération des jours fériés marocains et le repli sur les mocks.
class HolidayRepository {
  HolidayRepository({
    NagerDateClient? nagerClient,
    IslamicHolidayClient? islamicClient,
  })  : _nagerClient = nagerClient ?? const NagerDateClient(),
        _islamicClient = islamicClient ?? const IslamicHolidayClient();

  final NagerDateClient _nagerClient;
  final IslamicHolidayClient _islamicClient;

  List<HolidayEntry>? _cachedHolidays;
  int? _cachedYear;

  /// Tente les APIs ; en cas d'échec, renvoie le mock avec un libellé explicite.
  Future<HolidayStatusData> getHolidayStatus() async {
    try {
      final now = HolidayMapper.casablancaNow();
      final holidays = await _fetchYearHolidays(now.year);
      _cachedHolidays = holidays;
      _cachedYear = now.year;
      return HolidayMapper.forToday(holidays, referenceTime: now);
    } catch (_) {
      return _fallbackHolidayStatus();
    }
  }

  /// Recalcule le statut à partir du cache (même jour civile).
  HolidayStatusData buildForNow() {
    final now = HolidayMapper.casablancaNow();
    if (_cachedHolidays != null && _cachedYear == now.year) {
      return HolidayMapper.forToday(_cachedHolidays!, referenceTime: now);
    }
    return _fallbackHolidayStatus();
  }

  Future<List<HolidayEntry>> _fetchYearHolidays(int year) async {
    final results = await Future.wait([
      _nagerClient.fetchPublicHolidays(year),
      _islamicClient.fetchIslamicHolidays(year),
    ]);
    return HolidayMapper.mergeHolidayLists(results[0], results[1]);
  }

  HolidayStatusData _fallbackHolidayStatus() {
    const mock = HomeMockData.holidayStatus;
    return HolidayStatusData(
      isHoliday: mock.isHoliday,
      label: mock.label,
      detail: HolidayMapper.fallbackDetail,
      icon: mock.icon,
    );
  }
}
