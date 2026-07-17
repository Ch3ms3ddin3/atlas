import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';
import '../theme/atlas_text_styles.dart';

/// En-tête de page réutilisable — titre, sous-titre et note optionnelle.
class AtlasPageHeader extends StatelessWidget {
  const AtlasPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
            height: 1.4,
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            footnote!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AtlasTextStyles.metadata(theme.colorScheme),
            ),
          ),
        ],
      ],
    );
  }
}
