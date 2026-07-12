import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';

/// Liste des alertes importantes — affichée uniquement si des alertes existent.
class ImportantAlerts extends StatelessWidget {
  const ImportantAlerts({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.onAlertDismiss,
  });

  final List<AlertData> alerts;
  final ValueChanged<AlertData>? onAlertTap;
  final ValueChanged<AlertData>? onAlertDismiss;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          _AlertCard(
            alert: alerts[i],
            onTap: () => onAlertTap?.call(alerts[i]),
            onDismiss: () => onAlertDismiss?.call(alerts[i]),
          ),
          if (i < alerts.length - 1) const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    this.onTap,
    this.onDismiss,
  });

  final AlertData alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  Color _backgroundColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.caution => const Color(0xFFFFFBF3),
      AlertSeverity.critical => const Color(0xFFFDF8F8),
      AlertSeverity.info => Colors.white,
    };
  }

  Color _accentColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.caution => AtlasColors.subtleGold,
      AlertSeverity.critical => const Color(0xFFB3261E),
      AlertSeverity.info => AtlasColors.terracotta,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(alert.severity);

    return Material(
      color: _backgroundColor(alert.severity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        side: const BorderSide(color: AtlasColors.sandMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(alert.icon, size: 20, color: accent.withValues(alpha: 0.85)),
              const SizedBox(width: AtlasSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      alert.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      'Source : ${alert.source}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Fermer',
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
