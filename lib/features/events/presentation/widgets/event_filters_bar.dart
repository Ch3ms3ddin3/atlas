import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../domain/models/atlas_event.dart';

/// Barre de filtres catégorie + ville pour l'agenda.
class EventFiltersBar extends StatelessWidget {
  const EventFiltersBar({
    super.key,
    required this.selectedCategory,
    required this.selectedCity,
    required this.onCategorySelected,
    required this.onCitySelected,
  });

  final EventCategory? selectedCategory;
  final String? selectedCity;
  final ValueChanged<EventCategory?> onCategorySelected;
  final ValueChanged<String?> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catégorie', style: theme.textTheme.labelLarge),
        const SizedBox(height: AtlasSpacing.sm),
        Wrap(
          spacing: AtlasSpacing.sm,
          runSpacing: AtlasSpacing.sm,
          children: [
            AtlasFilterChip(
              label: 'Toutes',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
            for (final category in EventCategory.values)
              AtlasFilterChip(
                label: category.labelFr,
                isSelected: selectedCategory == category,
                onTap: () => onCategorySelected(category),
              ),
          ],
        ),
        const SizedBox(height: AtlasSpacing.lg),
        Text('Ville', style: theme.textTheme.labelLarge),
        const SizedBox(height: AtlasSpacing.sm),
        Wrap(
          spacing: AtlasSpacing.sm,
          runSpacing: AtlasSpacing.sm,
          children: [
            AtlasFilterChip(
              label: 'National + toutes',
              isSelected: selectedCity == null,
              onTap: () => onCitySelected(null),
            ),
            for (final city in MoroccoCities.supportedNames)
              AtlasFilterChip(
                label: city,
                isSelected: selectedCity == city,
                onTap: () => onCitySelected(city),
              ),
          ],
        ),
      ],
    );
  }
}
