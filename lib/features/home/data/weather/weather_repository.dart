import '../mock/home_mock_data.dart';
import '../../domain/models/home_models.dart';
import 'open_meteo_client.dart';

/// Orchestre la récupération météo et le repli sur les données fictives.
class WeatherRepository {
  WeatherRepository({OpenMeteoClient? client})
      : _client = client ?? const OpenMeteoClient();

  final OpenMeteoClient _client;

  /// Tente l'API ; en cas d'échec, renvoie le mock avec un libellé explicite.
  Future<WeatherData> getWeather() async {
    try {
      return await _client.fetchCurrentWeather();
    } catch (_) {
      return _fallbackWeather();
    }
  }

  WeatherData _fallbackWeather() {
    const mock = HomeMockData.weather;
    return WeatherData(
      temperature: mock.temperature,
      condition: mock.condition,
      feelsLike: mock.feelsLike,
      icon: mock.icon,
      updatedAt: 'données estimées',
    );
  }
}
