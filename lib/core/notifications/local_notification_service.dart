import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/home/data/prayer/prayer_notification_scheduler.dart';
import 'notification_constants.dart';

/// Encapsule flutter_local_notifications — init, permissions, planification.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        description: NotificationConstants.channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> requestExactAlarmsIfNeeded() async {
    if (kIsWeb) return;

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final canSchedule = await android.canScheduleExactNotifications();
    if (canSchedule == false) {
      await android.requestExactAlarmsPermission();
    }
  }

  Future<void> cancelPrayerNotifications() async {
    if (kIsWeb || !_initialized) return;

    for (
      var id = NotificationConstants.prayerNotificationIdStart;
      id <= NotificationConstants.prayerNotificationIdEnd;
      id++
    ) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> schedule(ScheduledPrayerNotification notification) async {
    if (kIsWeb || !_initialized) return;

    final scheduledDate = tz.TZDateTime(
      tz.getLocation('Africa/Casablanca'),
      notification.scheduledAt.year,
      notification.scheduledAt.month,
      notification.scheduledAt.day,
      notification.scheduledAt.hour,
      notification.scheduledAt.minute,
    );

    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationConstants.channelId,
          NotificationConstants.channelName,
          channelDescription: NotificationConstants.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
