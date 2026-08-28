import '../../domain/models/home_models.dart';

/// État d'affichage des horaires de prière sur l'accueil.
enum PrayerLoadState {
  /// Chargement initial sans cache affiché.
  loading,

  /// Horaires live AlAdhan pour la position réelle ou la ville choisie.
  success,

  /// Derniers horaires valides servis hors ligne.
  stale,

  /// Aucune donnée live ni cache — pas d'horaires inventés.
  unavailable,

  /// Mode auto sans GPS : pas d'horaires Marrakech présentés comme locaux.
  needsLocation,
}

/// Snapshot prêt pour l'UI Home (jamais de faux horaires).
class PrayerTimesSnapshot {
  const PrayerTimesSnapshot({required this.state, this.data});

  const PrayerTimesSnapshot.loading()
    : state = PrayerLoadState.loading,
      data = null;

  const PrayerTimesSnapshot.unavailable()
    : state = PrayerLoadState.unavailable,
      data = null;

  const PrayerTimesSnapshot.needsLocation()
    : state = PrayerLoadState.needsLocation,
      data = null;

  final PrayerLoadState state;
  final PrayerTimeData? data;

  bool get hasSchedule => data != null && data!.schedule.isNotEmpty;

  String get statusLabel => switch (state) {
    PrayerLoadState.loading => 'Chargement des horaires…',
    PrayerLoadState.success => data?.calculationMethod ?? '',
    PrayerLoadState.stale => 'Horaires enregistrés',
    PrayerLoadState.unavailable => 'Horaires indisponibles',
    PrayerLoadState.needsLocation =>
      'Localisation requise pour les horaires locaux',
  };
}
