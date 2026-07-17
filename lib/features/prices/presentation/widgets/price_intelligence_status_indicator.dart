import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Indicateur discret loading / stale / offline pour Price Intelligence.
class PriceIntelligenceStatusIndicator extends StatelessWidget {
  const PriceIntelligenceStatusIndicator({
    super.key,
    required this.loadState,
  });

  final EditorialCatalogLoadState loadState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String label)? status = switch (loadState) {
      EditorialCatalogLoadState.loading => (
          Icons.sync,
          'Mise à jour…',
        ),
      EditorialCatalogLoadState.stale => (
          Icons.cloud_off_outlined,
          'Données en cache',
        ),
      EditorialCatalogLoadState.error => (
          Icons.wifi_off_outlined,
          'Hors ligne',
        ),
      EditorialCatalogLoadState.idle ||
      EditorialCatalogLoadState.success =>
        null,
    };

    if (status == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
      child: Row(
        children: [
          Icon(
            status.$1,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Text(
            status.$2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
