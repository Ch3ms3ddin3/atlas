import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte de rappel administratif — échéance et progression.
class AdministrativeReminderCard extends StatelessWidget {
  const AdministrativeReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
  });

  final AdminReminderData reminder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(reminder.status);

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reminder.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),
              _StatusChip(
                label: reminder.statusLabel,
                color: statusColor,
              ),
            ],
          ),
          if (reminder.progress != null) ...[
            const SizedBox(height: AtlasSpacing.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: reminder.progress,
                minHeight: 3,
                backgroundColor: AtlasColors.sandMuted.withValues(alpha: 0.6),
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: AtlasSpacing.md),
          Text(
            reminder.progressLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AdminReminderStatus status) {
    return switch (status) {
      AdminReminderStatus.dueSoon => AtlasColors.subtleGold,
      AdminReminderStatus.inProgress => AtlasColors.terracotta,
      AdminReminderStatus.actionNeeded => const Color(0xFFB3261E),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
