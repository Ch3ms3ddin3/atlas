import '../../domain/models/home_models.dart';

/// Convertit la réponse Frankfurter en [ExchangeRateData] affichable.
abstract final class ExchangeRateMapper {
  static const liveSourceLabel = 'Frankfurter · taux de référence';

  static ExchangeRateData fromFrankfurter(Map<String, dynamic> json) {
    final rate = json['rate'];
    final date = json['date'] as String? ?? '';

    return ExchangeRateData(
      fromCurrency: 'EUR',
      toCurrency: 'MAD',
      rate: rate is num ? rate.toDouble() : 0,
      trendLabel: liveSourceLabel,
      isTrendingUp: true,
      updatedAt: date,
    );
  }
}
