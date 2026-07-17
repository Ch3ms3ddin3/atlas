import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Indicateur discret stale / hors ligne pour l'agenda.
class EventCatalogStatusIndicator extends StatelessWidget {
  const EventCatalogStatusIndicator({
    super.key,
    required this.loadState,
  });

  final EditorialCatalogLoadState loadState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (IconData icon, String label)? status = switch (loadState) {
      EditorialCatalogLoadState.stale => (
          Icons.cloud_off_outlined,
          'Catalogue local',
        ),
      EditorialCatalogLoadState.error => (
          Icons.wifi_off_outlined,
          'Hors ligne',
        ),
      EditorialCatalogLoadState.idle ||
      EditorialCatalogLoadState.loading ||
      EditorialCatalogLoadState.success =>
        null,
    };

    if (status == null) return const SizedBox.shrink();

    final (icon, label) = status;

    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AtlasColors.midnightBlueFaint),
          const SizedBox(width: AtlasSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AtlasColors.midnightBlueFaint,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
