import '../../../core/location/morocco_cities.dart';
import '../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../admission_temporaire/data/at_calculator.dart';
import '../../admission_temporaire/domain/at_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../../events/domain/event_repository.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../home/data/exchange_rate/exchange_rate_repository.dart';
import '../../home/data/holiday/holiday_repository.dart';
import '../../home/data/weather/weather_repository.dart';
import '../../home/domain/models/exchange_rate_snapshot.dart';
import '../../home/domain/models/weather_snapshot.dart';
import '../../profile/domain/models/user_profile.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/models/assistant_context_snapshot.dart';

/// Assemble un snapshot de contexte depuis les modules Atlas existants.
class AssistantContextBuilder {
  AssistantContextBuilder({
    required this.profileRepository,
    required this.authRepository,
    required this.favoritesRepository,
    required this.atRepository,
    WeatherRepository? weatherRepository,
    ExchangeRateRepository? exchangeRateRepository,
    HolidayRepository? holidayRepository,
    this.eventRepositoryProvider,
    this.prayerLeadTimeProvider,
  })  : _weatherRepository = weatherRepository ?? WeatherRepository(),
        _exchangeRateRepository =
            exchangeRateRepository ?? ExchangeRateRepository(),
        _holidayRepository = holidayRepository ?? HolidayRepository();

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final FavoritesRepository favoritesRepository;
  final AtRepository atRepository;
  final WeatherRepository _weatherRepository;
  final ExchangeRateRepository _exchangeRateRepository;
  final HolidayRepository _holidayRepository;
  final EventRepository? Function()? eventRepositoryProvider;
  final Future<String?> Function()? prayerLeadTimeProvider;

  Future<AssistantContextSnapshot> build() async {
    final profile = profileRepository.profile;
    final session = authRepository.session;
    final language = switch (profile.language) {
      AtlasLanguage.english => 'english',
      AtlasLanguage.arabic => 'arabic',
      AtlasLanguage.french => 'french',
    };

    final vehicles = atRepository.activeVehicles;
    final vehicleSummaries = [
      for (final vehicle in vehicles.take(5))
        '${vehicle.label} (${vehicle.plate}) — '
            '${AtCalculator.remainingLabel(
          remainingDays: AtCalculator.remainingDays(
            expiryDate: vehicle.expiryDate,
          ),
        )}',
    ];

    final favorites = favoritesRepository.activeFavorites;
    final favoriteSummaries = [
      for (final fav in favorites.take(8))
        '${fav.entityType.name}:${fav.entitySlug}',
    ];

    final filters = PlaceBrowseFilters.instance;
    final explorerParts = <String>[
      if (filters.cityName.isNotEmpty) 'ville=${filters.cityName}',
      if (filters.category != null) 'catégorie=${filters.category!.name}',
      if (filters.favoritesOnly) 'favoris_seulement',
    ];

    String? prayerLabel;
    try {
      final custom = prayerLeadTimeProvider;
      if (custom != null) {
        prayerLabel = await custom();
      } else {
        final lead = await prayerNotificationCoordinator.currentLeadTime();
        prayerLabel = lead.label;
      }
    } catch (_) {
      prayerLabel = null;
    }

    final weatherSummary = await _safeWeather(profile.preferredCity);
    final exchangeSummary = await _safeExchange();
    final holidaySummary = await _safeHoliday();
    final events = _safeEvents(profile.preferredCity);

    return AssistantContextSnapshot(
      city: profile.preferredCity,
      userType: profile.userType.name,
      language: language,
      authKind: session.kind.name,
      isSignedIn: session.kind == AuthSessionKind.signedIn,
      firstName: profile.firstName,
      prayerLeadTimeLabel: prayerLabel,
      vehicleSummaries: vehicleSummaries,
      favoriteSummaries: favoriteSummaries,
      weatherSummary: weatherSummary,
      exchangeRateSummary: exchangeSummary,
      holidaySummary: holidaySummary,
      eventHighlights: events,
      explorerSummary: explorerParts.isEmpty ? null : explorerParts.join(', '),
    );
  }

  Future<String?> _safeWeather(String cityName) async {
    try {
      final city = MoroccoCities.resolve(cityName) ?? MoroccoCities.fallback;
      final snapshot = await _weatherRepository
          .getWeather(
            latitude: city.latitude,
            longitude: city.longitude,
          )
          .timeout(const Duration(seconds: 4));
      if (!snapshot.hasWeather || snapshot.data == null) return null;
      if (snapshot.state == WeatherLoadState.unavailable) return null;
      final data = snapshot.data!;
      final suffix = snapshot.state == WeatherLoadState.stale ? ' (cache)' : '';
      return '${data.temperature}°C, ${data.condition}$suffix';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _safeExchange() async {
    try {
      final snapshot = await _exchangeRateRepository
          .getExchangeRate()
          .timeout(const Duration(seconds: 4));
      if (snapshot.state == ExchangeRateLoadState.unavailable) return null;
      final data = snapshot.data;
      if (data == null) return null;
      final suffix =
          snapshot.state == ExchangeRateLoadState.stale ? ' (cache)' : '';
      return '1 EUR = ${data.rate.toStringAsFixed(2)} MAD$suffix';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _safeHoliday() async {
    try {
      final status = await _holidayRepository
          .getHolidayStatus()
          .timeout(const Duration(seconds: 4));
      return '${status.label} — ${status.detail}';
    } catch (_) {
      return null;
    }
  }

  List<String> _safeEvents(String city) {
    try {
      final repo = eventRepositoryProvider?.call();
      if (repo == null) {
        try {
          final fallback = EventRepository();
          return _mapEvents(fallback, city);
        } catch (_) {
          return const [];
        }
      }
      return _mapEvents(repo, city);
    } catch (_) {
      return const [];
    }
  }

  List<String> _mapEvents(EventRepository repo, String city) {
    final upcoming = repo.upcoming(cityName: city).take(3);
    return [
      for (final event in upcoming)
        '${event.title} (${event.cityName ?? city})',
    ];
  }
}
