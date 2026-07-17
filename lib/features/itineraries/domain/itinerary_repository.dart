import 'package:flutter/foundation.dart';

import 'models/itinerary_day.dart';
import 'models/itinerary_stop.dart';
import 'models/trip.dart';

/// Demande de génération AI.
class TripGenerationRequest {
  const TripGenerationRequest({
    required this.startDate,
    required this.endDate,
    required this.primaryCity,
    this.cities = const [],
    this.pace = 'balanced',
    this.includeFavorites = true,
    this.prayerAware = true,
    this.weatherAware = true,
    this.budgetBand = 'balanced',
    this.title,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String primaryCity;
  final List<String> cities;
  final String pace;
  final bool includeFavorites;
  final bool prayerAware;
  final bool weatherAware;
  final String budgetBand;
  final String? title;

  int get dayCount {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }
}

/// Résultat de génération.
class TripGenerationResult {
  const TripGenerationResult({
    required this.trip,
    this.warnings = const [],
    this.fromAi = false,
  });

  final Trip trip;
  final List<String> warnings;
  final bool fromAi;
}

/// Tronçon de trajet entre deux arrêts.
enum RouteProviderKind { osrm, haversineFallback, unavailable }

class RouteLeg {
  const RouteLeg({
    required this.durationMin,
    required this.distanceKm,
    required this.provider,
    this.geometry,
  });

  final int durationMin;
  final double distanceKm;
  final RouteProviderKind provider;
  final List<List<double>>? geometry;
}

/// Contrat du dépôt itinéraires.
abstract class ItineraryRepository extends ChangeNotifier {
  ItineraryRepository.base();

  bool get isLoaded;

  List<Trip> get trips;

  List<Trip> get activeTrips;

  Trip? findById(String id);

  Future<void> load();

  Future<bool> saveTrip(Trip trip);

  Future<bool> deleteTrip(String id);

  Future<TripGenerationResult> generateTrip(TripGenerationRequest request);

  Future<Trip?> createManualTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String primaryCity,
    List<String> cities = const [],
    String pace = 'balanced',
  });

  Future<ItineraryDay> optimizeDay(Trip trip, ItineraryDay day);

  Future<ItineraryDay> refreshTravelTimes(ItineraryDay day);

  Future<void> addStop({
    required String tripId,
    required int dayIndex,
    required ItineraryStop stop,
  });
}
