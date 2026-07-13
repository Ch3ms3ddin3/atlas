import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../domain/models/home_models.dart';
import '../prayer/prayer_mapper.dart';

/// Construit l'en-tête d'accueil à partir du profil, de la ville et de la date.
class GreetingRepository {
  const GreetingRepository();

  GreetingData build({
    required String firstName,
    required String city,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? PrayerMapper.casablancaNow();
    return GreetingData(
      userName: firstName,
      city: city,
      dateLabel: CasablancaDateFormatter.formatLongDate(now),
    );
  }
}
