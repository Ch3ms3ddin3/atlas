import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';

/// Section titre + puces pour la page détail d'un prix.
class PriceDetailSection extends StatelessWidget {
  const PriceDetailSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AtlasSpacing.md),
        for (final item in items) ...[
          _BulletItem(text: item),
          const SizedBox(height: AtlasSpacing.sm),
        ],
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AtlasSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
