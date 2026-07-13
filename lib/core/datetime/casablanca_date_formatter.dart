/// Formate les dates en français pour le fuseau Africa/Casablanca.
abstract final class CasablancaDateFormatter {
  static const _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static const _monthsShort = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  /// Ex. « 12 juil. 2026 ».
  static String formatShortDate(DateTime date) {
    final month = _monthsShort[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// Ex. « Dimanche 12 juillet 2026 ».
  static String formatLongDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday ${date.day} $month ${date.year}';
  }
}
