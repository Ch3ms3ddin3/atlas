import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/home/data/exchange_rate/exchange_rate_cache_store.dart';
import 'package:atlas/features/home/data/exchange_rate/exchange_rate_mapper.dart';
import 'package:atlas/features/home/data/exchange_rate/exchange_rate_repository.dart';
import 'package:atlas/features/home/data/exchange_rate/frankfurter_client.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';

class _FakeFrankfurterClient extends FrankfurterClient {
  _FakeFrankfurterClient({
    this.fail = false,
    this.rate = 10.6998,
  });

  bool fail;
  double rate;
  var callCount = 0;

  @override
  Future<ExchangeRateData> fetchEurMadRate() async {
    callCount += 1;
    if (fail) throw Exception('network error');
    return ExchangeRateMapper.fromFrankfurter({
      'date': '2026-07-10',
      'base': 'EUR',
      'quote': 'MAD',
      'rate': rate,
    });
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
      expect(rate.sourceLabel, ExchangeRateMapper.liveSourceLabel);
      expect(rate.referenceDate, '2026-07-10');
      expect(rate.madToEur, closeTo(1 / 10.6998, 0.0000001));
    });

    test('refuse un taux invalide', () {
      expect(
        () => ExchangeRateMapper.fromFrankfurter({'rate': 0, 'date': '2026-07-10'}),
        throwsFormatException,
      );
    });
  });

  group('ExchangeRateRepository', () {
    test('succès live : snapshot success et conversion inverse', () async {
      final client = _FakeFrankfurterClient(rate: 10.5);
      final repository = ExchangeRateRepository(client: client);

      final snapshot = await repository.getExchangeRate();

      expect(snapshot.state, ExchangeRateLoadState.success);
      expect(snapshot.data!.rate, 10.5);
      expect(snapshot.data!.madToEur, closeTo(1 / 10.5, 0.0000001));
      expect(snapshot.statusLabel, ExchangeRateMapper.liveSourceLabel);
      expect(snapshot.data!.fetchedAt, isNotNull);
    });

    test('échec sans cache : unavailable (pas de taux inventé)', () async {
      final repository = ExchangeRateRepository(
        client: _FakeFrankfurterClient(fail: true),
      );

      final snapshot = await repository.getExchangeRate();

      expect(snapshot.state, ExchangeRateLoadState.unavailable);
      expect(snapshot.data, isNull);
      expect(snapshot.hasRate, isFalse);
    });

    test('échec avec cache : stale et taux enregistré', () async {
      const store = ExchangeRateCacheStore();
      await store.save(
        ExchangeRateData(
          fromCurrency: 'EUR',
          toCurrency: 'MAD',
          rate: 10.42,
          sourceLabel: ExchangeRateMapper.liveSourceLabel,
          referenceDate: '2026-07-09',
          fetchedAt: DateTime(2026, 7, 9, 12),
        ),
      );

      final repository = ExchangeRateRepository(
        client: _FakeFrankfurterClient(fail: true),
        cacheStore: store,
      );

      final snapshot = await repository.getExchangeRate();

      expect(snapshot.state, ExchangeRateLoadState.stale);
      expect(snapshot.data!.rate, 10.42);
      expect(snapshot.data!.madToEur, closeTo(1 / 10.42, 0.0000001));
      expect(snapshot.statusLabel, 'Taux enregistré');
    });

    test('rafraîchissement manuel refetch le réseau', () async {
      final client = _FakeFrankfurterClient(rate: 10.1);
      final repository = ExchangeRateRepository(client: client);

      await repository.getExchangeRate();
      expect(client.callCount, 1);

      client.rate = 10.3;
      final refreshed = await repository.getExchangeRate();

      expect(client.callCount, 2);
      expect(refreshed.data!.rate, 10.3);
      expect(refreshed.state, ExchangeRateLoadState.success);
    });
  });
}
