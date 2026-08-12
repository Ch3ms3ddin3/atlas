import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import 'explorer_chip_scroller.dart';

/// Sélecteur de ville — défilement horizontal avec momentum iOS.
///
/// [cities] limite les puces aux villes réellement couvertes par le catalogue
/// (beta Marrakech-first). Les villes profil non listées restent dans
/// [MoroccoCities] — on ne supprime pas leurs données.
class PlaceCityFilter extends StatelessWidget {
  const PlaceCityFilter({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
    this.cities,
  });

  final String selectedCity;
  final ValueChanged<String> onCitySelected;

  /// Villes affichées. Défaut : toutes les villes supportées du profil.
  final List<String>? cities;

  @override
  Widget build(BuildContext context) {
    final visible = cities ?? MoroccoCities.supportedNames;
    return ExplorerChipScroller(
      children: [
        for (final city in visible)
          AtlasFilterChip(
            label: city,
            isSelected: selectedCity == city,
            onTap: () => onCitySelected(city),
          ),
      ],
    );
  }
}
