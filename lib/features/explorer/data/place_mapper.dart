import '../../../core/location/location_constants.dart';
import '../../home/domain/models/home_models.dart';
import '../../map/data/map_search_text.dart';
import '../domain/models/place_models.dart';
import 'place_catalog.dart';

/// Filtre le catalogue et convertit vers les modèles d'affichage.
abstract final class PlaceMapper {
  static const categoryLabels = {
    PlaceCategory.jardin: 'Jardin',
    PlaceCategory.monument: 'Monument',
    PlaceCategory.restaurant: 'Restaurant',
    PlaceCategory.cafe: 'Café',
    PlaceCategory.musee: 'Musée',
    PlaceCategory.hammam: 'Hammam',
    PlaceCategory.plage: 'Plage',
    PlaceCategory.souk: 'Souk',
  };

  static const sortLabels = {
    PlaceSort.catalog: 'Ordre Atlas',
    PlaceSort.nameAsc: 'Nom A–Z',
    PlaceSort.neighborhood: 'Quartier',
    PlaceSort.priceLevel: 'Prix',
    PlaceSort.editorsPick: 'Sélection',
  };

  static String resolveCityName(
    String? cityName, {
    Iterable<PlaceGuide>? guides,
  }) {
    if (cityName == null || cityName.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }

    final normalized = cityName.trim().toLowerCase();
    final catalog = guides ?? PlaceCatalog.guides;
    final knownCities = catalog
        .map((guide) => guide.cityName.toLowerCase())
        .toSet();

    if (knownCities.contains(normalized)) {
      return _canonicalCityName(normalized, catalog);
    }

    return LocationConstants.fallbackCity;
  }

  /// Si le texte de recherche est un libellé/nom de catégorie (ex. « restaurant »),
  /// renvoie cette catégorie — permet d'ignorer une puce conflictuelle (ex. Hammam).
  static PlaceCategory? categoryMatchingSearch(String text) {
    final needle = MapSearchText.normalize(text);
    if (needle.isEmpty) return null;
    for (final category in PlaceCategory.values) {
      final label = MapSearchText.normalize(categoryLabels[category]!);
      if (needle == label || needle == category.name) {
        return category;
      }
    }
    return null;
  }

  /// Filtre puis trie selon [PlaceSearchQuery.sort].
  ///
  /// Recherche accent-insensible (même normalisation que la Carte). Un texte qui
  /// correspond à une catégorie prime sur [PlaceSearchQuery.category] conflictuel.
  ///
  /// Avec une requête texte et le tri [PlaceSort.catalog], les matches sur le
  /// **nom** passent avant les matches résumé-only (pas un score de popularité).
  static List<PlaceGuide> filter(
    PlaceSearchQuery query, {
    List<PlaceGuide>? source,
  }) {
    final catalog = source ?? PlaceCatalog.guides;
    final cityName = _effectiveCityName(query, catalog);
    final categoryFromText = categoryMatchingSearch(query.text);
    final effectiveCategory = categoryFromText ?? query.category;
    // Catégorie déduite du texte → filtre catégorie seul (pas de AND haystack).
    final normalizedQuery = categoryFromText != null
        ? ''
        : MapSearchText.normalize(query.text);

    final filtered = catalog.where((guide) {
      if (guide.cityName.toLowerCase() != cityName.toLowerCase()) {
        return false;
      }
      if (effectiveCategory != null && guide.category != effectiveCategory) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      return MapSearchText.placeMatches(
        query: normalizedQuery,
        name: guide.name,
        summary: guide.summary,
        neighborhood: guide.neighborhood,
        categoryLabel: guide.categoryLabel,
        categoryEnumName: guide.category.name,
        placeId: guide.id,
      );
    }).toList();

    // Requête active + ordre Atlas → pertinence nom d'abord (stable sinon).
    if (normalizedQuery.isNotEmpty && query.sort == PlaceSort.catalog) {
      return _rankBySearchRelevance(filtered, normalizedQuery);
    }

    return sortPlaces(filtered, query.sort);
  }

