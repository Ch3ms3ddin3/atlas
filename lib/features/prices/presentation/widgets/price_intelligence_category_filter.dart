import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../domain/models/price_observation.dart';

/// Chips catégories Price Intelligence — uniquement les catégories présentes.
class PriceIntelligenceCategoryFilter extends StatelessWidget {
  const PriceIntelligenceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.availableCategories,
  });

  final PriceIntelligenceCategory? selectedCategory;
  final ValueChanged<PriceIntelligenceCategory?> onCategorySelected;

  /// Catégories réellement présentes dans l'inventaire vérifié chargé.
  final List<PriceIntelligenceCategory> availableCategories;

  @override
  Widget build(BuildContext context) {
    if (availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AtlasFilterChip(
            label: 'Toutes',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in availableCategories) ...[
            const SizedBox(width: AtlasSpacing.sm),
            AtlasFilterChip(
              label: category.labelFr,
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
