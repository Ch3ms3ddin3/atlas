import '../../domain/models/home_models.dart';

/// État d'affichage de la météo sur l'accueil.
enum WeatherLoadState {
  loading,
  success,
  stale,
  unavailable,
}

/// Snapshot météo — jamais de valeurs inventées.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.state,
    this.data,
  });

  const WeatherSnapshot.loading()
      : state = WeatherLoadState.loading,
        data = null;

  const WeatherSnapshot.unavailable()
      : state = WeatherLoadState.unavailable,
        data = null;

  final WeatherLoadState state;
  final WeatherData? data;

  bool get hasWeather => data != null;

  String get statusLabel => switch (state) {
        WeatherLoadState.loading => 'Chargement de la météo…',
        WeatherLoadState.success => 'Open-Meteo',
        WeatherLoadState.stale => 'Météo enregistrée',
        WeatherLoadState.unavailable => 'Météo indisponible',
      };
}
