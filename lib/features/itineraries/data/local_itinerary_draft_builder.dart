import '../../../core/location/morocco_cities.dart';
import '../../../core/uuid/atlas_uuid.dart';
import '../../explorer/domain/models/place_models.dart';
import '../../explorer/domain/place_repository.dart';
import '../../favorites/domain/favorite_entity_type.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../home/data/prayer/prayer_repository.dart';
import '../domain/itinerary_repository.dart';
import '../domain/models/itinerary_day.dart';
import '../domain/models/itinerary_enums.dart';
import '../domain/models/itinerary_stop.dart';
import '../domain/models/trip.dart';
import 'itinerary_budget_estimator.dart';
import 'itinerary_route_service.dart';
import 'itinerary_weather_service.dart';

/// Construit un brouillon d'itinéraire local (sans LLM) — fallback offline / seed AI.
class LocalItineraryDraftBuilder {
  LocalItineraryDraftBuilder({
    this.favoritesRepository,
    this.placeRepositoryProvider,
    this.prayerRepository,
    OpenMeteoDailyForecastClient? weatherClient,
  }) : _weatherClient = weatherClient ?? const OpenMeteoDailyForecastClient();

  final FavoritesRepository? favoritesRepository;
  final PlaceRepository? Function()? placeRepositoryProvider;
  final PrayerRepository? prayerRepository;
  final OpenMeteoDailyForecastClient _weatherClient;

