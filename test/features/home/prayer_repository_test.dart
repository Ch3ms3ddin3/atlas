import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/home/data/prayer/aladhan_client.dart';
import 'package:atlas/features/home/data/prayer/prayer_mapper.dart';
import 'package:atlas/features/home/data/prayer/prayer_repository.dart';
import 'package:atlas/features/home/data/prayer/prayer_timings_cache_store.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';

class _FakeAladhanClient extends AladhanClient {
  _FakeAladhanClient({
    this.fail = false,
    this.byDate = const {},
  });

  bool fail;
  final Map<String, Map<String, String>> byDate;
  final calls = <String>[];

  @override
  Future<Map<String, String>> fetchTimingsForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}_'
        '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
    calls.add(key);
    if (fail) throw Exception('network');
    final dayKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final timings = byDate[dayKey] ?? byDate['default'];
    if (timings == null) throw Exception('missing fixture');
    return Map<String, String>.from(timings);
  }
}

void main() {
  const todayTimings = {
    'Fajr': '05:08',
    'Dhuhr': '13:22',
    'Asr': '16:58',
    'Maghrib': '20:11',
    'Isha': '21:28',
  };

  const tomorrowTimings = {
    'Fajr': '05:15',
    'Dhuhr': '13:23',
    'Asr': '16:59',
    'Maghrib': '20:10',
    'Isha': '21:27',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PrayerRepository.resetForTest();
  });

  tearDown(() {
    PrayerRepository.resetForTest();
  });

  group('PrayerMapper', () {
    test('désigne la prochaine prière du jour', () {
      final data = PrayerMapper.fromTimings(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        referenceTime: DateTime(2026, 7, 12, 14, 0),
      );

      expect(data.nextPrayerName, 'Asr');
      expect(data.nextPrayerCountdown, 'dans 2h 58m');
      expect(
        data.schedule.singleWhere((item) => item.name == 'Asr').isNext,
        isTrue,
      );
      expect(
        data.schedule.singleWhere((item) => item.name == 'Dhuhr').isCurrent,
        isTrue,
      );
    });

    test('après Isha utilise le Fajr de demain pour l\'horaire et le compte à rebours',
        () {
      final data = PrayerMapper.fromTimings(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        referenceTime: DateTime(2026, 7, 12, 22, 0),
      );

      expect(data.nextPrayerName, 'Fajr');
      // 22:00 → 05:15 = 7h 15m
      expect(data.nextPrayerCountdown, 'dans 7h 15m');
      expect(
        data.schedule.singleWhere((item) => item.name == 'Fajr').time,
        '05:15',
      );
      expect(
        data.schedule.singleWhere((item) => item.name == 'Fajr').isNext,
        isTrue,
      );
      expect(
        data.schedule.singleWhere((item) => item.name == 'Isha').isCurrent,
        isTrue,
      );
    });
  });

  group('PrayerRepository', () {
    test('succès réseau : snapshot live et cache durable', () async {
      final client = _FakeAladhanClient(
        byDate: {
          '2026-07-12': todayTimings,
          '2026-07-13': tomorrowTimings,
        },
      );
      final repository = PrayerRepository(client: client);
      final now = DateTime(2026, 7, 12, 10, 0);

      final snapshot = await repository.getPrayerTimes(
        latitude: 31.6295,
        longitude: -7.9811,
        referenceTime: now,
      );

      expect(snapshot.state, PrayerLoadState.success);
      expect(snapshot.data!.nextPrayerName, 'Dhuhr');
      expect(snapshot.data!.calculationMethod, PrayerMapper.liveCalculationMethod);

      final cached = await const PrayerTimingsCacheStore().load(
        latitude: 31.6295,
        longitude: -7.9811,
        date: DateTime(2026, 7, 12),
      );
      expect(cached?['Fajr'], '05:08');
    });

    test('échec sans cache : unavailable (pas de faux horaires)', () async {
      final repository = PrayerRepository(
        client: _FakeAladhanClient(fail: true),
      );

      final snapshot = await repository.getPrayerTimes(
        latitude: 33.5731,
        longitude: -7.5898,
        referenceTime: DateTime(2026, 7, 12, 10, 0),
      );

      expect(snapshot.state, PrayerLoadState.unavailable);
      expect(snapshot.data, isNull);
      expect(repository.buildForNow().state, PrayerLoadState.unavailable);
    });

    test('échec avec cache : stale et horaires enregistrés', () async {
      const store = PrayerTimingsCacheStore();
      await store.save(
        latitude: 34.0209,
        longitude: -6.8416,
        date: DateTime(2026, 7, 12),
        timings: todayTimings,
      );
      await store.save(
        latitude: 34.0209,
        longitude: -6.8416,
        date: DateTime(2026, 7, 13),
        timings: tomorrowTimings,
      );

      final repository = PrayerRepository(
        client: _FakeAladhanClient(fail: true),
        cacheStore: store,
      );

      final snapshot = await repository.getPrayerTimes(
        latitude: 34.0209,
        longitude: -6.8416,
        referenceTime: DateTime(2026, 7, 12, 22, 30),
      );

      expect(snapshot.state, PrayerLoadState.stale);
      expect(snapshot.data!.nextPrayerName, 'Fajr');
      expect(snapshot.data!.schedule.first.time, '05:15');
      expect(snapshot.statusLabel, 'Horaires enregistrés');
    });

    test('changement de ville refetch des horaires distincts', () async {
      final client = _FakeAladhanClient(
        byDate: {
          '2026-07-12': todayTimings,
          '2026-07-13': tomorrowTimings,
        },
      );
      final repository = PrayerRepository(client: client);
      final now = DateTime(2026, 7, 12, 10, 0);

      await repository.getPrayerTimes(
        latitude: 31.6295,
        longitude: -7.9811,
        referenceTime: now,
      );
      final firstCalls = client.calls.length;

      await repository.getPrayerTimes(
        latitude: 33.5731,
        longitude: -7.5898,
        referenceTime: now,
      );

      expect(client.calls.length, greaterThan(firstCalls));
      expect(
        client.calls.any((call) => call.contains('33.5731')),
        isTrue,
      );
    });

    test('buildForNow rafraîchit le compte à rebours depuis le cache mémoire',
        () async {
      final repository = PrayerRepository(
        client: _FakeAladhanClient(
          byDate: {
            '2026-07-12': todayTimings,
            '2026-07-13': tomorrowTimings,
          },
        ),
      );

      await repository.getPrayerTimes(
        latitude: 31.6295,
        longitude: -7.9811,
        referenceTime: DateTime(2026, 7, 12, 10, 0),
      );

      final later = repository.buildForNow(
        referenceTime: DateTime(2026, 7, 12, 16, 0),
      );
      expect(later.state, PrayerLoadState.success);
      expect(later.data!.nextPrayerName, 'Asr');
      expect(later.data!.nextPrayerCountdown, 'dans 58m');
    });

    test('getTimingsForDate retourne null sans API ni cache', () async {
      final repository = PrayerRepository(
        client: _FakeAladhanClient(fail: true),
      );
      final timings = await repository.getTimingsForDate(
        latitude: 31.6295,
        longitude: -7.9811,
        date: DateTime(2026, 7, 12),
      );
      expect(timings, isNull);
    });
  });
}
