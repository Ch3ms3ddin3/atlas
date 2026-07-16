import 'package:flutter/material.dart';

import '../../domain/models/place_models.dart';

/// Icône Material associée à une [PlaceCategory].
IconData placeCategoryIcon(PlaceCategory category) {
  return switch (category) {
    PlaceCategory.jardin => Icons.park_outlined,
    PlaceCategory.monument => Icons.account_balance_outlined,
    PlaceCategory.restaurant => Icons.restaurant_outlined,
    PlaceCategory.cafe => Icons.coffee_outlined,
    PlaceCategory.musee => Icons.museum_outlined,
    PlaceCategory.hammam => Icons.spa_outlined,
    PlaceCategory.plage => Icons.beach_access_outlined,
    PlaceCategory.souk => Icons.storefront_outlined,
  };
}
