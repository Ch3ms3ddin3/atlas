import 'package:flutter/material.dart';

/// Données affichées dans l'en-tête d'accueil.
class GreetingData {
  const GreetingData({
    required this.userName,
    required this.city,
    required this.dateLabel,
  });

  final String userName;
  final String city;
  final String dateLabel;
}

/// Statut jour férié ou jour ouvré.
class HolidayStatusData {
  const HolidayStatusData({
    required this.isHoliday,
    required this.label,
    required this.detail,
    required this.icon,
  });

  final bool isHoliday;
  final String label;
  final String detail;
  final IconData icon;
}

/// Suivi de l'admission temporaire du véhicule.
class AdmissionTemporaireData {
  const AdmissionTemporaireData({
    required this.title,
    required this.daysRemaining,
    required this.totalDays,
    required this.expiryLabel,
  });

  final String title;
  final int daysRemaining;
  final int totalDays;
  final String expiryLabel;
}

/// Contenu de la section « À savoir aujourd'hui ».
class TodayEssentialsData {
  const TodayEssentialsData({
    required this.alert,
    required this.tip,
    required this.adminReminder,
  });

  final AlertData alert;
  final DailyInfoData tip;
  final AdminReminderData adminReminder;
}

/// Données météo pour la carte du jour.
class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.feelsLike,
    required this.icon,
    required this.updatedAt,
  });

  final int temperature;
  final String condition;
  final int feelsLike;
  final IconData icon;
  final String updatedAt;
}

/// Horaire d'une prière.
class PrayerScheduleItem {
  const PrayerScheduleItem({
    required this.name,
    required this.time,
    required this.isCurrent,
    required this.isNext,
  });

  final String name;
  final String time;
  final bool isCurrent;
  final bool isNext;
}

/// Données des horaires de prière.
class PrayerTimeData {
  const PrayerTimeData({
    required this.nextPrayerName,
    required this.nextPrayerCountdown,
    required this.schedule,
    required this.calculationMethod,
  });

  final String nextPrayerName;
  final String nextPrayerCountdown;
  final List<PrayerScheduleItem> schedule;
  final String calculationMethod;
}

/// Données de taux de change.
class ExchangeRateData {
  const ExchangeRateData({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.trendLabel,
    required this.isTrendingUp,
    required this.updatedAt,
  });

  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final String trendLabel;
  final bool isTrendingUp;
  final String updatedAt;
}

/// Niveau de sévérité d'une alerte.
enum AlertSeverity { info, caution, critical }

/// Alerte importante affichée sur l'accueil.
class AlertData {
  const AlertData({
    required this.id,
    required this.title,
    required this.detail,
    required this.source,
    required this.severity,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final String source;
  final AlertSeverity severity;
  final IconData icon;
}

/// Action rapide accessible depuis l'accueil.
class QuickActionData {
  const QuickActionData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Statut d'un rappel administratif.
enum AdminReminderStatus { dueSoon, inProgress, actionNeeded }

/// Rappel administratif à suivre.
class AdminReminderData {
  const AdminReminderData({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.status,
    required this.progressLabel,
    required this.progress,
  });

  final String id;
  final String title;
  final String statusLabel;
  final AdminReminderStatus status;
  final String progressLabel;
  final double? progress;
}

/// Lieu recommandé près de l'utilisateur.
class RecommendedPlaceData {
  const RecommendedPlaceData({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceLabel,
    required this.priceLevel,
    required this.isEditorsPick,
    required this.imageColor,
  });

  final String id;
  final String name;
  final String category;
  final String distanceLabel;
  final String priceLevel;
  final bool isEditorsPick;
  final Color imageColor;
}

/// Information utile du jour.
class DailyInfoData {
  const DailyInfoData({
    required this.category,
    required this.content,
    required this.icon,
  });

  final String category;
  final String content;
  final IconData icon;
}
