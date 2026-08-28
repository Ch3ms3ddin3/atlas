import '../../../../core/datetime/atlas_display_clock.dart';
import '../../../../core/location/atlas_city_source.dart';
import '../../../../core/location/atlas_geo_country.dart';
import '../../../../core/location/user_location.dart';

/// Méthode AlAdhan + fuseau pour un pays ISO.
class PrayerCalculationMethod {
  const PrayerCalculationMethod({
    required this.id,
    required this.label,
    this.timeZoneString,
  });

  /// Identifiant `method` de l'API AlAdhan.
  final int id;

  /// Libellé affiché (carte / source).
  final String label;

  /// Fuseau IANA ; `null` → AlAdhan infère depuis les coordonnées.
  final String? timeZoneString;
}

/// Plan d'appel AlAdhan — jamais de coords catalogue si la position n'est pas réelle.
class PrayerFetchPlan {
  const PrayerFetchPlan._({
    required this.canFetch,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.method,
  });

  const PrayerFetchPlan.blocked()
    : canFetch = false,
      latitude = null,
      longitude = null,
      countryCode = null,
      method = null;

  const PrayerFetchPlan.fetch({
    required double latitude,
    required double longitude,
    required String? countryCode,
    required PrayerCalculationMethod method,
  }) : this._(
         canFetch: true,
         latitude: latitude,
         longitude: longitude,
         countryCode: countryCode,
         method: method,
       );

  final bool canFetch;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final PrayerCalculationMethod? method;

  int get methodId => method!.id;
  String get methodLabel => method!.label;
  String? get timeZoneString => method!.timeZoneString;
}

/// Source de vérité unique : coords, fuseau et méthode de calcul des prières.
abstract final class PrayerCalculationPolicy {
  static const moroccoMethodId = 21;
  static const franceUoifMethodId = 12;
  static const muslimWorldLeagueMethodId = 3;

  static const moroccoLabel = 'AlAdhan · méthode Maroc';
  static const franceUoifLabel = 'AlAdhan · UOIF';
  static const mwlLabel = 'AlAdhan · Ligue islamique mondiale';

  /// `true` seulement si on a une position réelle (GPS) ou une ville choisie.
  static bool canFetch({
    required AtlasCitySource citySource,
    required UserLocation location,
  }) {
    return resolve(citySource: citySource, location: location).canFetch;
  }

  static PrayerFetchPlan resolve({
    required AtlasCitySource citySource,
    required UserLocation location,
  }) {
    if (citySource == AtlasCitySource.manual) {
      final country = _normalizeCountry(location.countryCode) ?? 'MA';
      return PrayerFetchPlan.fetch(
        latitude: location.latitude,
        longitude: location.longitude,
        countryCode: country,
        method: methodForCountry(country),
      );
    }

    if (!location.isResolved) {
      return const PrayerFetchPlan.blocked();
    }

    final country =
        _normalizeCountry(location.countryCode) ??
        AtlasGeoCountry.guessIsoCode(
          latitude: location.latitude,
          longitude: location.longitude,
        );

    return PrayerFetchPlan.fetch(
      latitude: location.latitude,
      longitude: location.longitude,
      countryCode: country,
      method: methodForCountry(country),
    );
  }

