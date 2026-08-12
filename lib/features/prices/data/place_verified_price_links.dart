/// Liens Explorer place id → slugs Price Intelligence (source unique).
///
/// Aucun montant ici — uniquement des références vers [PriceObservation.id].
abstract final class PlaceVerifiedPriceLinks {
  /// Ordre d'affichage : tarif principal (souvent adulte/étranger) puis
  /// différentiel Marocain/résident quand publié.
  static const Map<String, List<String>> byPlaceId = {
    'place-bahia': [
      'culture-palais-bahia-adulte-etranger-marrakech',
      'culture-palais-bahia-adulte-marocain-resident-marrakech',
    ],
    'place-el-badi': [
      'culture-palais-el-badi-adulte-etranger-marrakech',
      'culture-palais-el-badi-adulte-marocain-resident-marrakech',
    ],
    'place-tombeaux-saadiens': [
      'culture-tombeaux-saadiens-adulte-etranger-marrakech',
      'culture-tombeaux-saadiens-adulte-marocain-resident-marrakech',
    ],
    'place-medersa-ben-youssef': [
      'culture-medersa-ben-youssef-adulte-marrakech',
    ],
    'place-musee-dar-el-bacha': [
      'culture-dar-el-bacha-adulte-etranger-marrakech',
      'culture-dar-el-bacha-adulte-marocain-resident-marrakech',
    ],
    'place-maison-de-la-photographie': [
      'culture-maison-photographie-adulte-marrakech',
      'culture-maison-photographie-resident-marrakech',
    ],
    'place-macaal': [
      'culture-macaal-adulte-marrakech',
      'culture-macaal-resident-africain-marrakech',
    ],
    'place-majorelle': [
      'culture-jardin-majorelle-admission-marrakech',
      'culture-jardin-majorelle-marocain-resident-marrakech',
    ],
    'place-ysl-museum': [
      'culture-musee-ysl-admission-marrakech',
      'culture-musee-ysl-marocain-resident-marrakech',
    ],
  };

  static List<String> slugsForPlace(String placeId) =>
      List<String>.unmodifiable(byPlaceId[placeId] ?? const <String>[]);

  static bool hasLinks(String placeId) =>
      (byPlaceId[placeId]?.isNotEmpty ?? false);
}
