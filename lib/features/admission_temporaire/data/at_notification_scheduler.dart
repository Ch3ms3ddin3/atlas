import '../domain/models/at_vehicle.dart';
import '../../../core/notifications/notification_constants.dart';
import 'at_calculator.dart';

/// Notification AT à planifier.
class ScheduledAtNotification {
  const ScheduledAtNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.vehicleId,
    required this.daysBeforeExpiry,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String vehicleId;
  final int daysBeforeExpiry;
}

/// Logique pure : véhicules + opt-in → notifications futures.
class AtNotificationScheduler {
  const AtNotificationScheduler();

  /// Jours avant expiration : 30, 15, 7, 3, 1, 0 (jour J).
  static const reminderDaysBefore = <int>[30, 15, 7, 3, 1, 0];

  static const _notifyHour = 9;

  List<ScheduledAtNotification> build({
    required List<AtVehicle> vehicles,
    required bool notificationsEnabled,
    DateTime? now,
  }) {
    if (!notificationsEnabled) return const [];

    final reference = now ?? AtCalculator.casablancaNow();
    final results = <ScheduledAtNotification>[];

    for (final vehicle in vehicles.where((v) => v.isActive)) {
      for (var offsetIndex = 0;
          offsetIndex < reminderDaysBefore.length;
          offsetIndex++) {
        final daysBefore = reminderDaysBefore[offsetIndex];
        final notifyDay = AtCalculator.calendarDay(vehicle.expiryDate)
            .subtract(Duration(days: daysBefore));
        final scheduledAt = DateTime(
          notifyDay.year,
          notifyDay.month,
          notifyDay.day,
          _notifyHour,
        );
        if (!scheduledAt.isAfter(reference)) continue;

        final id = NotificationConstants.atNotificationIdStart +
            (vehicle.notificationSlot.clamp(0, 99) * 10) +
            offsetIndex;
        if (id < NotificationConstants.atNotificationIdStart ||
            id > NotificationConstants.atNotificationIdEnd) {
          continue;
        }

        results.add(
          ScheduledAtNotification(
            id: id,
            title: 'Mes véhicules au Maroc',
            body: _body(vehicle, daysBefore),
            scheduledAt: scheduledAt,
            vehicleId: vehicle.id,
            daysBeforeExpiry: daysBefore,
          ),
        );
      }
    }

    return results;
  }

  String _body(AtVehicle vehicle, int daysBefore) {
    final identity = vehicle.plate.isNotEmpty
        ? '${vehicle.label} (${vehicle.plate})'
        : vehicle.label;
    if (daysBefore == 0) {
      return 'L\'admission temporaire de $identity expire aujourd\'hui.';
    }
    if (daysBefore == 1) {
      return 'L\'admission temporaire de $identity expire demain.';
    }
    return 'L\'admission temporaire de $identity expire dans $daysBefore jours.';
  }
}
