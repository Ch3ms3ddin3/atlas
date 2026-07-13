import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../data/procedure_mapper.dart';
import '../../domain/models/procedure_models.dart';

/// Filtres par catégorie pour la liste des démarches.
class ProcedureCategoryFilter extends StatelessWidget {
  const ProcedureCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final ProcedureCategory? selectedCategory;
  final ValueChanged<ProcedureCategory?> onCategorySelected;

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
          for (final category in ProcedureCategory.values) ...[
            const SizedBox(width: AtlasSpacing.sm),
            AtlasFilterChip(
              label: ProcedureMapper.categoryLabels[category]!,
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
