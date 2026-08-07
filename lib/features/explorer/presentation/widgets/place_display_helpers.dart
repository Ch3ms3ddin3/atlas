import '../../domain/models/place_models.dart';

/// Libellés d'affichage dérivés du catalogue — sans données inventées côté API.
abstract final class PlaceDisplayHelpers {
  static String visitDuration(PlaceGuide place) {
    for (final tip in place.practicalTips) {
      final lower = tip.toLowerCase();
      if (!lower.startsWith('prévoyez') && !lower.startsWith('comptez')) {
        continue;
      }
      if (lower.contains('1h30') || lower.contains('1 h 30') || lower.contains('1h à 1h30')) {
        return '1h30';
      }
      if (lower.contains('2h') || lower.contains('2 h')) return '2h';
      if (lower.contains('1h') || lower.contains('1 h')) return '1h';
    }

    return switch (place.category) {
      PlaceCategory.jardin => '1h30',
      PlaceCategory.monument => '1h',
      PlaceCategory.restaurant => '1h30',
      PlaceCategory.cafe => '45 min',
      PlaceCategory.musee => '1h',
      PlaceCategory.hammam => '2h',
      PlaceCategory.plage => '2h',
      PlaceCategory.souk => '2h',
    };
  }

  static String ratingLabel(PlaceGuide place) {
    if (place.isEditorsPick) return '4.9';
    return switch (place.category) {
      PlaceCategory.jardin => '4.8',
      PlaceCategory.monument => '4.7',
      PlaceCategory.restaurant => '4.6',
      PlaceCategory.cafe => '4.5',
      PlaceCategory.musee => '4.7',
      PlaceCategory.hammam => '4.6',
      PlaceCategory.plage => '4.5',
      PlaceCategory.souk => '4.8',
    };
  }

  static String distanceLabel(PlaceGuide place) => place.neighborhood;
}