  /// Classe les résultats : préfixe/nom > quartier/catégorie > résumé.
  static List<PlaceGuide> _rankBySearchRelevance(
    List<PlaceGuide> places,
    String normalizedQuery,
  ) {
    if (places.length < 2) return places;

    final indexed = [
      for (var i = 0; i < places.length; i++) (index: i, place: places[i]),
    ];
    indexed.sort((a, b) {
      final rankA = MapSearchText.relevanceRank(
        query: normalizedQuery,
        name: a.place.name,
        summary: a.place.summary,
        neighborhood: a.place.neighborhood,
        categoryLabel: a.place.categoryLabel,
        placeId: a.place.id,
      );
      final rankB = MapSearchText.relevanceRank(
        query: normalizedQuery,
        name: b.place.name,
        summary: b.place.summary,
        neighborhood: b.place.neighborhood,
        categoryLabel: b.place.categoryLabel,
        placeId: b.place.id,
      );
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.index.compareTo(b.index);
    });
    return [for (final entry in indexed) entry.place];
  }

  /// Trie une liste déjà filtrée.
  ///
  /// [PlaceSort.catalog] : ordre source, avec les sélections Atlas en tête
  /// (partition stable — curation éditoriale, pas un score de popularité).
  static List<PlaceGuide> sortPlaces(List<PlaceGuide> places, PlaceSort sort) {
    if (places.length < 2) {
      return places;
    }

    switch (sort) {
      case PlaceSort.catalog:
        return _editorsPickFirstStable(places);
      case PlaceSort.nameAsc:
        final sorted = List<PlaceGuide>.from(places)
          ..sort((a, b) => a.name.compareTo(b.name));
        return sorted;
      case PlaceSort.neighborhood:
        final sorted = List<PlaceGuide>.from(places)
          ..sort((a, b) {
            final byNeighborhood = a.neighborhood.compareTo(b.neighborhood);
            if (byNeighborhood != 0) return byNeighborhood;
            return a.name.compareTo(b.name);
          });
        return sorted;
      case PlaceSort.priceLevel:
        final sorted = List<PlaceGuide>.from(places)
          ..sort((a, b) {
            final byPrice = _priceLevelRank(
              a.priceLevel,
            ).compareTo(_priceLevelRank(b.priceLevel));
            if (byPrice != 0) return byPrice;
            return a.name.compareTo(b.name);
          });
        return sorted;
      case PlaceSort.editorsPick:
        final sorted = List<PlaceGuide>.from(places)
          ..sort((a, b) {
            if (a.isEditorsPick != b.isEditorsPick) {
              return a.isEditorsPick ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          });
        return sorted;
    }
  }

  /// Sélections Atlas d'abord, sans réordonner à l'intérieur de chaque groupe.
  static List<PlaceGuide> _editorsPickFirstStable(List<PlaceGuide> places) {
    if (!places.any((place) => place.isEditorsPick)) {
      return places;
    }
    final picks = <PlaceGuide>[];
    final rest = <PlaceGuide>[];
    for (final place in places) {
      if (place.isEditorsPick) {
        picks.add(place);
      } else {
        rest.add(place);
      }
    }
    return [...picks, ...rest];
  }

  static PlaceGuide? findById(String id, {List<PlaceGuide>? source}) {
    final catalog = source ?? PlaceCatalog.guides;
    for (final guide in catalog) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  static RecommendedPlaceData toRecommendedPlaceData(PlaceGuide guide) {
    return RecommendedPlaceData(
      id: guide.id,
      name: guide.name,
      category: guide.categoryLabel,
      distanceLabel: guide.neighborhood,
      priceLevel: guide.priceLevel,
      isEditorsPick: guide.isEditorsPick,
      imageColor: guide.imageColor,
    );
  }

  static String _effectiveCityName(
    PlaceSearchQuery query,
    Iterable<PlaceGuide> catalog,
  ) {
    if (!query.strictCity) {
      return resolveCityName(query.cityName, guides: catalog);
    }
    if (query.cityName == null || query.cityName!.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }
    return query.cityName!.trim();
  }

  static int _priceLevelRank(String priceLevel) {
    final normalized = priceLevel.trim().toLowerCase();
    if (normalized.contains('gratuit')) return 0;
    final euroCount = '€'.allMatches(priceLevel).length;
    if (euroCount > 0) return euroCount;
    return 99;
  }

  static String _canonicalCityName(
    String normalizedCity,
    Iterable<PlaceGuide> guides,
  ) {
    for (final guide in guides) {
      if (guide.cityName.toLowerCase() == normalizedCity) {
        return guide.cityName;
      }
    }
    return LocationConstants.fallbackCity;
  }

  /// Catégories réellement présentes dans [places], ordre enum stable.
  static List<PlaceCategory> categoriesPresentIn(Iterable<PlaceGuide> places) {
    final present = <PlaceCategory>{};
    for (final place in places) {
      present.add(place.category);
    }
    return [
      for (final category in PlaceCategory.values)
        if (present.contains(category)) category,
    ];
  }
}
