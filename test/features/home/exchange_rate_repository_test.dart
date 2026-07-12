import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/exchange_rate/exchange_rate_mapper.dart';
import 'package:atlas/features/home/data/exchange_rate/exchange_rate_repository.dart';
import 'package:atlas/features/home/data/exchange_rate/frankfurter_client.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';

void main() {
  group('ExchangeRateMapper', () {
    test('mappe une réponse Frankfurter valide', () {
      final rate = ExchangeRateMapper.fromFrankfurter({
        'date': '2026-07-10',
        'base': 'EUR',
        'quote': 'MAD',
        'rate': 10.6998,
      });

      expect(rate.fromCurrency, 'EUR');
      expect(rate.toCurrency, 'MAD');
      expect(rate.rate, 10.6998);
      expect(rate.trendLabel, 'Frankfurter · taux de référence');
      expect(rate.isTrendingUp, isTrue);
      expect(rate.updatedAt, '2026-07-10');
    });
  });

  group('ExchangeRateRepository', () {
    test('retombe sur le mock si l\'API échoue', () async {
      final repository = ExchangeRateRepository(
        client: _FailingFrankfurterClient(),
      );

      final rate = await repository.getExchangeRate();

      expect(rate.fromCurrency, 'EUR');
      expect(rate.toCurrency, 'MAD');
      expect(rate.rate, 10.78);
      expect(rate.trendLabel, 'données estimées');
      expect(rate.isTrendingUp, isTrue);
    });
  });
}

class _FailingFrankfurterClient extends FrankfurterClient {
  @override
  Future<ExchangeRateData> fetchEurMadRate() async {
    throw Exception('network error');
  }
}
