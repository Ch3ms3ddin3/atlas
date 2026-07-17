import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/itineraries/data/itinerary_budget_estimator.dart';
import 'package:atlas/features/itineraries/data/itinerary_route_service.dart';
import 'package:atlas/features/itineraries/data/itinerary_sync_coordinator.dart';
import 'package:atlas/features/itineraries/data/local_itinerary_draft_builder.dart';
import 'package:atlas/features/itineraries/data/syncing_itinerary_repository.dart';
import 'package:atlas/features/itineraries/domain/itinerary_repository.dart';
import 'package:atlas/features/itineraries/domain/models/itinerary_enums.dart';
import 'package:atlas/features/itineraries/domain/models/itinerary_stop.dart';
import 'package:atlas/features/itineraries/domain/models/trip.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/price_repository.dart';
import 'package:atlas/features/procedures/domain/procedure_repository.dart';
import 'package:atlas/features/events/domain/event_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    PriceRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    EventRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    PriceRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    EventRepository.resetForTest();
  });

  group('ItineraryRouteService', () {
    test('optimise l\'ordre des arrêts géolocalisés', () {
      final stops = [
        const ItineraryStop(
          id: 'a',
          type: ItineraryStopType.place,
          title: 'A',
          source: ItineraryStopSource.user,
          latitude: 31.63,
          longitude: -8.0,
        ),
        const ItineraryStop(
          id: 'c',
          type: ItineraryStopType.place,
          title: 'C',
          source: ItineraryStopSource.user,
          latitude: 31.64,
          longitude: -8.02,
        ),
        const ItineraryStop(
          id: 'b',
          type: ItineraryStopType.place,
          title: 'B',
          source: ItineraryStopSource.user,
          latitude: 31.631,
          longitude: -8.001,
        ),
      ];
      final ordered = ItineraryRouteService.optimizeStopOrder(stops);
      expect(ordered.map((s) => s.id).toList(), isNot(equals(['a', 'c', 'b'])));
      expect(ordered, hasLength(3));
    });

    test('estime un trajet haversine hors OSRM', () async {
      final leg = await ItineraryRouteService.estimateLeg(
        fromLat: 31.63,
        fromLng: -8.0,
        toLat: 31.64,
        toLng: -8.01,
      );
      expect(leg.durationMin, greaterThan(0));
      expect(leg.distanceKm, greaterThan(0));
      expect(
        leg.provider,
        anyOf(RouteProviderKind.osrm, RouteProviderKind.haversineFallback),
      );
    });
  });

  group('ItineraryBudgetEstimator', () {
    test('produit des fourchettes MAD', () {
      final budget = ItineraryBudgetEstimator.estimate(
        dayCount: 3,
        budgetBand: 'balanced',
        stopCount: 9,
      );
      expect(budget.totalMin, greaterThan(0));
      expect(budget.totalMax, greaterThan(budget.totalMin!));
      expect(budget.notes, contains('indicatives'));
    });
  });

  group('ItinerarySyncCoordinator', () {
    test('fusionne en LWW et respecte syncPending local', () {
      final older = Trip(
        id: 't1',
        title: 'Remote',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        primaryCity: 'Rabat',
        status: TripStatus.draft,
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 10),
        syncPending: false,
      );
      final localPending = older.copyWith(
        title: 'Local pending',
        updatedAt: DateTime.utc(2026, 7, 1),
        syncPending: true,
      );
      final merged = ItinerarySyncCoordinator.merge(
        local: [localPending],
        remote: [older.copyWith(title: 'Should not win', updatedAt: DateTime.utc(2026, 7, 20))],
      );
      expect(merged.single.title, 'Local pending');
    });
  });

  group('SyncingItineraryRepository', () {
    test('persiste hors ligne et respecte la limite 14 jours', () async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final repo = SyncingItineraryRepository(
        favoritesRepository: favorites,
      );
      await repo.load();

      final ok = await repo.createManualTrip(
        title: 'Week-end Fès',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        primaryCity: 'Fès',
      );
      expect(ok, isNotNull);
      expect(repo.activeTrips, hasLength(1));
      expect(repo.activeTrips.first.dayCount, 3);

      final tooLong = await repo.createManualTrip(
        title: 'Trop long',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 20),
        primaryCity: 'Marrakech',
      );
      expect(tooLong, isNull);
      expect(repo.activeTrips, hasLength(1));

      // Reload from SharedPreferences — offline availability.
      final reloaded = SyncingItineraryRepository(
        favoritesRepository: favorites,
      );
      await reloaded.load();
      expect(reloaded.activeTrips, hasLength(1));
      expect(reloaded.activeTrips.first.title, 'Week-end Fès');
    });

    test('génère un brouillon local (fallback AI)', () async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final repo = SyncingItineraryRepository(
        favoritesRepository: favorites,
        draftBuilder: LocalItineraryDraftBuilder(
          favoritesRepository: favorites,
        ),
      );
      await repo.load();

      final result = await repo.generateTrip(
        TripGenerationRequest(
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 3),
          primaryCity: 'Marrakech',
          includeFavorites: false,
          prayerAware: false,
          weatherAware: false,
        ),
      );
      expect(result.trip.dayCount, 3);
      expect(result.trip.isWithinLimit, isTrue);
      expect(repo.activeTrips.any((t) => t.id == result.trip.id), isTrue);
    });
  });
}
