import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import 'explorer_chip_scroller.dart';

/// Sélecteur de ville — défilement horizontal avec momentum iOS.
class PlaceCityFilter extends StatelessWidget {
  const PlaceCityFilter({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  final String selectedCity;
  final ValueChanged<String> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return ExplorerChipScroller(
      children: [
        for (final city in MoroccoCities.supportedNames)
          AtlasFilterChip(
            label: city,
            isSelected: selectedCity == city,
            onTap: () => onCitySelected(city),
          ),
      ],
    );
  }
}
