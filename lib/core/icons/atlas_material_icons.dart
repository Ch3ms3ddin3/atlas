import 'package:flutter/material.dart';

/// Correspondance clé texte ↔ icônes Material utilisées dans les catalogues.
abstract final class AtlasMaterialIcons {
  static const _iconsByKey = <String, IconData>{
    'account_balance_outlined': Icons.account_balance_outlined,
    'apartment_outlined': Icons.apartment_outlined,
    'badge_outlined': Icons.badge_outlined,
    'bakery_dining_outlined': Icons.bakery_dining_outlined,
    'bolt_outlined': Icons.bolt_outlined,
    'card_membership_outlined': Icons.card_membership_outlined,
    'coffee_outlined': Icons.coffee_outlined,
    'content_cut_outlined': Icons.content_cut_outlined,
    'description_outlined': Icons.description_outlined,
    'directions_bus_outlined': Icons.directions_bus_outlined,
    'directions_car_outlined': Icons.directions_car_outlined,
    'flight_land_outlined': Icons.flight_land_outlined,
    'local_hospital_outlined': Icons.local_hospital_outlined,
    'local_laundry_service_outlined': Icons.local_laundry_service_outlined,
    'local_shipping_outlined': Icons.local_shipping_outlined,
    'local_taxi_outlined': Icons.local_taxi_outlined,
    'museum_outlined': Icons.museum_outlined,
    'phone_android_outlined': Icons.phone_android_outlined,
    'receipt_long_outlined': Icons.receipt_long_outlined,
    'restaurant_outlined': Icons.restaurant_outlined,
    'shopping_basket_outlined': Icons.shopping_basket_outlined,
    'tour_outlined': Icons.tour_outlined,
    'warning_amber_outlined': Icons.warning_amber_outlined,
    'work_outline': Icons.work_outline,
  };

  static IconData resolve(String? key, {IconData fallback = Icons.article_outlined}) {
    if (key == null || key.isEmpty) return fallback;
    return _iconsByKey[key] ?? fallback;
  }

  static String keyFor(IconData icon, {String fallback = 'article_outlined'}) {
    for (final entry in _iconsByKey.entries) {
      if (entry.value.codePoint == icon.codePoint &&
          entry.value.fontFamily == icon.fontFamily) {
        return entry.key;
      }
    }
    return fallback;
  }
}
