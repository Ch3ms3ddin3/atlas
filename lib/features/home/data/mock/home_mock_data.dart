import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

/// Données fictives pour le tableau de bord — remplacées par les APIs plus tard.
abstract final class HomeMockData {
  static const greeting = GreetingData(
    userName: 'Chemseddine',
    city: 'Marrakech',
    dateLabel: 'Dimanche 12 juillet 2026',
  );

  static const weather = WeatherData(
    temperature: 38,
    condition: 'Très ensoleillé',
    feelsLike: 41,
    icon: Icons.wb_sunny_outlined,
    updatedAt: 'il y a 5 min',
  );

  static const prayerTime = PrayerTimeData(
    nextPrayerName: 'Asr',
    nextPrayerCountdown: 'dans 2h 14m',
    calculationMethod: 'Ministère des Habous',
    schedule: [
      PrayerScheduleItem(name: 'Fajr', time: '05:08', isCurrent: false, isNext: false),
      PrayerScheduleItem(name: 'Dhuhr', time: '13:22', isCurrent: false, isNext: false),
      PrayerScheduleItem(name: 'Asr', time: '16:58', isCurrent: false, isNext: true),
      PrayerScheduleItem(name: 'Maghrib', time: '20:11', isCurrent: false, isNext: false),
      PrayerScheduleItem(name: 'Isha', time: '21:28', isCurrent: false, isNext: false),
    ],
  );

  static const exchangeRate = ExchangeRateData(
    fromCurrency: 'EUR',
    toCurrency: 'MAD',
    rate: 10.78,
    trendLabel: '+0.1 % sur 7 jours',
    isTrendingUp: true,
    updatedAt: 'il y a 8 min',
  );

  static const holidayStatus = HolidayStatusData(
    isHoliday: false,
    label: 'Jour ouvré',
    detail: 'Administrations et banques ouvertes aux horaires habituels.',
    icon: Icons.event_available_outlined,
  );

  static const todayEssentials = TodayEssentialsData(
    alert: AlertData(
      id: 'alert-heat',
      title: 'Forte chaleur prévue',
      detail: '38 °C cet après-midi à Marrakech — hydratez-vous et évitez les sorties entre 12h et 16h.',
      source: 'Atlas Météo',
      severity: AlertSeverity.caution,
      icon: Icons.wb_sunny_outlined,
    ),
    tip: DailyInfoData(
      category: 'Conseil local',
      content:
          'Visitez la Médina tôt le matin (avant 10h) pour éviter la foule '
          'et profiter des températures plus clémentes.',
      icon: Icons.lightbulb_outline,
    ),
    adminReminder: AdminReminderData(
      id: 'admin-cin',
      title: 'Renouveler la CIN',
      statusLabel: 'Dans 18 jours',
      status: AdminReminderStatus.dueSoon,
      progressLabel: 'Rendez-vous à prendre à la commune de Gueliz',
      progress: null,
    ),
  );

  static const quickActions = <QuickActionData>[
    QuickActionData(id: 'emergency', label: 'Urgences', icon: Icons.emergency_outlined),
    QuickActionData(id: 'hospitals', label: 'Hôpitaux', icon: Icons.local_hospital_outlined),
    QuickActionData(id: 'restaurants', label: 'Restaurants', icon: Icons.restaurant_outlined),
    QuickActionData(id: 'padel', label: 'Padel', icon: Icons.sports_tennis_outlined),
    QuickActionData(id: 'fuel', label: 'Carburant', icon: Icons.local_gas_station_outlined),
    QuickActionData(id: 'parking', label: 'Parking', icon: Icons.local_parking_outlined),
  ];

  static const admissionTemporaire = AdmissionTemporaireData(
    title: 'Admission temporaire',
    daysRemaining: 42,
    totalDays: 90,
    expiryLabel: 'Expire le 23 août 2026',
  );

  static const recommendedPlaces = <RecommendedPlaceData>[
    RecommendedPlaceData(
      id: 'place-majorelle',
      name: 'Jardin Majorelle',
      category: 'Jardin',
      distanceLabel: '12 min · Gueliz',
      priceLevel: '€€€',
      isEditorsPick: true,
      imageColor: Color(0xFF2D6A4F),
    ),
    RecommendedPlaceData(
      id: 'place-bahia',
      name: 'Palais de la Bahia',
      category: 'Monument',
      distanceLabel: '18 min · Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFFC4654A),
    ),
  ];

  static const lastUpdated = 'Toutes les données mises à jour il y a 5 min';
}
