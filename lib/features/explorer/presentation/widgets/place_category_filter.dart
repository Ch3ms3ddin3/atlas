import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/place_mapper.dart';
import '../../domain/models/place_models.dart';

/// Filtres par catégorie — défilement horizontal fluide.
class PlaceCategoryFilter extends StatelessWidget {
  const PlaceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onCategorySelected;

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
          AtlasFilterChip(
            label: 'Toutes',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in PlaceCategory.values) ...[
            const SizedBox(width: AtlasSpacing.md),
            AtlasFilterChip(
              label: PlaceMapper.categoryLabels[category]!,
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
