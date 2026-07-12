import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import 'holiday_entry.dart';

/// Client AlAdhan pour les jours fériés islamiques du Maroc (dates estimées).
class IslamicHolidayClient {
  const IslamicHolidayClient();

  static const _moroccoIslamicHolidays = [
    _IslamicHolidayDefinition(day: 1, month: 10, name: 'Aïd al-Fitr'),
    _IslamicHolidayDefinition(day: 2, month: 10, name: 'Aïd al-Fitr'),
    _IslamicHolidayDefinition(day: 10, month: 12, name: 'Aïd al-Adha'),
    _IslamicHolidayDefinition(day: 11, month: 12, name: 'Aïd al-Adha'),
    _IslamicHolidayDefinition(day: 1, month: 1, name: 'Nouvel An hijri'),
    _IslamicHolidayDefinition(day: 12, month: 3, name: 'Mawlid'),
    _IslamicHolidayDefinition(day: 13, month: 3, name: 'Mawlid'),
  ];

  /// Convertit les dates hijri observées au Maroc en jours fériés civils.
  Future<List<HolidayEntry>> fetchIslamicHolidays(int gregorianYear) async {
    final hijriYears = _hijriYearsForGregorianYear(gregorianYear);
    final entries = <HolidayEntry>[];

    for (final hijriYear in hijriYears) {
      for (final holiday in _moroccoIslamicHolidays) {
        final hijriDate = '${holiday.day.toString().padLeft(2, '0')}-'
            '${holiday.month.toString().padLeft(2, '0')}-'
            '$hijriYear';
        final gregorianDate = await _fetchGregorianDate(hijriDate);
        if (gregorianDate.year == gregorianYear) {
          entries.add(
            HolidayEntry(
              date: gregorianDate,
              name: holiday.name,
              isIslamicEstimated: true,
            ),
          );
        }
      }
    }

    return entries;
  }

  static List<int> _hijriYearsForGregorianYear(int year) {
    final approximate = ((year - 622) * 33 ~/ 32);
    return [approximate - 1, approximate, approximate + 1];
  }

  Future<DateTime> _fetchGregorianDate(String hijriDate) async {
    final uri = Uri.https('api.aladhan.com', '/v1/hToG/$hijriDate');
    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final gregorian = data['gregorian'] as Map<String, dynamic>? ?? {};
    return _parseGregorianDate(gregorian['date'] as String? ?? '');
  }

  static DateTime _parseGregorianDate(String ddMmYyyy) {
    final parts = ddMmYyyy.split('-');
    if (parts.length != 3) return DateTime(1970);
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}

class _IslamicHolidayDefinition {
  const _IslamicHolidayDefinition({
    required this.day,
    required this.month,
    required this.name,
  });

  final int day;
  final int month;
  final String name;
}
