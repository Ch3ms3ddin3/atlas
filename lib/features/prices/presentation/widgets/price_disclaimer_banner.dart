import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';

/// Avertissement légal affiché sur la liste et le détail des prix.
class PriceDisclaimerBanner extends StatelessWidget {
  const PriceDisclaimerBanner({super.key});

  static const text =
      'Prix indicatifs — ils peuvent varier selon la ville, la saison '
      'et le prestataire.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      emphasis: AtlasCardEmphasis.compact,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AtlasSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
