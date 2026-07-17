import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../../design_system/motion/atlas_haptics.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/atlas_map_models.dart';

/// Implémentation flutter_map + OSM — isolée du domaine.
class AtlasFlutterMapView extends StatelessWidget {
  const AtlasFlutterMapView({
    super.key,
    required this.camera,
    required this.markers,
    required this.tileProvider,
    required this.mapController,
    required this.onMarkerTap,
    this.selectedPlaceId,
    this.userLatitude,
    this.userLongitude,
  });

  final AtlasMapCamera camera;
  final List<AtlasMapMarker> markers;
  final AtlasMapTileProvider tileProvider;
  final MapController mapController;
  final ValueChanged<AtlasMapMarker> onMarkerTap;
  final String? selectedPlaceId;
  final double? userLatitude;
  final double? userLongitude;

  static const clusterMaxZoom = 14.0;

  /// Active les tuiles silencieuses (tests) — pas de requêtes réseau.
  @visibleForTesting
  static bool useSilentTiles = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flutterMarkers = [
      for (final marker in markers)
        Marker(
          key: ValueKey(marker.placeId),
          point: LatLng(marker.latitude, marker.longitude),
          width: 48,
          height: 48,
          child: Semantics(
            button: true,
            label: marker.isFavorite
                ? '${marker.name}, favori'
                : marker.name,
            child: _PlaceMarkerPin(
              isFavorite: marker.isFavorite,
              isSelected: marker.placeId == selectedPlaceId,
              onTap: () {
                AtlasHaptics.selection();
                onMarkerTap(marker);
              },
            ),
          ),
        ),
    ];

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(camera.latitude, camera.longitude),
        initialZoom: camera.zoom,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        for (final layer in tileProvider.layers)
          TileLayer(
            urlTemplate: layer.urlTemplate,
            userAgentPackageName: layer.userAgentPackageName,
            tileProvider:
                useSilentTiles ? _SilentTileProvider() : NetworkTileProvider(),
            errorTileCallback: (_, error, _) {
              assert(() {
                debugPrint('Atlas map tile error: $error');
                return true;
              }());
            },
          ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 48,
            disableClusteringAtZoom: clusterMaxZoom.round(),
            size: const Size(40, 40),
            markers: flutterMarkers,
            builder: (context, clusterMarkers) {
              return AnimatedContainer(
                duration: AtlasMotion.navAnimationDuration,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AtlasColors.terracotta,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${clusterMarkers.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        if (userLatitude != null && userLongitude != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(userLatitude!, userLongitude!),
                width: 22,
                height: 22,
                child: Semantics(
                  label: 'Votre position',
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(tileProvider.attribution),
          ],
        ),
      ],
    );
  }
}

class _SilentTileProvider extends TileProvider {
  static final _transparent = MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _transparent;
  }
}

class _PlaceMarkerPin extends StatefulWidget {
  const _PlaceMarkerPin({
    required this.isFavorite,
    required this.isSelected,
    required this.onTap,
  });

  final bool isFavorite;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PlaceMarkerPin> createState() => _PlaceMarkerPinState();
}

class _PlaceMarkerPinState extends State<_PlaceMarkerPin> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isFavorite ? AtlasColors.terracotta : AtlasColors.midnightBlue;
    final selected = widget.isSelected || _pressed;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: selected ? 1.18 : 1,
        duration: AtlasMotion.navAnimationDuration,
        curve: AtlasMotion.curveSpring,
        child: AnimatedContainer(
          duration: AtlasMotion.navAnimationDuration,
          curve: AtlasMotion.curveDefault,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.28 : 0.2),
                blurRadius: selected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.place,
            color: Colors.white,
            size: AtlasSpacing.xl,
          ),
        ),
      ),
    );
  }
}
