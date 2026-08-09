import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../domain/models/atlas_event.dart';

/// Barre de filtres catégorie + ville pour l'agenda.
///
/// N'expose que les [availableCategories] réellement présentes dans le catalogue
/// chargé — pas de chips « festivals / sport » vides trompeurs.
class EventFiltersBar extends StatelessWidget {
  const EventFiltersBar({
    super.key,
    required this.selectedCategory,
    required this.selectedCity,
    required this.onCategorySelected,
    required this.onCitySelected,
    required this.availableCategories,
  });

  final EventCategory? selectedCategory;
  final String? selectedCity;
  final ValueChanged<EventCategory?> onCategorySelected;
  final ValueChanged<String?> onCitySelected;
  final List<EventCategory> availableCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCategoryFilters = availableCategories.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCategoryFilters) ...[
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
              for (final category in availableCategories)
                AtlasFilterChip(
                  label: category.labelFr,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.lg),
        ],
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
