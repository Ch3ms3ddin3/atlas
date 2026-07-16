import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/place_models.dart';
import 'place_detail_section.dart';

/// Horaires — rendu uniquement si [PlaceGuide.hasOpeningHours].
class PlaceOpeningHoursSection extends StatelessWidget {
  const PlaceOpeningHoursSection({
    super.key,
    required this.openingHours,
  });

  final PlaceOpeningHours openingHours;

  @override
  Widget build(BuildContext context) {
    if (!openingHours.hasContent) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceDetailSectionHeader(title: 'Horaires'),
        AtlasCard(
          emphasis: AtlasCardEmphasis.compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < openingHours.entries.length; i++) ...[
                if (i > 0) const SizedBox(height: AtlasSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        openingHours.entries[i].dayLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      openingHours.entries[i].hoursLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (openingHours.note != null) ...[
                if (openingHours.entries.isNotEmpty)
                  const SizedBox(height: AtlasSpacing.md),
                Text(
                  openingHours.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
