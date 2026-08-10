import 'package:flutter/foundation.dart';

/// Covers locaux vérifiés — hors inventaire inventé.
///
/// Sources et licences : `assets/explorer_place_covers/_ledger/ATTRIBUTION.md`.
///
/// Exclus volontairement :
/// - `place-majorelle` : aucun cover local vérifié dans le ledger
abstract final class PlaceCoverAssets {
  static const _assetByPlaceId = <String, String>{
    'place-bahia':
        'assets/explorer_place_covers/place-photos/place-bahia/cover.webp',
    'place-jemaa-el-fna':
        'assets/explorer_place_covers/place-photos/place-jemaa-el-fna/cover.webp',
    'place-ysl-museum':
        'assets/explorer_place_covers/place-photos/place-ysl-museum/cover.webp',
    'place-hammam-marrakech':
        'assets/explorer_place_covers/place-photos/place-hammam-marrakech/cover.webp',
    'place-hassan-ii':
        'assets/explorer_place_covers/place-photos/place-hassan-ii/cover.webp',
    'place-corniche':
        'assets/explorer_place_covers/place-photos/place-corniche/cover.webp',
    'place-marche-central':
        'assets/explorer_place_covers/place-photos/place-marche-central/cover.webp',
    'place-musee-judaisme':
        'assets/explorer_place_covers/place-photos/place-musee-judaisme/cover.webp',
    'place-habous':
        'assets/explorer_place_covers/place-photos/place-habous/cover.webp',
    'place-tour-hassan':
        'assets/explorer_place_covers/place-photos/place-tour-hassan/cover.webp',
    'place-oudayas':
        'assets/explorer_place_covers/place-photos/place-oudayas/cover.webp',
    'place-chellah':
        'assets/explorer_place_covers/place-photos/place-chellah/cover.webp',
    'place-musee-rabat':
        'assets/explorer_place_covers/place-photos/place-musee-rabat/cover.webp',
    'place-plage-rabat':
        'assets/explorer_place_covers/place-photos/place-plage-rabat/cover.webp',
  };

  /// Chemin asset bundle, ou `null` si aucun cover vérifié n'est expédié.
  static String? assetPathFor(String placeId) => _assetByPlaceId[placeId];

  static bool hasBundledCover(String placeId) =>
      _assetByPlaceId.containsKey(placeId);

  @visibleForTesting
  static Iterable<String> get bundledPlaceIds => _assetByPlaceId.keys;
}
