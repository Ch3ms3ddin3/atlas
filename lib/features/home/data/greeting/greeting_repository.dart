import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../core/datetime/atlas_display_clock.dart';
import '../../../../core/location/atlas_city_source.dart';
import '../../domain/models/home_models.dart';

/// Construit l'en-tête d'accueil à partir du profil, de la ville et de la date.
class GreetingRepository {
  const GreetingRepository();

  GreetingData build({
    required String firstName,
    required String city,
    AtlasCitySource citySource = AtlasCitySource.auto,
    DateTime? referenceTime,
  }) {
    final now =
        referenceTime ?? AtlasDisplayClock.nowFor(citySource: citySource);
    return GreetingData(
      userName: firstName,
      city: city,
      dateLabel: CasablancaDateFormatter.formatLongDate(now),
    );
  }
}
