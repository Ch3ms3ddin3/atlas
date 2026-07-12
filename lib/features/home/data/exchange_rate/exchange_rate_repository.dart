import '../mock/home_mock_data.dart';
import '../../domain/models/home_models.dart';
import 'frankfurter_client.dart';

/// Orchestre la récupération du taux de change et le repli sur les mocks.
class ExchangeRateRepository {
  ExchangeRateRepository({FrankfurterClient? client})
      : _client = client ?? const FrankfurterClient();

  final FrankfurterClient _client;

  /// Tente l'API ; en cas d'échec, renvoie le mock avec un libellé explicite.
  Future<ExchangeRateData> getExchangeRate() async {
    try {
      return await _client.fetchEurMadRate();
    } catch (_) {
      return _fallbackExchangeRate();
    }
  }

  ExchangeRateData _fallbackExchangeRate() {
    const mock = HomeMockData.exchangeRate;
    return ExchangeRateData(
      fromCurrency: mock.fromCurrency,
      toCurrency: mock.toCurrency,
      rate: mock.rate,
      trendLabel: 'données estimées',
      isTrendingUp: mock.isTrendingUp,
      updatedAt: mock.updatedAt,
    );
  }
}
