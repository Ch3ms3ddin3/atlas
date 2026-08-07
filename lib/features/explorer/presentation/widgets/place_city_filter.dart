import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < MoroccoCities.supportedNames.length; i++) ...[
            if (i > 0) const SizedBox(width: AtlasSpacing.md),
            AtlasFilterChip(
              label: MoroccoCities.supportedNames[i],
              isSelected:
                  selectedCity == MoroccoCities.supportedNames[i],
              onTap: () => onCitySelected(MoroccoCities.supportedNames[i]),
            ),
          ],
        ],
      ),
    );
  }
}
