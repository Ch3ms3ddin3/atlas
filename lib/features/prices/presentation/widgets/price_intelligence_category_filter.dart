import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../domain/models/price_observation.dart';

/// Chips catégories Price Intelligence.
class PriceIntelligenceCategoryFilter extends StatelessWidget {
  const PriceIntelligenceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final PriceIntelligenceCategory? selectedCategory;
  final ValueChanged<PriceIntelligenceCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AtlasFilterChip(
            label: 'Toutes',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in PriceIntelligenceCategory.values) ...[
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
