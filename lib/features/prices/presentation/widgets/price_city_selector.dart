import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';

/// Sélecteur de ville — uniquement les villes présentes dans les données Prix.
class PriceCitySelector extends StatelessWidget {
  const PriceCitySelector({
    super.key,
    required this.selectedCity,
    required this.dataCities,
    required this.onCitySelected,
  });

  final String selectedCity;
  final List<String> dataCities;
  final ValueChanged<String> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final cities = <String>{
      ...dataCities,
      // Keep a non-empty selection visible if it somehow lacks catalog rows.
      if (selectedCity.trim().isNotEmpty) selectedCity,
    }.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < cities.length; i++) ...[
            if (i > 0) const SizedBox(width: AtlasSpacing.sm),
            AtlasFilterChip(
              label: cities[i],
              isSelected: selectedCity == cities[i],
              onTap: () => onCitySelected(cities[i]),
            ),
          ],
        ],
      ),
    );
  }
}