  /// Table pays → méthode AlAdhan officielle ou équivalent usuel.
  static PrayerCalculationMethod methodForCountry(String? countryCode) {
    final code = _normalizeCountry(countryCode);
    switch (code) {
      case 'MA' || 'EH':
        return const PrayerCalculationMethod(
          id: moroccoMethodId,
          label: moroccoLabel,
          timeZoneString: AtlasDisplayClock.casablancaTimeZone,
        );
      case 'FR' || 'MC':
        return const PrayerCalculationMethod(
          id: franceUoifMethodId,
          label: franceUoifLabel,
          timeZoneString: 'Europe/Paris',
        );
      case 'DZ':
        return const PrayerCalculationMethod(
          id: 19,
          label: 'AlAdhan · Algérie',
          timeZoneString: 'Africa/Algiers',
        );
      case 'TN':
        return const PrayerCalculationMethod(
          id: 18,
          label: 'AlAdhan · Tunisie',
          timeZoneString: 'Africa/Tunis',
        );
      case 'EG':
        return const PrayerCalculationMethod(
          id: 5,
          label: 'AlAdhan · Égypte',
          timeZoneString: 'Africa/Cairo',
        );
      case 'SA':
        return const PrayerCalculationMethod(
          id: 4,
          label: 'AlAdhan · Umm al-Qura',
          timeZoneString: 'Asia/Riyadh',
        );
      case 'AE':
        return const PrayerCalculationMethod(
          id: 16,
          label: 'AlAdhan · Dubaï',
          timeZoneString: 'Asia/Dubai',
        );
      case 'KW':
        return const PrayerCalculationMethod(
          id: 9,
          label: 'AlAdhan · Koweït',
          timeZoneString: 'Asia/Kuwait',
        );
      case 'QA':
        return const PrayerCalculationMethod(
          id: 10,
          label: 'AlAdhan · Qatar',
          timeZoneString: 'Asia/Qatar',
        );
      case 'BH' || 'OM':
        return const PrayerCalculationMethod(id: 8, label: 'AlAdhan · Golfe');
      case 'TR':
        return const PrayerCalculationMethod(
          id: 13,
          label: 'AlAdhan · Diyanet',
          timeZoneString: 'Europe/Istanbul',
        );
      case 'IR':
        return const PrayerCalculationMethod(
          id: 7,
          label: 'AlAdhan · Téhéran',
          timeZoneString: 'Asia/Tehran',
        );
      case 'ID':
        return const PrayerCalculationMethod(
          id: 20,
          label: 'AlAdhan · Indonésie',
        );
      case 'MY':
        return const PrayerCalculationMethod(
          id: 17,
          label: 'AlAdhan · Malaisie',
        );
      case 'SG':
        return const PrayerCalculationMethod(
          id: 11,
          label: 'AlAdhan · Singapour',
          timeZoneString: 'Asia/Singapore',
        );
      case 'PT':
        return const PrayerCalculationMethod(
          id: 22,
          label: 'AlAdhan · Lisbonne',
          timeZoneString: 'Europe/Lisbon',
        );
      case 'US' || 'CA':
        return const PrayerCalculationMethod(id: 2, label: 'AlAdhan · ISNA');
      case 'RU':
        return const PrayerCalculationMethod(id: 14, label: 'AlAdhan · Russie');
      case 'JO':
        return const PrayerCalculationMethod(
          id: 23,
          label: 'AlAdhan · Jordanie',
          timeZoneString: 'Asia/Amman',
        );
      case 'BE':
        return const PrayerCalculationMethod(
          id: franceUoifMethodId,
          label: franceUoifLabel,
          timeZoneString: 'Europe/Brussels',
        );
      case 'ES':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/Madrid',
        );
      case 'DE':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/Berlin',
        );
      case 'GB':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/London',
        );
      case 'IT':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/Rome',
        );
      case 'NL':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/Amsterdam',
        );
      case 'CH':
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
          timeZoneString: 'Europe/Zurich',
        );
      default:
        return const PrayerCalculationMethod(
          id: muslimWorldLeagueMethodId,
          label: mwlLabel,
        );
    }
  }

  static String labelForMethod(int methodId) {
    switch (methodId) {
      case moroccoMethodId:
        return moroccoLabel;
      case franceUoifMethodId:
        return franceUoifLabel;
      case muslimWorldLeagueMethodId:
        return mwlLabel;
      default:
        return 'AlAdhan · méthode $methodId';
    }
  }

  static String? _normalizeCountry(String? raw) {
    final code = raw?.trim().toUpperCase();
    if (code == null || code.isEmpty) return null;
    return code;
  }
}
