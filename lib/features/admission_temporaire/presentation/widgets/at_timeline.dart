import 'package:flutter/material.dart';

import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/at_calculator.dart';
import '../../domain/models/at_vehicle.dart';
import '../at_status_colors.dart';

/// Timeline visuelle Entry → Aujourd'hui → alertes → Expiration.
class AtTimeline extends StatelessWidget {
  const AtTimeline({
    super.key,
    required this.vehicle,
  });

  final AtVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = AtCalculator.casablancaNow();
    final remaining = AtCalculator.remainingDays(
      expiryDate: vehicle.expiryDate,
      now: now,
    );
    final status = AtCalculator.status(expiryDate: vehicle.expiryDate, now: now);
    final statusColor = AtStatusColors.forStatus(status);

    final steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Entrée au Maroc',
        subtitle: CasablancaDateFormatter.formatLongDate(vehicle.entryDate),
        isDone: true,
        isCurrent: false,
      ),
      _TimelineStep(
        title: 'Aujourd\'hui',
        subtitle: AtCalculator.remainingLabel(remainingDays: remaining),
        isDone: remaining < 0,
        isCurrent: remaining >= 0,
        accent: statusColor,
      ),
      if (remaining > 30)
        _TimelineStep(
          title: 'Alerte J-30',
          subtitle: CasablancaDateFormatter.formatLongDate(
            AtCalculator.calendarDay(vehicle.expiryDate)
                .subtract(const Duration(days: 30)),
          ),
          isDone: false,
          isCurrent: false,
        ),
      _TimelineStep(
        title: remaining < 0 ? 'Expiration dépassée' : 'Fin d\'admission temporaire',
        subtitle: CasablancaDateFormatter.formatLongDate(vehicle.expiryDate),
        isDone: remaining < 0,
        isCurrent: remaining == 0,
        accent: remaining <= 0 ? statusColor : null,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            theme: theme,
          ),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    this.accent,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final Color? accent;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.theme,
  });

  final _TimelineStep step;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = step.accent ??
        (step.isDone || step.isCurrent
            ? theme.colorScheme.primary
            : AtlasTextStyles.metadata(theme.colorScheme));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCurrent || step.isDone
                        ? color
                        : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AtlasSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight:
                          step.isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: step.isCurrent ? color : null,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    step.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AtlasTextStyles.helper(theme.colorScheme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
