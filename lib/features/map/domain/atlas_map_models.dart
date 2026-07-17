import '../../explorer/domain/models/place_models.dart';

/// Position caméra indépendante du fournisseur de tuiles.
class AtlasMapCamera {
  const AtlasMapCamera({
    required this.latitude,
    required this.longitude,
    this.zoom = 12,
  });

  final double latitude;
  final double longitude;
  final double zoom;
}

/// Marqueur domaine — uniquement des lieux avec coordonnées valides.
class AtlasMapMarker {
  const AtlasMapMarker({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.isFavorite,
  });

  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final PlaceCategory category;
  final bool isFavorite;

  static AtlasMapMarker? fromPlace(
    PlaceGuide place, {
    required bool isFavorite,
  }) {
    if (!place.hasCoordinates) return null;
    return AtlasMapMarker(
      placeId: place.id,
      name: place.name,
      latitude: place.latitude!,
      longitude: place.longitude!,
      category: place.category,
      isFavorite: isFavorite,
    );
  }
}

/// Contrat tuiles — v1 OSM via flutter_map ; Google/Mapbox branchables plus tard.
abstract class AtlasMapTileProvider {
  String get attribution;
  List<AtlasMapTileLayer> get layers;
}

class AtlasMapTileLayer {
  const AtlasMapTileLayer({
    required this.urlTemplate,
    this.userAgentPackageName = 'com.atlas.app',
  });

  final String urlTemplate;
  final String userAgentPackageName;
}

/// Fournisseur OSM v1.
class OsmAtlasMapTileProvider implements AtlasMapTileProvider {
  const OsmAtlasMapTileProvider();

  @override
  String get attribution => '© OpenStreetMap contributors';

  @override
  List<AtlasMapTileLayer> get layers => const [
        AtlasMapTileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
      ];
}
