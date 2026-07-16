import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/home_models.dart';
import 'exchange_rate_cache_store.dart';
import 'frankfurter_client.dart';

/// Orchestre Frankfurter + cache durable — jamais de taux inventé.
class ExchangeRateRepository {
  ExchangeRateRepository({
    FrankfurterClient? client,
    ExchangeRateCacheStore? cacheStore,
  })  : _client = client ?? const FrankfurterClient(),
        _cacheStore = cacheStore ?? const ExchangeRateCacheStore();

  final FrankfurterClient _client;
  final ExchangeRateCacheStore _cacheStore;

  ExchangeRateData? _memory;
  ExchangeRateLoadState _memoryState = ExchangeRateLoadState.unavailable;

  /// Charge le taux live ; en échec, sert le dernier taux valide ou unavailable.
  Future<ExchangeRateSnapshot> getExchangeRate() async {
    try {
      final live = await _client.fetchEurMadRate();
      final stamped = ExchangeRateData(
        fromCurrency: live.fromCurrency,
        toCurrency: live.toCurrency,
        rate: live.rate,
        sourceLabel: live.sourceLabel,
        referenceDate: live.referenceDate,
        fetchedAt: live.fetchedAt ?? DateTime.now(),
      );
      await _cacheStore.save(stamped);
      _memory = stamped;
      _memoryState = ExchangeRateLoadState.success;
      return ExchangeRateSnapshot(
        state: ExchangeRateLoadState.success,
        data: stamped,
      );
    } catch (_) {
      return _snapshotFromCache();
    }
  }

  Future<ExchangeRateSnapshot> _snapshotFromCache() async {
    final cached = await _cacheStore.load() ?? _memory;
    if (cached == null || cached.rate <= 0) {
      _memory = null;
      _memoryState = ExchangeRateLoadState.unavailable;
      return const ExchangeRateSnapshot.unavailable();
    }

    final stale = ExchangeRateData(
      fromCurrency: cached.fromCurrency,
      toCurrency: cached.toCurrency,
      rate: cached.rate,
      sourceLabel: cached.sourceLabel,
      referenceDate: cached.referenceDate,
      fetchedAt: cached.fetchedAt,
    );
    _memory = stale;
    _memoryState = ExchangeRateLoadState.stale;
    return ExchangeRateSnapshot(
      state: ExchangeRateLoadState.stale,
      data: stale,
    );
  }

  /// Dernier snapshot mémoire (après un chargement réussi ou stale).
  ExchangeRateSnapshot currentSnapshot() {
    final data = _memory;
    if (data == null || data.rate <= 0) {
      return const ExchangeRateSnapshot.unavailable();
    }
    return ExchangeRateSnapshot(state: _memoryState, data: data);
  }
}
