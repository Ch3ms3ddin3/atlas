import '../../domain/models/home_models.dart';
import '../../../profile/domain/models/user_profile.dart';
import 'today_essentials_mapper.dart';

/// Orchestre la construction de « À savoir aujourd'hui ».
class TodayEssentialsRepository {
  const TodayEssentialsRepository();

  TodayEssentialsData build({
    WeatherData? weather,
    required HolidayStatusData holidayStatus,
    required String cityName,
    AtlasUserType userType = UserProfile.defaultUserType,
  }) {
    return TodayEssentialsMapper.fromContext(
      weather: weather,
      holidayStatus: holidayStatus,
      cityName: cityName,
      userType: userType,
    );
  }
}
