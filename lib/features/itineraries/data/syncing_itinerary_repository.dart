import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/uuid/atlas_uuid.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../domain/itinerary_repository.dart';
import '../domain/models/itinerary_day.dart';
import '../domain/models/itinerary_enums.dart';
import '../domain/models/itinerary_stop.dart';
import '../domain/models/trip.dart';
import 'itinerary_ai_planner.dart';
import 'itinerary_local_store.dart';
import 'itinerary_route_service.dart';
import 'itinerary_sync_coordinator.dart';
import 'local_itinerary_draft_builder.dart';
import 'supabase_itinerary_repository.dart';

/// Itinéraires local-first avec sync Supabase silencieuse.
class SyncingItineraryRepository extends ItineraryRepository {
  SyncingItineraryRepository({
    FavoritesRepository? favoritesRepository,
    ItineraryLocalStore? store,
    SupabaseItineraryRepository? remote,
    ItineraryAiPlanner? aiPlanner,
    LocalItineraryDraftBuilder? draftBuilder,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const ItineraryLocalStore(),
        _remote = remote ?? const SupabaseItineraryRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ??
            (() => SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id),
        _draftBuilder = draftBuilder ??
            LocalItineraryDraftBuilder(
              favoritesRepository: favoritesRepository,
            ),
        super.base() {
    _aiPlanner = aiPlanner ??
        ItineraryAiPlanner(localBuilder: _draftBuilder);
  }

  final ItineraryLocalStore _store;
  final SupabaseItineraryRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final LocalItineraryDraftBuilder _draftBuilder;
  late final ItineraryAiPlanner _aiPlanner;
  @visibleForTesting
  final bool syncEnabledOverride;

  bool _loaded = false;
  List<Trip> _trips = [];
  bool _syncInProgress = false;

  @override
  bool get isLoaded => _loaded;

  @override
  List<Trip> get trips => List.unmodifiable(_trips);

  @override
  List<Trip> get activeTrips =>
      _trips.where((t) => t.isActive && t.status != TripStatus.archived).toList();

  @override
  Trip? findById(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  @override
  Future<void> load() async {
    _trips = await _store.loadTrips();
    _loaded = true;
    notifyListeners();
    unawaited(_sync());
  }

  @override
  Future<bool> saveTrip(Trip trip) async {
    if (!trip.isWithinLimit) return false;
    final now = DateTime.now().toUtc();
    final stamped = trip.copyWith(updatedAt: now, syncPending: true);
    final index = _trips.indexWhere((t) => t.id == stamped.id);
    if (index < 0) {
      _trips = [stamped, ..._trips];
    } else {
      final next = [..._trips];
      next[index] = stamped;
      _trips = next;
    }
    await _persist();
    await _store.setSyncPending(true);
    notifyListeners();
    unawaited(_sync());
    return true;
  }

  @override
  Future<bool> deleteTrip(String id) async {
    final index = _trips.indexWhere((t) => t.id == id);
    if (index < 0) return false;
    final next = [..._trips];
    next[index] = next[index].copyWith(
      isActive: false,
      status: TripStatus.archived,
      updatedAt: DateTime.now().toUtc(),
      syncPending: true,
    );
    _trips = next;
    await _persist();
    await _store.setSyncPending(true);
    notifyListeners();
    unawaited(_sync());
    return true;
  }

  @override
  Future<TripGenerationResult> generateTrip(
    TripGenerationRequest request,
  ) async {
    final result = await _aiPlanner.generate(request);
    if (result.trip.isWithinLimit) {
      await saveTrip(result.trip);
    }
    return result;
  }

  @override
  Future<ItineraryDay> optimizeDay(Trip trip, ItineraryDay day) async {
    var stops = ItineraryRouteService.optimizeStopOrder(day.stops);
    stops = await ItineraryRouteService.applyTravelTimes(stops);
    final updatedDay = day.copyWith(stops: stops);
    final days = [
      for (final d in trip.days) d.id == day.id ? updatedDay : d,
    ];
    await saveTrip(trip.copyWith(days: days));
    return updatedDay;
  }

  @override
  Future<ItineraryDay> refreshTravelTimes(ItineraryDay day) async {
    final stops = await ItineraryRouteService.applyTravelTimes(day.stops);
    return day.copyWith(stops: stops);
  }

  /// Crée un voyage manuel vide sur la plage de dates.
  @override
  Future<Trip?> createManualTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String primaryCity,
    List<String> cities = const [],
    String pace = 'balanced',
  }) async {
    final request = TripGenerationRequest(
      startDate: startDate,
      endDate: endDate,
      primaryCity: primaryCity,
      cities: cities,
      pace: pace,
      title: title,
      includeFavorites: false,
      prayerAware: false,
      weatherAware: false,
    );
    if (request.dayCount < 1 || request.dayCount > ItineraryLimits.maxDays) {
      return null;
    }
    final days = <ItineraryDay>[];
    for (var i = 0; i < request.dayCount; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day)
          .add(Duration(days: i));
      days.add(
        ItineraryDay(
          id: AtlasUuid.v4(),
          dayIndex: i,
          date: date,
          cityName: cities.isNotEmpty
              ? cities[i % cities.length]
              : primaryCity,
          stops: const [],
        ),
      );
    }
    final now = DateTime.now().toUtc();
    final trip = Trip(
      id: AtlasUuid.v4(),
      title: title.trim().isEmpty ? 'Voyage à $primaryCity' : title.trim(),
      startDate: startDate,
      endDate: endDate,
      primaryCity: primaryCity,
      cities: cities.isEmpty ? [primaryCity] : cities,
      days: days,
      status: TripStatus.draft,
      pace: pace,
      createdAt: now,
      updatedAt: now,
      syncPending: true,
    );
    await saveTrip(trip);
    return trip;
  }

  @override
  Future<void> addStop({
    required String tripId,
    required int dayIndex,
    required ItineraryStop stop,
  }) async {
    final trip = findById(tripId);
    if (trip == null) return;
    final days = [...trip.days];
    if (dayIndex < 0 || dayIndex >= days.length) return;
    final day = days[dayIndex];
    days[dayIndex] = day.copyWith(stops: [...day.stops, stop]);
    await saveTrip(trip.copyWith(days: days));
  }

  Future<void> _persist() => _store.saveTrips(_trips);

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured && SupabaseBootstrap.isInitialized);

  Future<void> _sync() async {
    if (_syncInProgress || !_canSync) return;
    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) return;

    _syncInProgress = true;
    try {
      final remote = await _remote.fetchAll(userId);
      final merged = ItinerarySyncCoordinator.merge(
        local: _trips,
        remote: remote,
      );
      _trips = merged;
      await _persist();

      final pending = merged.any((t) => t.syncPending) ||
          await _store.isSyncPending();
      if (pending) {
        await _remote.upsertAll(userId, merged);
        _trips = [
          for (final trip in merged) trip.copyWith(syncPending: false),
        ];
        await _persist();
        await _store.setSyncPending(false);
      }
      notifyListeners();
    } catch (_) {
      // Silent — offline-first.
    } finally {
      _syncInProgress = false;
    }
  }
}
