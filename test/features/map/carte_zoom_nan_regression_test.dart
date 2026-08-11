import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/map/data/atlas_map_camera_guard.dart';
import 'package:atlas/features/map/domain/atlas_map_models.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUp(() {
    AtlasFlutterMapView.useSilentTiles = true;
  });

  const cafeCoords = <String, (double, double)>{
    'place-bacha-coffee': (31.631521, -7.992561),
    'place-simple-specialty-coffee': (31.631583, -7.990912),
    'place-cafe-des-epices': (31.629062, -7.987323),
    'place-kartell-kollektiv': (31.636385, -8.009579),
    'place-cafe-clock': (31.613029, -7.987289),
  };

  group('AtlasMapCameraGuard', () {
    test('sanitizeZoom rejects NaN and Infinity', () {
      expect(AtlasMapCameraGuard.sanitizeZoom(double.nan), 12);
      expect(AtlasMapCameraGuard.sanitizeZoom(double.infinity), 12);
      expect(AtlasMapCameraGuard.sanitizeZoom(double.negativeInfinity), 12);
      expect(AtlasMapCameraGuard.sanitizeZoom(20), 18);
      expect(AtlasMapCameraGuard.sanitizeZoom(3), 5);
      expect(AtlasMapCameraGuard.sanitizeZoom(14), 14);
    });

    test('isFiniteLatLngZoom rejects non-finite inputs', () {
      expect(
        AtlasMapCameraGuard.isFiniteLatLngZoom(31.6, -8.0, 12),
        isTrue,
      );
      expect(
        AtlasMapCameraGuard.isFiniteLatLngZoom(double.nan, -8.0, 12),
        isFalse,
      );
      expect(
        AtlasMapCameraGuard.isFiniteLatLngZoom(31.6, -8.0, double.infinity),
        isFalse,
      );
    });

    test('expandIfDegenerate widens zero-area bounds', () {
      const point = LatLng(31.631521, -7.992561);
      final degenerate = LatLngBounds(point, point);
      expect(AtlasMapCameraGuard.isDegenerateBounds(degenerate), isTrue);

      final expanded = AtlasMapCameraGuard.expandIfDegenerate(degenerate);
      expect(AtlasMapCameraGuard.isDegenerateBounds(expanded), isFalse);
      expect(expanded.north - expanded.south, greaterThan(0));
      expect(expanded.east - expanded.west, greaterThan(0));
    });

    test('safeFitBounds never returns non-finite zoom for point bounds', () {
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(31.63, -7.99),
        zoom: 12,
        rotation: 0,
        nonRotatedSize: const Size(390, 700),
        minZoom: AtlasMapCameraGuard.minZoom,
        maxZoom: AtlasMapCameraGuard.maxZoom,
      );
      const point = LatLng(31.631521, -7.992561);
      final fitted = AtlasMapCameraGuard.safeFitBounds(
        camera: camera,
        bounds: LatLngBounds(point, point),
      );
      expect(fitted, isNotNull);
      expect(fitted!.zoom.isFinite, isTrue);
      expect(fitted.center.latitude.isFinite, isTrue);
      expect(fitted.center.longitude.isFinite, isTrue);
      expect(fitted.zoom, lessThanOrEqualTo(AtlasMapCameraGuard.maxZoom));
      expect(() => fitted.zoom.ceil(), returnsNormally);
      expect(() => fitted.zoom.round(), returnsNormally);
    });

    test('safeFitBounds keeps café cluster bounds finite through zoom levels', () {
      final points = cafeCoords.values
          .map((c) => LatLng(c.$1, c.$2))
          .toList(growable: false);
      final bounds = LatLngBounds.fromPoints(points);

      for (final zoom in <double>[8, 10, 12, 14, 16, 18]) {
        final camera = MapCamera(
          crs: const Epsg3857(),
          center: bounds.center,
          zoom: zoom,
          rotation: 0,
          nonRotatedSize: const Size(390, 700),
          minZoom: AtlasMapCameraGuard.minZoom,
          maxZoom: AtlasMapCameraGuard.maxZoom,
        );
        final fitted = AtlasMapCameraGuard.safeFitBounds(
          camera: camera,
          bounds: bounds,
        );
        expect(fitted, isNotNull, reason: 'zoom $zoom');
        expect(fitted!.zoom.isFinite, isTrue, reason: 'zoom $zoom');
        expect(() => fitted.zoom.ceil(), returnsNormally);
      }
    });

    test('raw CameraFit.bounds on zero-area is unsafe (assert or non-finite)', () {
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(31.63, -7.99),
        zoom: 12,
        rotation: 0,
        nonRotatedSize: const Size(390, 700),
      );
      const point = LatLng(31.631521, -7.992561);
      expect(
        () => CameraFit.bounds(
          bounds: LatLngBounds(point, point),
        ).fit(camera),
        throwsA(
          anyOf(
            isA<AssertionError>(),
            isA<UnsupportedError>(),
          ),
        ),
      );
      final guarded = AtlasMapCameraGuard.safeFitBounds(
        camera: camera,
        bounds: LatLngBounds(point, point),
      );
      expect(guarded, isNotNull);
      expect(guarded!.zoom.isFinite, isTrue);
      expect(() => guarded.zoom.ceil(), returnsNormally);
    });
  });

  group('flutter_map 8.3.1 zero-length fling → first NaN', () {
    test('buggy expression creates NaN direction (root cause)', () {
      // Exact 8.3.1 path when velocity is high but tracked deltas are zero
      // (common at pinch/zoom-out release on a physical touchscreen).
      final direction = AtlasMapCameraGuard.buggyFlingDirection83(
        finalSegment: Offset.zero,
        flingOffset: Offset.zero,
      );
      expect(direction.dx.isNaN, isTrue, reason: '0/0 → NaN dx');
      expect(direction.dy.isNaN, isTrue, reason: '0/0 → NaN dy');
    });

    test('safeFlingDirection falls back to velocity (upstream PR #2220)', () {
      const velocity = Offset(120, -40);
      final direction = AtlasMapCameraGuard.safeFlingDirection(
        finalSegment: Offset.zero,
        flingOffset: Offset.zero,
        velocityDirection: velocity / velocity.distance,
      );
      expect(direction.dx.isFinite, isTrue);
      expect(direction.dy.isFinite, isTrue);
      expect(direction.distance, closeTo(1.0, 1e-9));
    });

    test('NaN fling end offset poisons projected pixel → tile _floor crash', () {
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(31.63, -7.99),
        zoom: 14,
        rotation: 0,
        nonRotatedSize: const Size(390, 700),
        minZoom: AtlasMapCameraGuard.minZoom,
        maxZoom: AtlasMapCameraGuard.maxZoom,
      );

      final nanDirection = AtlasMapCameraGuard.buggyFlingDirection83(
        finalSegment: Offset.zero,
        flingOffset: Offset.zero,
      );
      final distance = (Offset.zero & camera.nonRotatedSize).shortestSide;
      final flingEnd = Offset.zero + nanDirection * distance;
      expect(flingEnd.dx.isNaN, isTrue);

      final poisonedPoint =
          camera.projectAtZoom(camera.center) + flingEnd;
      expect(poisonedPoint.dx.isNaN, isTrue);

      final poisonedCenter = camera.unprojectAtZoom(poisonedPoint);
      expect(poisonedCenter.latitude.isNaN, isTrue);
      expect(poisonedCenter.longitude.isNaN, isTrue);

      final poisonedCamera = camera.withPosition(center: poisonedCenter);
      final pixelBounds = poisonedCamera.pixelBounds;
      expect(
        !pixelBounds.left.isFinite || !pixelBounds.top.isFinite,
        isTrue,
      );

      // Crash site observed on device / upstream #2227:
      // DiscreteTileRange.fromPixelBounds → point.dx.floor() → toInt
      expect(
        () => pixelBounds.left.floor(),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Infinity or NaN toInt'),
          ),
        ),
      );
    });

    test('AtlasFiniteCameraConstraint rejects poisoned camera', () {
      final camera = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(31.63, -7.99),
        zoom: 14,
        rotation: 0,
        nonRotatedSize: const Size(390, 700),
        minZoom: AtlasMapCameraGuard.minZoom,
        maxZoom: AtlasMapCameraGuard.maxZoom,
      );
      final poisoned = camera.withPosition(
        center: const LatLng(double.nan, double.nan),
      );
      expect(AtlasMapCameraGuard.finiteCameraConstraint.constrain(poisoned), isNull);
      expect(AtlasMapCameraGuard.finiteCameraConstraint.constrain(camera), camera);
    });
  });

  group('Marrakech café cluster zoom regression', () {
    List<AtlasMapMarker> cafeMarkers() => [
          for (final entry in cafeCoords.entries)
            AtlasMapMarker(
              placeId: entry.key,
              name: entry.key,
              latitude: entry.value.$1,
              longitude: entry.value.$2,
              category: PlaceCategory.cafe,
              isFavorite: false,
            ),
        ];

    test('five café fixture markers are finite', () {
      final markers = cafeMarkers();
      expect(markers, hasLength(5));
      for (final marker in markers) {
        expect(marker.latitude.isFinite, isTrue);
        expect(marker.longitude.isFinite, isTrue);
      }
    });

    test('native zoomToBoundsOnClick stays disabled', () {
      expect(AtlasFlutterMapView.zoomToBoundsOnClick, isFalse);
    });

    testWidgets(
      'zoom-out transition + NaN fling move stays finite with café markers',
      (tester) async {
        final controller = MapController();
        final markers = cafeMarkers();
        expect(markers, hasLength(5));

        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AtlasFlutterMapView(
                camera: const AtlasMapCamera(
                  latitude: 31.63,
                  longitude: -7.99,
                  zoom: 12,
                ),
                markers: markers,
                tileProvider: const OsmAtlasMapTileProvider(),
                mapController: controller,
                onMarkerTap: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);

        // Zoom-in past cluster threshold, then zoom-out (device repro path).
        for (final zoom in <double>[10, 12, 14, 16, 15, 13, 11, 9, 8]) {
          controller.move(const LatLng(31.63, -7.99), zoom);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          expect(controller.camera.zoom.isFinite, isTrue);
          expect(controller.camera.center.latitude.isFinite, isTrue);
          expect(() => controller.camera.zoom.ceil(), returnsNormally);
          expect(() => controller.camera.zoom.round(), returnsNormally);
        }

        // Simulate the poisoned fling frame that 8.3.1 would commit.
        // FiniteCameraConstraint must reject it — camera stays finite.
        final before = controller.camera;
        final accepted = controller.move(
          const LatLng(double.nan, double.nan),
          before.zoom,
        );
        expect(accepted, isFalse);
        await tester.pump();
        expect(controller.camera.center.latitude.isFinite, isTrue);
        expect(controller.camera.center.longitude.isFinite, isTrue);
        expect(controller.camera.zoom.isFinite, isTrue);
        expect(() => controller.camera.zoom.ceil(), returnsNormally);
        expect(find.byType(AtlasFlutterMapView), findsOneWidget);
        expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      },
    );
  });
}
