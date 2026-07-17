import 'dart:math' as math;

import '../../../core/config/atlas_env.dart';
import '../../../core/network/atlas_http_client.dart';
import '../domain/itinerary_repository.dart';
import '../domain/models/itinerary_stop.dart';

/// Optimisation locale + estimation de trajets (OSRM + haversine).
abstract final class ItineraryRouteService {
  /// Nearest-neighbor + 2-opt léger sur les arrêts géolocalisés.
  static List<ItineraryStop> optimizeStopOrder(List<ItineraryStop> stops) {
    final withCoords = stops.where((s) => s.hasCoordinates).toList();
    final without = stops.where((s) => !s.hasCoordinates).toList();
    if (withCoords.length <= 2) return [...withCoords, ...without];

    final remaining = List<ItineraryStop>.of(withCoords);
    final ordered = <ItineraryStop>[remaining.removeAt(0)];
    while (remaining.isNotEmpty) {
      final last = ordered.last;
      remaining.sort(
        (a, b) => _haversineKm(
          last.latitude!,
          last.longitude!,
          a.latitude!,
          a.longitude!,
        ).compareTo(
          _haversineKm(
            last.latitude!,
            last.longitude!,
            b.latitude!,
            b.longitude!,
          ),
        ),
      );
      ordered.add(remaining.removeAt(0));
    }

    // 2-opt pass
    var improved = true;
    while (improved) {
      improved = false;
      for (var i = 0; i < ordered.length - 2; i++) {
        for (var k = i + 1; k < ordered.length - 1; k++) {
          final current = _pathLength(ordered);
          final candidate = [
            ...ordered.sublist(0, i + 1),
            ...ordered.sublist(i + 1, k + 1).reversed,
            ...ordered.sublist(k + 1),
          ];
          if (_pathLength(candidate) + 0.01 < current) {
            ordered
              ..clear()
              ..addAll(candidate);
            improved = true;
          }
        }
      }
    }

    return [...ordered, ...without];
  }

  static Future<List<ItineraryStop>> applyTravelTimes(
    List<ItineraryStop> stops, {
    AtlasEnv? env,
  }) async {
    if (stops.isEmpty) return stops;
    final result = <ItineraryStop>[];
    for (var i = 0; i < stops.length; i++) {
      if (i == 0 || !stops[i].hasCoordinates || !stops[i - 1].hasCoordinates) {
        result.add(stops[i].copyWith(clearTravel: true));
        continue;
      }
      final leg = await estimateLeg(
        fromLat: stops[i - 1].latitude!,
        fromLng: stops[i - 1].longitude!,
        toLat: stops[i].latitude!,
        toLng: stops[i].longitude!,
        env: env,
      );
      result.add(
        stops[i].copyWith(
          travelFromPreviousMin: leg.durationMin,
          travelDistanceKm: leg.distanceKm,
        ),
      );
    }
    return result;
  }

  static Future<RouteLeg> estimateLeg({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    AtlasEnv? env,
  }) async {
    final baseUrl = _osrmBaseUrl(env);
    if (baseUrl != null) {
      try {
        final uri = Uri.parse(
          '$baseUrl/route/v1/driving/'
          '$fromLng,$fromLat;$toLng,$toLat'
          '?overview=false&alternatives=false',
        );
        final body = await AtlasHttpClient.get(uri.toString())
            .timeout(const Duration(seconds: 4));
        // Lightweight parse without dart:convert dependency issues
        final durationMatch =
            RegExp(r'"duration"\s*:\s*([0-9.]+)').firstMatch(body);
        final distanceMatch =
            RegExp(r'"distance"\s*:\s*([0-9.]+)').firstMatch(body);
        if (durationMatch != null && distanceMatch != null) {
          final seconds = double.parse(durationMatch.group(1)!);
          final meters = double.parse(distanceMatch.group(1)!);
          return RouteLeg(
            durationMin: math.max(1, (seconds / 60).round()),
            distanceKm: meters / 1000,
            provider: RouteProviderKind.osrm,
          );
        }
      } catch (_) {
        // fall through
      }
    }

    final km = _haversineKm(fromLat, fromLng, toLat, toLng);
    // ~25 km/h urban average → minutes
    final minutes = math.max(1, (km / 25 * 60).round());
    return RouteLeg(
      durationMin: minutes,
      distanceKm: km,
      provider: RouteProviderKind.haversineFallback,
    );
  }

  static String? _osrmBaseUrl(AtlasEnv? env) {
    const fromDefine = String.fromEnvironment('OSRM_BASE_URL', defaultValue: '');
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim().replaceAll(RegExp(r'/$'), '');
    }
    // Public demo server — best-effort only.
    return 'https://router.project-osrm.org';
  }

  static double _pathLength(List<ItineraryStop> stops) {
    var total = 0.0;
    for (var i = 1; i < stops.length; i++) {
      final a = stops[i - 1];
      final b = stops[i];
      if (!a.hasCoordinates || !b.hasCoordinates) continue;
      total += _haversineKm(a.latitude!, a.longitude!, b.latitude!, b.longitude!);
    }
    return total;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
