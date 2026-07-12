import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/place_mapper.dart';
import '../../domain/models/place_models.dart';

/// Filtres par catégorie pour la liste des lieux.
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
      child: Row(
        children: [
          _CategoryChip(
            label: 'Toutes',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in PlaceCategory.values) ...[
            const SizedBox(width: AtlasSpacing.sm),
            _CategoryChip(
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.35)
            : theme.colorScheme.outlineVariant,
      ),
    );
  }
}