  Future<TripGenerationResult> build(TripGenerationRequest request) async {
    final warnings = <String>[];
    if (request.dayCount < 1 || request.dayCount > ItineraryLimits.maxDays) {
      return TripGenerationResult(
        trip: _emptyTrip(request),
        warnings: [
          'La durée doit être entre 1 et ${ItineraryLimits.maxDays} jours.',
        ],
      );
    }

    final places = _candidatePlaces(
      city: request.primaryCity,
      includeFavorites: request.includeFavorites,
    );
    if (places.isEmpty) {
      warnings.add(
        'Peu de lieux Atlas disponibles — arrêts à compléter manuellement.',
      );
    }

    final forecasts = await _safeForecast(request);
    final days = <ItineraryDay>[];
    final perDay = switch (request.pace) {
      'relaxed' => 2,
      'packed' => 5,
      _ => 3,
    };

    var placeIndex = 0;
    for (var i = 0; i < request.dayCount; i++) {
      final date = DateTime(
        request.startDate.year,
        request.startDate.month,
        request.startDate.day,
      ).add(Duration(days: i));
      final city = request.cities.isNotEmpty
          ? request.cities[i % request.cities.length]
          : request.primaryCity;

      final dayStops = <ItineraryStop>[];
      for (var s = 0; s < perDay && placeIndex < places.length; s++) {
        final place = places[placeIndex++];
        dayStops.add(
          ItineraryStop(
            id: AtlasUuid.v4(),
            type: ItineraryStopType.place,
            title: place.name,
            source: ItineraryStopSource.ai,
            refId: place.id,
            latitude: place.latitude,
            longitude: place.longitude,
            estimatedDurationMin: 90,
            notes: place.bestTimeToVisit,
          ),
        );
      }

      var ordered = ItineraryRouteService.optimizeStopOrder(dayStops);
      ordered = await ItineraryRouteService.applyTravelTimes(ordered);

      String? weatherSummary;
      if (request.weatherAware) {
        weatherSummary = _weatherForDate(forecasts, date);
        if (weatherSummary == null) {
          warnings.add('Météo multi-jours indisponible pour le jour ${i + 1}.');
        }
      }

      String? prayerSummary;
      if (request.prayerAware) {
        prayerSummary = await _prayerForDay(city, date);
        if (prayerSummary != null) {
          // Soft constraint: note only — do not remove stops.
          ordered = [
            for (final stop in ordered)
              stop.copyWith(
                notes: [
                  if (stop.notes != null && stop.notes!.isNotEmpty) stop.notes,
                  'Éviter de planifier pendant les fenêtres de prière ($prayerSummary).',
                ].whereType<String>().join(' '),
              ),
          ];
        }
      }

      days.add(
        ItineraryDay(
          id: AtlasUuid.v4(),
          dayIndex: i,
          date: date,
          cityName: city,
          stops: ordered,
          weatherSummary: weatherSummary,
          prayerSummary: prayerSummary,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final stopCount =
        days.fold<int>(0, (sum, day) => sum + day.stops.length);
    final trip = Trip(
      id: AtlasUuid.v4(),
      title: request.title?.trim().isNotEmpty == true
          ? request.title!.trim()
          : 'Voyage à ${request.primaryCity}',
      startDate: request.startDate,
      endDate: request.endDate,
      primaryCity: request.primaryCity,
      cities: request.cities.isEmpty ? [request.primaryCity] : request.cities,
      days: days,
      status: TripStatus.draft,
      pace: request.pace,
      budget: ItineraryBudgetEstimator.estimate(
        dayCount: request.dayCount,
        budgetBand: request.budgetBand,
        stopCount: stopCount,
      ),
      createdAt: now,
      updatedAt: now,
      syncPending: true,
    );

    return TripGenerationResult(
      trip: trip,
      warnings: warnings.toSet().toList(),
      fromAi: false,
    );
  }

  List<PlaceGuide> _candidatePlaces({
    required String city,
    required bool includeFavorites,
  }) {
    final places = placeRepositoryProvider?.call() ?? _tryPlaces();
    if (places == null) return const [];

    final all = places
        .search(PlaceSearchQuery(cityName: city))
        .where((p) => p.hasCoordinates)
        .toList();

    final favorites = favoritesRepository;
    if (!includeFavorites || favorites == null) {
      return all.take(40).toList();
    }

    final favSlugs = favorites.activeFavorites
        .where((f) => f.entityType == FavoriteEntityType.place)
        .map((f) => f.entitySlug)
        .toSet();
    final favored = <PlaceGuide>[];
    final rest = <PlaceGuide>[];
    for (final place in all) {
      if (favSlugs.contains(place.id)) {
        favored.add(place);
      } else {
        rest.add(place);
      }
    }
    return [...favored, ...rest].take(40).toList();
  }

  PlaceRepository? _tryPlaces() {
    try {
      return PlaceRepository();
    } catch (_) {
      return null;
    }
  }

  Future<List<DailyWeatherForecast>> _safeForecast(
    TripGenerationRequest request,
  ) async {
    try {
      final city =
          MoroccoCities.resolve(request.primaryCity) ?? MoroccoCities.fallback;
      return await _weatherClient
          .fetchDailyForecast(
            latitude: city.latitude,
            longitude: city.longitude,
            forecastDays: request.dayCount,
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return const [];
    }
  }

  String? _weatherForDate(List<DailyWeatherForecast> forecasts, DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final f in forecasts) {
      if (f.date == key) return f.summaryLabel;
    }
    return null;
  }

  Future<String?> _prayerForDay(String cityName, DateTime date) async {
    try {
      final city = MoroccoCities.resolve(cityName) ?? MoroccoCities.fallback;
      final repo = prayerRepository ?? PrayerRepository.instance;
      final timings = await repo
          .getTimingsForDate(
            latitude: city.latitude,
            longitude: city.longitude,
            date: date,
          )
          .timeout(const Duration(seconds: 4));
      if (timings == null) return null;
      final dhuhr = timings['Dhuhr'] ?? timings['dhuhr'];
      final asr = timings['Asr'] ?? timings['asr'];
      if (dhuhr == null || asr == null) return null;
      return 'Dhuhr $dhuhr · Asr $asr';
    } catch (_) {
      return null;
    }
  }

  Trip _emptyTrip(TripGenerationRequest request) {
    final now = DateTime.now().toUtc();
    return Trip(
      id: AtlasUuid.v4(),
      title: 'Voyage',
      startDate: request.startDate,
      endDate: request.endDate,
      primaryCity: request.primaryCity,
      status: TripStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }
}
