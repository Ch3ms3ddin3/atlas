import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import 'holiday_entry.dart';
import 'holiday_mapper.dart';

/// Client réseau pour l'API Nager.Date (jours fériés civils du Maroc).
class NagerDateClient {
  const NagerDateClient();

  static const _countryCode = 'MA';

  /// Récupère les jours fériés nationaux fixes pour une année civile.
  Future<List<HolidayEntry>> fetchPublicHolidays(int year) async {
    final uri = Uri.https(
      'date.nager.at',
      '/api/v4/Holidays/$_countryCode/$year',
    );

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as List<dynamic>;

    return [
      for (final item in json)
        if (_isNationalPublicHoliday(item as Map<String, dynamic>))
          HolidayEntry(
            date: _parseIsoDate(item['date'] as String? ?? ''),
            name: HolidayMapper.frenchNameForNagerHoliday(
              item['name'] as String? ?? '',
            ),
          ),
    ];
  }

  static bool _isNationalPublicHoliday(Map<String, dynamic> item) {
    if (item['nationalHoliday'] != true) return false;
    final types = item['holidayTypes'] as List<dynamic>? ?? [];
    return types.contains('Public');
  }

  static DateTime _parseIsoDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return DateTime(1970);
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
