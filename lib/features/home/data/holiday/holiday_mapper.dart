import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';
import 'holiday_entry.dart';

/// Convertit les jours fériés bruts en [HolidayStatusData] pour aujourd'hui.
abstract final class HolidayMapper {
  static const workingDayDetail =
      'Administrations et banques ouvertes aux horaires habituels.';
  static const holidayDetail =
      'Administrations et banques fermées.';
  static const islamicHolidayDetail =
      'Administrations et banques fermées. Date estimée — confirmation officielle possible.';
  static const fallbackDetail = 'données estimées';

  /// Heure actuelle en Africa/Casablanca (UTC+1 permanent depuis 2018).
  static DateTime casablancaNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 1));
  }

  static List<HolidayEntry> mergeHolidayLists(
    List<HolidayEntry> fixedHolidays,
    List<HolidayEntry> islamicHolidays,
  ) {
    final byDate = <String, HolidayEntry>{};

    for (final holiday in fixedHolidays) {
      byDate[_dateKey(holiday.date)] = holiday;
    }
    for (final holiday in islamicHolidays) {
      byDate.putIfAbsent(_dateKey(holiday.date), () => holiday);
    }

    final merged = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  static HolidayStatusData forToday(
    List<HolidayEntry> holidays, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? casablancaNow();
    final todayKey = _dateKey(now);

    for (final holiday in holidays) {
      if (_dateKey(holiday.date) == todayKey) {
        return HolidayStatusData(
          isHoliday: true,
          label: holiday.name,
          detail: holiday.isIslamicEstimated
              ? islamicHolidayDetail
              : holidayDetail,
          icon: Icons.event_outlined,
        );
      }
    }

    return const HolidayStatusData(
      isHoliday: false,
      label: 'Jour ouvré',
      detail: workingDayDetail,
      icon: Icons.event_available_outlined,
    );
  }

  static String frenchNameForNagerHoliday(String englishName) {
    return switch (englishName) {
      'New Year\'s Day' => 'Jour de l\'an',
      'Proclamation of Independence' => 'Manifeste de l\'indépendance',
      'Amazigh New Year' => 'Yennayer',
      'Labour Day' => 'Fête du travail',
      'Enthronement' => 'Fête du Trône',
      'Zikra Oued Ed-Dahab' => 'Fête de Oued Ed-Dahab',
      'Revolution of the King and the People' =>
        'Révolution du Roi et du Peuple',
      'Youth Day' => 'Fête de la Jeunesse',
      'Green March' => 'Marche Verte',
      'Independence Day' => 'Fête de l\'Indépendance',
      _ => englishName,
    };
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
