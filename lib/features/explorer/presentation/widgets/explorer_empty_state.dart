import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_primary_button.dart';

/// État vide Explorer — illustration calme et suggestion claire.
class ExplorerEmptyState extends StatelessWidget {
  const ExplorerEmptyState({
    super.key,
    this.onReset,
  });

  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.section),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AtlasColors.sandMuted.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_outlined,
              size: 40,
              color: theme.colorScheme.primary.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Text(
            'Aucun lieu trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            'Essayez une autre catégorie.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasTextStyles.helper(theme.colorScheme),
              height: 1.45,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: AtlasSpacing.xl),
            AtlasSecondaryButton(
              label: 'Réinitialiser les filtres',
              onPressed: onReset,
            ),
          ],
        ],
      ),
    );
  }
}
