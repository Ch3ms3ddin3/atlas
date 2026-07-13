import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';

/// État vide calme — message centré sans bruit visuel.
class AtlasEmptyState extends StatelessWidget {
  const AtlasEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xxl),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
