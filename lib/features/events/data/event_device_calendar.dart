import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/atlas_event.dart';

/// Ajout au calendrier de l'appareil — masqué sur web / plateformes non supportées.
abstract final class EventDeviceCalendar {
  static bool get isSupported => !kIsWeb;

  static Future<bool> add(AtlasEvent event) async {
    if (!isSupported) return false;

    final start = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
    );
    final endDay = DateTime(
      event.effectiveEnd.year,
      event.effectiveEnd.month,
      event.effectiveEnd.day,
    );
    // Pour les journées entières, beaucoup de calendriers attendent une fin exclusive.
    final end = event.isAllDay
        ? endDay.add(const Duration(days: 1))
        : endDay;

    final calendarEvent = Event(
      title: event.title,
      description: '${event.description}\n\nSource : ${event.source}',
      location: event.cityName ?? 'Maroc',
      startDate: start,
      endDate: end,
      allDay: event.isAllDay,
    );

    return Add2Calendar.addEvent2Cal(calendarEvent);
  }
}
