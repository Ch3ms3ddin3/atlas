import '../../../../core/notifications/notification_constants.dart';
import '../../../../core/notifications/prayer_notification_lead_time.dart';

/// Notification de prière à planifier.
class ScheduledPrayerNotification {
  const ScheduledPrayerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.prayerName,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String prayerName;
}

/// Logique pure : horaires + préférence → notifications futures.
class PrayerNotificationScheduler {
  const PrayerNotificationScheduler();

  static const _todayIds = {
    'Fajr': 1,
    'Dhuhr': 2,
    'Asr': 3,
    'Maghrib': 4,
    'Isha': 5,
  };

  static const _tomorrowIds = {
    'Fajr': 6,
    'Dhuhr': 7,
    'Asr': 8,
    'Maghrib': 9,
    'Isha': 10,
  };

  List<ScheduledPrayerNotification> build({
    required Map<String, String> todayTimings,
    required Map<String, String> tomorrowTimings,
    required PrayerNotificationLeadTime leadTime,
    required DateTime now,
  }) {
    if (leadTime == PrayerNotificationLeadTime.disabled) {
      return const [];
    }

    final results = <ScheduledPrayerNotification>[];
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final entry in _todayIds.entries) {
      _addIfFuture(
        results: results,
        prayerName: entry.key,
        day: today,
        time: todayTimings[entry.key] ?? '00:00',
        notificationId: entry.value,
        leadTime: leadTime,
        now: now,
      );
    }

    for (final entry in _tomorrowIds.entries) {
      _addIfFuture(
        results: results,
        prayerName: entry.key,
        day: tomorrow,
        time: tomorrowTimings[entry.key] ?? '00:00',
        notificationId: entry.value,
        leadTime: leadTime,
        now: now,
      );
    }

    return results;
  }

  void _addIfFuture({
    required List<ScheduledPrayerNotification> results,
    required String prayerName,
    required DateTime day,
    required String time,
    required int notificationId,
    required PrayerNotificationLeadTime leadTime,
    required DateTime now,
  }) {
    if (notificationId < NotificationConstants.prayerNotificationIdStart ||
        notificationId > NotificationConstants.prayerNotificationIdEnd) {
      return;
    }

    final prayerAt = _prayerDateTime(day, time);
    final notifyAt = prayerAt.subtract(Duration(minutes: leadTime.offsetMinutes));
    if (!notifyAt.isAfter(now)) return;

    results.add(
      ScheduledPrayerNotification(
        id: notificationId,
        title: 'Prière — $prayerName',
        body: _buildBody(prayerName, leadTime),
        scheduledAt: notifyAt,
        prayerName: prayerName,
      ),
    );
  }

  DateTime _prayerDateTime(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) {
      return DateTime(day.year, day.month, day.day);
    }
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _buildBody(String prayerName, PrayerNotificationLeadTime leadTime) {
    return switch (leadTime) {
      PrayerNotificationLeadTime.atPrayerTime =>
        'C\'est l\'heure de $prayerName',
      PrayerNotificationLeadTime.fiveMinutesBefore =>
        'Dans 5 minutes : $prayerName',
      PrayerNotificationLeadTime.tenMinutesBefore =>
        'Dans 10 minutes : $prayerName',
      PrayerNotificationLeadTime.disabled => '',
    };
  }
}
