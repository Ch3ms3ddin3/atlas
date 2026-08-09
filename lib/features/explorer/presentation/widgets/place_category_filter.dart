import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/place_mapper.dart';
import '../../domain/models/place_models.dart';
import 'explorer_chip_scroller.dart';

/// Filtres par catégorie — uniquement les catégories présentes dans l'inventaire.
class PlaceCategoryFilter extends StatelessWidget {
  const PlaceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.availableCategories,
    this.favoritesOnly = false,
    this.onFavoritesToggle,
  });

  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onCategorySelected;

  /// Catégories réellement présentes (ville / catalogue chargé).
  final List<PlaceCategory> availableCategories;

  /// Affiche la puce Favoris dans la même rangée scrollable.
  final bool favoritesOnly;
  final VoidCallback? onFavoritesToggle;

  @override
  Widget build(BuildContext context) {
    final selected = availableCategories.contains(selectedCategory)
        ? selectedCategory
        : null;

    return ExplorerChipScroller(
      children: [
        AtlasFilterChip(
          label: 'Toutes',
          isSelected: selected == null,
          onTap: () => onCategorySelected(null),
        ),
        for (final category in availableCategories)
          AtlasFilterChip(
            label: PlaceMapper.categoryLabels[category]!,
            isSelected: selected == category,
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
