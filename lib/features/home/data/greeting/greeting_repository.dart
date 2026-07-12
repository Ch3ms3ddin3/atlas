import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../domain/models/home_models.dart';
import '../mock/home_mock_data.dart';
import '../prayer/prayer_mapper.dart';

/// Construit l'en-tête d'accueil à partir de la ville et de la date locale.
class GreetingRepository {
  const GreetingRepository();

  GreetingData build({required String city, DateTime? referenceTime}) {
    final now = referenceTime ?? PrayerMapper.casablancaNow();
    return GreetingData(
      userName: HomeMockData.greeting.userName,
      city: city,
      dateLabel: CasablancaDateFormatter.formatLongDate(now),
    );
  }
}
