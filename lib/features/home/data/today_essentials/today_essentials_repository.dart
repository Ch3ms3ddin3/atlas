import '../../domain/models/home_models.dart';
import 'today_essentials_mapper.dart';

/// Orchestre la construction de « À savoir aujourd'hui ».
class TodayEssentialsRepository {
  const TodayEssentialsRepository();

  TodayEssentialsData build({
    required WeatherData weather,
    required HolidayStatusData holidayStatus,
    required String cityName,
  }) {
    return TodayEssentialsMapper.fromContext(
      weather: weather,
      holidayStatus: holidayStatus,
      cityName: cityName,
    );
  }
}
