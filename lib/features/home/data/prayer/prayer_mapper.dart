import '../../domain/models/home_models.dart';

/// Convertit les horaires bruts en [PrayerTimeData] avec prochaine prière dynamique.
abstract final class PrayerMapper {
  static const prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static const liveCalculationMethod = 'AlAdhan · méthode Maroc';

  /// Heure actuelle en Africa/Casablanca (UTC+1 permanent depuis 2018).
  static DateTime casablancaNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 1));
  }

  /// Construit l'affichage du jour.
  ///
  /// Après Isha, [tomorrowTimings] doit fournir le vrai Fajr du lendemain —
  /// le compte à rebours et la cellule Fajr utilisent cette heure.
  static PrayerTimeData fromTimings({
    required Map<String, String> todayTimings,
    Map<String, String>? tomorrowTimings,
    String calculationMethod = liveCalculationMethod,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? casablancaNow();
    final nowMinutes = now.hour * 60 + now.minute;

    final todayParsed = <String, int>{
      for (final name in prayerNames)
        name: _parseTime(todayTimings[name] ?? '00:00'),
    };

    final next = _resolveNextPrayer(
      todayParsed: todayParsed,
      tomorrowTimings: tomorrowTimings,
      nowMinutes: nowMinutes,
    );

    final displayTimings = Map<String, String>.from(todayTimings);
    if (next.usesTomorrowFajr && tomorrowTimings != null) {
      final tomorrowFajr = tomorrowTimings['Fajr'];
      if (tomorrowFajr != null && tomorrowFajr.isNotEmpty) {
        displayTimings['Fajr'] = tomorrowFajr;
      }
    }

    final currentName = _resolveCurrentPrayer(todayParsed, nowMinutes);

    return PrayerTimeData(
      nextPrayerName: next.name,
      nextPrayerCountdown: _formatCountdown(next.minutesUntil),
      calculationMethod: calculationMethod,
      schedule: [
        for (final name in prayerNames)
          PrayerScheduleItem(
            name: name,
            time: displayTimings[name] ?? '--:--',
            isCurrent: name == currentName,
            isNext: name == next.name,
          ),
      ],
    );
  }

  static ({String name, int minutesUntil, bool usesTomorrowFajr})
      _resolveNextPrayer({
    required Map<String, int> todayParsed,
    required Map<String, String>? tomorrowTimings,
    required int nowMinutes,
  }) {
    for (final name in prayerNames) {
      final prayerMinutes = todayParsed[name]!;
      if (prayerMinutes > nowMinutes) {
        return (
          name: name,
          minutesUntil: prayerMinutes - nowMinutes,
          usesTomorrowFajr: false,
        );
      }
    }

    // Après Isha : Fajr du lendemain (horaires réels requis).
    final tomorrowFajrRaw = tomorrowTimings?['Fajr'];
    final tomorrowFajrMinutes = tomorrowFajrRaw == null || tomorrowFajrRaw.isEmpty
        ? todayParsed['Fajr']!
        : _parseTime(tomorrowFajrRaw);

    return (
      name: 'Fajr',
      minutesUntil: (24 * 60 - nowMinutes) + tomorrowFajrMinutes,
      usesTomorrowFajr: true,
    );
  }

  /// Dernière prière déjà commencée (fenêtre jusqu'à la suivante).
  static String? _resolveCurrentPrayer(
    Map<String, int> parsed,
    int nowMinutes,
  ) {
    String? current;
    for (final name in prayerNames) {
      if (parsed[name]! <= nowMinutes) {
        current = name;
      }
    }
    return current;
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
