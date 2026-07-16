import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';
import 'administrative_reminder_card.dart';
import 'daily_info_card.dart';
import 'important_alerts.dart';

/// Section « À savoir aujourd'hui » — alerte, conseil et rappel administratif.
class TodayEssentialsSection extends StatelessWidget {
  const TodayEssentialsSection({
    super.key,
    required this.data,
    this.onAlertTap,
    this.onTipTap,
    this.onReminderTap,
  });

  final TodayEssentialsData data;
  final VoidCallback? onAlertTap;
  final VoidCallback? onTipTap;
  final VoidCallback? onReminderTap;

  @override
  Widget build(BuildContext context) {
    final reminder = data.adminReminder;

    return Column(
      children: [
        ImportantAlerts(
          alerts: [data.alert],
          onAlertTap: (_) => onAlertTap?.call(),
        ),
        const SizedBox(height: AtlasSpacing.lg),
        DailyInfoCard(data: data.tip, onTap: onTipTap),
        if (reminder != null) ...[
          const SizedBox(height: AtlasSpacing.lg),
          AdministrativeReminderCard(
            reminder: reminder,
            onTap: onReminderTap,
          ),
        ],
      ],
    );
  }
}
