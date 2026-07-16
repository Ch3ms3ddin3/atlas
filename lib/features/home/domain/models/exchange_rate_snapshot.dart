import '../../domain/models/home_models.dart';

/// État d'affichage du taux de change sur l'accueil.
enum ExchangeRateLoadState {
  loading,
  success,
  stale,
  unavailable,
}

/// Snapshot FX — jamais de taux inventé.
class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.state,
    this.data,
  });

  const ExchangeRateSnapshot.loading()
      : state = ExchangeRateLoadState.loading,
        data = null;

  const ExchangeRateSnapshot.unavailable()
      : state = ExchangeRateLoadState.unavailable,
        data = null;

  final ExchangeRateLoadState state;
  final ExchangeRateData? data;

  bool get hasRate => data != null && data!.rate > 0;

  String get statusLabel => switch (state) {
        ExchangeRateLoadState.loading => 'Chargement du taux…',
        ExchangeRateLoadState.success =>
          data?.sourceLabel ?? 'Frankfurter · taux de référence',
        ExchangeRateLoadState.stale => 'Taux enregistré',
        ExchangeRateLoadState.unavailable => 'Taux indisponible',
      };
}
