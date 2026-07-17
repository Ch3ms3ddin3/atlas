import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';
import '../theme/atlas_text_styles.dart';
import 'atlas_primary_button.dart';

/// État vide calme — message centré sans bruit visuel.
class AtlasEmptyState extends StatelessWidget {
  const AtlasEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off_outlined,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xl),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasTextStyles.helper(theme.colorScheme),
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AtlasSpacing.lg),
            AtlasSecondaryButton(
              label: retryLabel ?? 'Réessayer',
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
