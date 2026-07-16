import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/place_mapper.dart';
import '../../domain/models/place_models.dart';

/// Menu de tri compact pour la liste Explorer.
class PlaceSortButton extends StatelessWidget {
  const PlaceSortButton({
    super.key,
    required this.selectedSort,
    required this.onSortSelected,
  });

  final PlaceSort selectedSort;
  final ValueChanged<PlaceSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<PlaceSort>(
      initialValue: selectedSort,
      tooltip: 'Trier',
      onSelected: onSortSelected,
      itemBuilder: (context) => [
        for (final sort in PlaceSort.values)
          PopupMenuItem(
            value: sort,
            child: Text(PlaceMapper.sortLabels[sort]!),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 18,
              color: AtlasTextStyles.subtitle(theme.colorScheme),
            ),
            const SizedBox(width: 6),
            Text(
              PlaceMapper.sortLabels[selectedSort]!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AtlasTextStyles.subtitle(theme.colorScheme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
