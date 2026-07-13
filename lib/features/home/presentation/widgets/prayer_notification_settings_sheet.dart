import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../profile/presentation/widgets/profile_prayer_section.dart';
import '../../data/prayer/prayer_notification_coordinator.dart';

/// Feuille de réglage des rappels de prière — ouverte depuis la carte Prière.
class PrayerNotificationSettingsSheet extends StatelessWidget {
  const PrayerNotificationSettingsSheet({
    super.key,
    required this.coordinator,
    required this.onPermissionDenied,
  });

  final PrayerNotificationCoordinator coordinator;
  final VoidCallback onPermissionDenied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.xl,
          AtlasSpacing.lg,
          AtlasSpacing.xl,
          AtlasSpacing.section,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rappels de prière',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              'Recevez une notification avant la prochaine prière, même si Atlas est fermé.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            ProfilePrayerSection(
              coordinator: coordinator,
              onPermissionDenied: onPermissionDenied,
              onDisabledSelected: () => Navigator.of(context).pop(),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
