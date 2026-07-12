import '../../domain/models/home_models.dart';

/// Convertit les horaires bruts en [PrayerTimeData] avec prochaine prière dynamique.
abstract final class PrayerMapper {
  static const prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static const liveCalculationMethod = 'AlAdhan · méthode Maroc';
  static const fallbackCalculationMethod = 'données estimées';

  /// Heure actuelle en Africa/Casablanca (UTC+1 permanent depuis 2018).
  static DateTime casablancaNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 1));
  }

  static PrayerTimeData fromTimings(
    Map<String, String> timings, {
    required String calculationMethod,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? casablancaNow();
    final nowMinutes = now.hour * 60 + now.minute;

    final parsed = <String, int>{
      for (final name in prayerNames)
        name: _parseTime(timings[name] ?? '00:00'),
    };

    final next = _resolveNextPrayer(parsed, nowMinutes);

    return PrayerTimeData(
      nextPrayerName: next.name,
      nextPrayerCountdown: _formatCountdown(next.minutesUntil),
      calculationMethod: calculationMethod,
      schedule: [
        for (final name in prayerNames)
          PrayerScheduleItem(
            name: name,
            time: timings[name] ?? '--:--',
            isCurrent: false,
            isNext: name == next.name,
          ),
      ],
    );
  }

  static ({String name, int minutesUntil}) _resolveNextPrayer(
    Map<String, int> parsed,
    int nowMinutes,
  ) {
    for (final name in prayerNames) {
      final prayerMinutes = parsed[name]!;
      if (prayerMinutes > nowMinutes) {
        return (name: name, minutesUntil: prayerMinutes - nowMinutes);
      }
    }

    // Après Isha : prochaine prière = Fajr du lendemain.
    final fajrMinutes = parsed['Fajr']!;
    return (
      name: 'Fajr',
      minutesUntil: (24 * 60 - nowMinutes) + fajrMinutes,
    );
  }

  static int _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _formatCountdown(int totalMinutes) {
    if (totalMinutes <= 0) {
      return 'maintenant';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return 'dans ${minutes}m';
    }
    if (minutes == 0) {
      return 'dans ${hours}h';
    }
    return 'dans ${hours}h ${minutes}m';
  }
}
