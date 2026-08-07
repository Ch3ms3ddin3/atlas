import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/place_mapper.dart';
import '../../domain/models/place_models.dart';
import 'explorer_chip_scroller.dart';

/// Filtres par catégorie — défilement horizontal fluide.
class PlaceCategoryFilter extends StatelessWidget {
  const PlaceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.favoritesOnly = false,
    this.onFavoritesToggle,
  });

  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onCategorySelected;

  /// Affiche la puce Favoris dans la même rangée scrollable.
  final bool favoritesOnly;
  final VoidCallback? onFavoritesToggle;

  @override
  Widget build(BuildContext context) {
    return ExplorerChipScroller(
      children: [
        AtlasFilterChip(
          label: 'Toutes',
          isSelected: selectedCategory == null,
          onTap: () => onCategorySelected(null),
        ),
        for (final category in PlaceCategory.values)
          AtlasFilterChip(
            label: PlaceMapper.categoryLabels[category]!,
            isSelected: selectedCategory == category,
            onTap: () => onCategorySelected(category),
          ),
        if (onFavoritesToggle != null)
          AtlasFilterChip(
            label: 'Favoris',
            isSelected: favoritesOnly,
            onTap: onFavoritesToggle!,
          ),
      ],
    );
  }
}
