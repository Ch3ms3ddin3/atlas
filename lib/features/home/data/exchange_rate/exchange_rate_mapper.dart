import '../../domain/models/home_models.dart';

/// Convertit la réponse Frankfurter en [ExchangeRateData] affichable.
abstract final class ExchangeRateMapper {
  static const liveSourceLabel = 'Frankfurter · taux de référence';

  static ExchangeRateData fromFrankfurter(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final rate = json['rate'];
    final parsed = rate is num ? rate.toDouble() : double.tryParse('$rate');
    if (parsed == null || parsed <= 0) {
      throw FormatException('Taux Frankfurter invalide: $json');
    }

    return ExchangeRateData(
      fromCurrency: 'EUR',
      toCurrency: 'MAD',
      rate: parsed,
      sourceLabel: liveSourceLabel,
      referenceDate: json['date'] as String? ?? '',
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }
}
