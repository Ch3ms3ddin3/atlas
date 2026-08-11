import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Garde-fous caméra Carte — évite NaN/Infinity (crash `.toInt()` / `.floor()`).
///
/// ## Cause racine (flutter_map 8.3.1, upstream #2221 / #2227)
///
/// Au relâchement d'un pinch/pan (souvent après zoom-out), `_handleScaleEnd`
/// calcule la direction de fling ainsi :
///
/// ```dart
/// direction = flingOffset / flingDistance; // si flingDistance == 0 → 0/0 = NaN
/// ```
///
/// quand le velocity tracker signale une vitesse élevée alors que les derniers
/// échantillons de pointeur coïncident (offset nul). Ce `NaN` entre dans le
/// Tween de fling → `center` caméra non fini → `tile_range.dart` `_floor`
/// lève « Unsupported operation: Infinity or NaN toInt ».
///
/// Correctif amont : `flingDirection` (PR #2220) — pas encore publié sur pub.
/// Ici : [AtlasFiniteCameraConstraint] refuse toute caméra non finie au
/// chokepoint `moveRaw` (gestures incluses).
abstract final class AtlasMapCameraGuard {
  static const double minZoom = 5;
  static const double maxZoom = 18;
  static const double defaultZoom = 12;

  /// Seuil (~200 m) sous lequel on élargit les bounds pour un fit sûr.
  static const double degenerateDegrees = 0.002;

  /// Contrainte unique branchée sur [MapOptions.cameraConstraint].
  static const CameraConstraint finiteCameraConstraint =
      AtlasFiniteCameraConstraint();

  static bool isFiniteNumber(double value) => value.isFinite;

  static bool isFiniteLatLng(double latitude, double longitude) =>
      latitude.isFinite && longitude.isFinite;

  static bool isFiniteLatLngZoom(
    double latitude,
    double longitude,
    double zoom,
  ) =>
      isFiniteLatLng(latitude, longitude) && zoom.isFinite;

  /// Centre / zoom / rotation finis. Ne valide PAS [MapCamera.nonRotatedSize] :
  /// flutter_map démarre avec [MapCamera.kImpossibleSize] (-Inf) avant layout.
  static bool isFiniteCamera(MapCamera camera) =>
      isFiniteLatLngZoom(
        camera.center.latitude,
        camera.center.longitude,
        camera.zoom,
      ) &&
      camera.rotation.isFinite;

  /// Clamp zoom dans [minZoom, maxZoom] ; fallback si non fini.
  static double sanitizeZoom(
    double zoom, {
    double fallback = defaultZoom,
  }) {
    if (!zoom.isFinite) return fallback.clamp(minZoom, maxZoom);
    return zoom.clamp(minZoom, maxZoom);
  }

  /// True si les bounds ont une aire géo négligeable (point unique / NaN).
  static bool isDegenerateBounds(LatLngBounds bounds) {
    final latSpan = (bounds.north - bounds.south).abs();
    final lngSpan = (bounds.east - bounds.west).abs();
    if (!latSpan.isFinite || !lngSpan.isFinite) return true;
    return latSpan < degenerateDegrees && lngSpan < degenerateDegrees;
  }

  /// Élargit les bounds dégénérées pour que [CameraFit.bounds] ne divise pas
  /// par zéro / ne calcule pas un zoom Infinity.
  static LatLngBounds expandIfDegenerate(LatLngBounds bounds) {
    if (!isDegenerateBounds(bounds)) return bounds;
    final c = bounds.center;
    if (!isFiniteLatLng(c.latitude, c.longitude)) {
      return LatLngBounds(
        const LatLng(-0.001, -0.001),
        const LatLng(0.001, 0.001),
      );
    }
    return LatLngBounds(
      LatLng(c.latitude - degenerateDegrees, c.longitude - degenerateDegrees),
      LatLng(c.latitude + degenerateDegrees, c.longitude + degenerateDegrees),
    );
  }

  /// Fit sûr : bounds élargies si besoin + maxZoom + résultat fini.
  static MapCamera? safeFitBounds({
    required MapCamera camera,
    required LatLngBounds bounds,
    double maxFitZoom = 16,
  }) {
    final safeBounds = expandIfDegenerate(bounds);
    final fitted = CameraFit.bounds(
      bounds: safeBounds,
      maxZoom: maxFitZoom.clamp(minZoom, maxZoom),
      padding: const EdgeInsets.all(40),
    ).fit(camera);

    final zoom = sanitizeZoom(fitted.zoom, fallback: camera.zoom);
    if (!isFiniteLatLngZoom(
      fitted.center.latitude,
      fitted.center.longitude,
      zoom,
    )) {
      return null;
    }

    return camera.withPosition(center: fitted.center, zoom: zoom);
  }

  /// Miroir du correctif amont `flingDirection` (flutter_map PR #2220).
  ///
  /// Documente / teste l'expression qui créait le premier NaN :
  /// `flingOffset / flingDistance` lorsque les deux distances sont 0.
  @visibleForTesting
  static Offset safeFlingDirection({
    required Offset finalSegment,
    required Offset flingOffset,
    required Offset velocityDirection,
  }) {
    final finalSegmentDistance = finalSegment.distance;
    if (finalSegmentDistance > 0) {
      return finalSegment / finalSegmentDistance;
    }
    final flingDistance = flingOffset.distance;
    if (flingDistance > 0) {
      return flingOffset / flingDistance;
    }
    return velocityDirection;
  }

  /// Reproduction de l'expression buggée 8.3.1 (sans fallback velocity).
  @visibleForTesting
  static Offset buggyFlingDirection83({
    required Offset finalSegment,
    required Offset flingOffset,
  }) {
    final finalSegmentDistance = finalSegment.distance;
    if (finalSegmentDistance > 0) {
      return finalSegment / finalSegmentDistance;
    }
    final flingDistance = flingOffset.distance;
    return flingOffset / flingDistance;
  }
}

/// Refuse toute [MapCamera] non finie — chokepoint `MapController.moveRaw`.
///
/// Sans cela, un centre NaN (fling 0/0) atteint `DiscreteTileRange._floor`
/// et lève « Infinity or NaN toInt ».
@immutable
final class AtlasFiniteCameraConstraint extends CameraConstraint {
  const AtlasFiniteCameraConstraint();

  @override
  MapCamera? constrain(MapCamera camera) =>
      AtlasMapCameraGuard.isFiniteCamera(camera) ? camera : null;
}
