import 'package:flutter/material.dart';

import '../../design_system/navigation/atlas_modal.dart';
import '../../design_system/theme/atlas_spacing.dart';

/// Dialogue d'erreur lisible avec action de réessai optionnelle.
Future<void> showAtlasErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? retryLabel,
  VoidCallback? onRetry,
}) {
  return showAtlasDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: Text(retryLabel ?? 'Réessayer'),
            ),
        ],
      );
    },
  );
}

/// Explication courte hors ligne (bandeau ou carte).
class AtlasOfflineNotice extends StatelessWidget {
  const AtlasOfflineNotice({
    super.key,
    this.message =
        'Hors ligne — Atlas continue avec vos données locales. '
        'La synchronisation reprendra automatiquement.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.lg,
        vertical: AtlasSpacing.md,
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran de repli pour une erreur inattendue (ErrorWidget).
class AtlasErrorFallback extends StatelessWidget {
  const AtlasErrorFallback({
    super.key,
    this.details,
    this.onRetry,
  });

  final String? details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AtlasSpacing.xl),
              Text(
                'Une erreur inattendue est survenue',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),
              Text(
                'Atlas a rencontré un problème. '
                'Réessayez ou signalez-le via « Signaler un problème ».',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (details != null && details!.isNotEmpty) ...[
                const SizedBox(height: AtlasSpacing.lg),
                Text(
                  details!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AtlasSpacing.xxl),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// SnackBar de succès cohérent.
void showAtlasSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
