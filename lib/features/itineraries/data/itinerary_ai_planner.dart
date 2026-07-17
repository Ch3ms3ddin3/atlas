import 'dart:convert';

import '../../../core/config/atlas_env.dart';
import '../../../core/network/atlas_http_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../explorer/domain/models/place_models.dart';
import '../../explorer/domain/place_repository.dart';
import '../domain/itinerary_repository.dart';
import '../domain/models/itinerary_day.dart';
import '../domain/models/trip.dart';
import 'itinerary_budget_estimator.dart';
import 'itinerary_route_service.dart';
import 'local_itinerary_draft_builder.dart';

/// Génération AI via Edge Function `itinerary-generate` + fallback local.
class ItineraryAiPlanner {
  ItineraryAiPlanner({
    required this.localBuilder,
    AtlasEnv? env,
    this.functionName = 'itinerary-generate',
  }) : _env = env ?? AtlasEnv.fromCompileTime();

  final LocalItineraryDraftBuilder localBuilder;
  final AtlasEnv _env;
  final String functionName;

  bool get isCloudAvailable =>
      _env.isConfigured && SupabaseBootstrap.isInitialized;

  Future<TripGenerationResult> generate(TripGenerationRequest request) async {
    final local = await localBuilder.build(request);
    if (!isCloudAvailable) {
      return TripGenerationResult(
        trip: local.trip,
        warnings: [
          ...local.warnings,
          'Assistant cloud indisponible — brouillon local généré.',
        ],
        fromAi: false,
      );
    }

    try {
      final base = _env.supabaseUrl.replaceAll(RegExp(r'/$'), '');
      final url = '$base/functions/v1/$functionName';
      final session = SupabaseBootstrap.clientOrNull()?.auth.currentSession;
      final bearer = session?.accessToken ?? _env.supabaseAnonKey;

      final placeHints = <Map<String, dynamic>>[];
      try {
        final places = PlaceRepository().search(
          PlaceSearchQuery(cityName: request.primaryCity),
        );
        for (final place in places.take(25)) {
          placeHints.add({
            'id': place.id,
            'title': place.name,
            if (place.latitude != null) 'lat': place.latitude,
            if (place.longitude != null) 'lng': place.longitude,
          });
        }
      } catch (_) {}

      final payload = {
        'model': 'gpt-4o-mini',
        'request': {
          'start_date': local.trip.startDate.toIso8601String().split('T').first,
          'end_date': local.trip.endDate.toIso8601String().split('T').first,
          'primary_city': request.primaryCity,
          'cities': request.cities,
          'pace': request.pace,
          'budget_band': request.budgetBand,
          'prayer_aware': request.prayerAware,
          'weather_aware': request.weatherAware,
        },
        'candidate_places': placeHints,
        'seed_trip': local.trip.toJson(),
      };

      final responseBody = await _postJson(url, bearer, jsonEncode(payload));
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final tripJson = decoded['trip'] as Map<String, dynamic>?;
      if (tripJson == null) {
        return TripGenerationResult(
          trip: local.trip,
          warnings: [
            ...local.warnings,
            'Réponse AI incomplète — brouillon local conservé.',
          ],
          fromAi: false,
        );
      }

      var trip = Trip.fromJson(tripJson);
      if (!trip.isWithinLimit) {
        return TripGenerationResult(
          trip: local.trip,
          warnings: ['AI a proposé une durée invalide — brouillon local.'],
          fromAi: false,
        );
      }

      final enrichedDays = <ItineraryDay>[];
      for (final day in trip.days) {
        var stops = ItineraryRouteService.optimizeStopOrder(day.stops);
        stops = await ItineraryRouteService.applyTravelTimes(stops);
        enrichedDays.add(day.copyWith(stops: stops));
      }
      trip = trip.copyWith(
        days: enrichedDays,
        budget: trip.budget ??
            ItineraryBudgetEstimator.estimate(
              dayCount: trip.dayCount,
              budgetBand: request.budgetBand,
              stopCount: enrichedDays.fold(0, (s, d) => s + d.stops.length),
            ),
        updatedAt: DateTime.now().toUtc(),
        syncPending: true,
      );

      return TripGenerationResult(
        trip: trip,
        warnings: [
          ...local.warnings,
          ...((decoded['warnings'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString()),
        ],
        fromAi: true,
      );
    } catch (_) {
      return TripGenerationResult(
        trip: local.trip,
        warnings: [
          ...local.warnings,
          'Génération AI indisponible — brouillon local.',
        ],
        fromAi: false,
      );
    }
  }

  Future<String> _postJson(
    String url,
    String bearer,
    String body,
  ) async {
    final buffer = StringBuffer();
    await for (final chunk in AtlasHttpClient.postJsonStream(
      url: url,
      headers: {
        'Authorization': 'Bearer $bearer',
        'apikey': _env.supabaseAnonKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }
}
