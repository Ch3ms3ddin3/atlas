import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/holiday/holiday_entry.dart';
import 'package:atlas/features/home/data/holiday/holiday_mapper.dart';
import 'package:atlas/features/home/data/holiday/holiday_repository.dart';
import 'package:atlas/features/home/data/holiday/islamic_holiday_client.dart';
import 'package:atlas/features/home/data/holiday/nager_date_client.dart';

void main() {
  group('HolidayMapper', () {
    test('détecte un jour férié civil', () {
      final status = HolidayMapper.forToday(
        [
          HolidayEntry(
            date: DateTime(2026, 7, 30),
            name: 'Fête du Trône',
          ),
        ],
        referenceTime: DateTime(2026, 7, 30, 15, 30),
      );

      expect(status.isHoliday, isTrue);
      expect(status.label, 'Fête du Trône');
      expect(status.detail, HolidayMapper.holidayDetail);
      expect(status.icon, Icons.event_outlined);
    });

    test('détecte un jour férié islamique estimé', () {
      final status = HolidayMapper.forToday(
        [
          HolidayEntry(
            date: DateTime(2026, 3, 20),
            name: 'Aïd al-Fitr',
            isIslamicEstimated: true,
          ),
        ],
        referenceTime: DateTime(2026, 3, 20, 9, 0),
      );

      expect(status.isHoliday, isTrue);
      expect(status.label, 'Aïd al-Fitr');
      expect(status.detail, HolidayMapper.islamicHolidayDetail);
    });

    test('retourne un jour ouvré si aucune correspondance', () {
      final status = HolidayMapper.forToday(
        [
          HolidayEntry(
            date: DateTime(2026, 7, 30),
            name: 'Fête du Trône',
          ),
        ],
        referenceTime: DateTime(2026, 7, 12, 10, 0),
      );

      expect(status.isHoliday, isFalse);
      expect(status.label, 'Jour ouvré');
      expect(status.detail, HolidayMapper.workingDayDetail);
      expect(status.icon, Icons.event_available_outlined);
    });

    test('fusionne les listes sans doublons de date', () {
      final merged = HolidayMapper.mergeHolidayLists(
        [
          HolidayEntry(
            date: DateTime(2026, 1, 1),
            name: 'Jour de l\'an',
          ),
        ],
        [
          HolidayEntry(
            date: DateTime(2026, 1, 1),
            name: 'Autre libellé',
            isIslamicEstimated: true,
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.first.name, 'Jour de l\'an');
    });

    test('traduit les noms Nager.Date en français', () {
      expect(
        HolidayMapper.frenchNameForNagerHoliday('Green March'),
        'Marche Verte',
      );
      expect(
        HolidayMapper.frenchNameForNagerHoliday('Enthronement'),
        'Fête du Trône',
      );
    });
  });

  group('HolidayRepository', () {
    test('retombe sur le mock si une API échoue', () async {
      final repository = HolidayRepository(
        nagerClient: _FailingNagerDateClient(),
        islamicClient: _FakeIslamicHolidayClient(),
      );

      final status = await repository.getHolidayStatus();

      expect(status.isHoliday, isFalse);
      expect(status.label, 'Jour ouvré');
      expect(status.detail, HolidayMapper.fallbackDetail);
    });

    test('combine Nager.Date et AlAdhan', () async {
      final repository = HolidayRepository(
        nagerClient: _FakeNagerDateClient(),
        islamicClient: _FakeIslamicHolidayClient(),
      );

      final status = await repository.getHolidayStatus();

      expect(status.isHoliday, isFalse);
      expect(status.label, 'Jour ouvré');
    });
  });
}

class _FailingNagerDateClient extends NagerDateClient {
  @override
  Future<List<HolidayEntry>> fetchPublicHolidays(int year) async {
    throw Exception('network error');
  }
}

class _FakeNagerDateClient extends NagerDateClient {
  @override
  Future<List<HolidayEntry>> fetchPublicHolidays(int year) async {
    return [
      HolidayEntry(
        date: DateTime(2026, 7, 30),
        name: 'Fête du Trône',
      ),
    ];
  }
}

class _FakeIslamicHolidayClient extends IslamicHolidayClient {
  @override
  Future<List<HolidayEntry>> fetchIslamicHolidays(int gregorianYear) async {
    return [
      HolidayEntry(
        date: DateTime(2026, 3, 20),
        name: 'Aïd al-Fitr',
        isIslamicEstimated: true,
      ),
    ];
  }
}
