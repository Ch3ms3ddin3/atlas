import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/notifications/prayer_notification_lead_time.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../home/data/prayer/prayer_notification_coordinator.dart';

/// Sélecteur de rappels de prière — partagé entre l'accueil et le profil.
class ProfilePrayerSection extends StatefulWidget {
  const ProfilePrayerSection({
    super.key,
    required this.coordinator,
    this.onPermissionDenied,
    this.onDisabledSelected,
    this.compact = false,
  });

  final PrayerNotificationCoordinator coordinator;
  final VoidCallback? onPermissionDenied;
  final VoidCallback? onDisabledSelected;
  final bool compact;

  @override
  State<ProfilePrayerSection> createState() => _ProfilePrayerSectionState();
}

class _ProfilePrayerSectionState extends State<ProfilePrayerSection> {
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
      widget.onPermissionDenied?.call();
      return;
    }

    setState(() => _isSaving = false);
    if (option == PrayerNotificationLeadTime.disabled) {
      widget.onDisabledSelected?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          Text(
            'Rappels de prière',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            'Recevez une notification avant la prochaine prière, même si Atlas '
            'est fermé.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
        ],
        for (final option in _options) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: widget.compact,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              option == _selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: option == _selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(option.label),
            onTap: _isSaving ? null : () => _onOptionSelected(option),
          ),
        ],
        if (_isSaving) ...[
          const SizedBox(height: AtlasSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
