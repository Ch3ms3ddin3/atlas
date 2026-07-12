import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/notifications/prayer_notification_lead_time.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/prayer/prayer_notification_coordinator.dart';

/// Feuille de réglage des rappels de prière — ouverte depuis la carte Prière.
class PrayerNotificationSettingsSheet extends StatefulWidget {
  const PrayerNotificationSettingsSheet({
    super.key,
    required this.coordinator,
    required this.onPermissionDenied,
  });

  final PrayerNotificationCoordinator coordinator;
  final VoidCallback onPermissionDenied;

  @override
  State<PrayerNotificationSettingsSheet> createState() =>
      _PrayerNotificationSettingsSheetState();
}

class _PrayerNotificationSettingsSheetState
    extends State<PrayerNotificationSettingsSheet> {
  PrayerNotificationLeadTime? _selected;
  bool _isLoading = true;
  bool _isSaving = false;

  static const _options = PrayerNotificationLeadTime.values;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final current = await widget.coordinator.currentLeadTime();
    if (!mounted) return;
    setState(() {
      _selected = current;
      _isLoading = false;
    });
  }

  Future<void> _onOptionSelected(PrayerNotificationLeadTime option) async {
    if (_isSaving || option == _selected) return;

    if (kIsWeb && option != PrayerNotificationLeadTime.disabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les rappels de prière ne sont pas disponibles sur le web.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _selected = option;
    });

    final success = await widget.coordinator.setLeadTime(option);
    if (!mounted) return;

    if (!success && option != PrayerNotificationLeadTime.disabled) {
      final current = await widget.coordinator.currentLeadTime();
      setState(() {
        _selected = current;
        _isSaving = false;
      });
      widget.onPermissionDenied();
      return;
    }

    setState(() => _isSaving = false);
    if (option == PrayerNotificationLeadTime.disabled) {
      Navigator.of(context).pop();
    }
  }

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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ..._options.map((option) {
                final isSelected = option == _selected;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(option.label),
                  onTap: _isSaving ? null : () => _onOptionSelected(option),
                );
              }),
            if (_isSaving) ...[
              const SizedBox(height: AtlasSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
