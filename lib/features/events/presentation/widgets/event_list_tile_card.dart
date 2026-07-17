import 'package:flutter/material.dart';

import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/atlas_event.dart';
import 'event_reliability_chip.dart';

/// Ligne compacte d'événement pour Home et liste agenda.
class EventListTileCard extends StatelessWidget {
  const EventListTileCard({
    super.key,
    required this.event,
    this.onTap,
    this.compact = false,
  });

  final AtlasEvent event;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = CasablancaDateFormatter.formatShortDate(event.startAt);
    final scope = event.isNational
        ? 'National'
        : (event.cityName ?? '');

    return AtlasCard(
      emphasis: compact ? AtlasCardEmphasis.compact : AtlasCardEmphasis.standard,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (event.reliability != EventReliability.confirmed) ...[
                const SizedBox(width: AtlasSpacing.sm),
                EventReliabilityChip(reliability: event.reliability),
              ],
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            '$dateLabel · ${event.categoryLabel} · $scope',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AtlasTextStyles.helper(theme.colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}
