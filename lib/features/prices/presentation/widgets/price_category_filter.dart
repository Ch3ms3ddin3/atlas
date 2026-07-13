import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/price_mapper.dart';
import '../../domain/models/price_models.dart';

/// Filtres par catégorie pour la liste des prix.
class PriceCategoryFilter extends StatelessWidget {
  const PriceCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final PriceCategory? selectedCategory;
  final ValueChanged<PriceCategory?> onCategorySelected;

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
          for (final category in PriceCategory.values) ...[
            const SizedBox(width: AtlasSpacing.sm),
            AtlasFilterChip(
              label: PriceMapper.categoryLabels[category]!,
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
