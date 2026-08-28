import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/atlas_display_clock.dart';
import '../../../../core/location/atlas_city_source.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_pressable.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../domain/models/home_models.dart';

/// En-tête d'accueil — salutation, ville, date et heure en un regard.
class GreetingHeader extends StatefulWidget {
  const GreetingHeader({
    super.key,
    required this.data,
    this.citySource = AtlasCitySource.auto,
    this.clockNow,
    this.onProfileTap,
  });

  final GreetingData data;
  final AtlasCitySource citySource;
  final DateTime Function()? clockNow;
  final VoidCallback? onProfileTap;

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
  Timer? _clockTimer;
  late String _timeLabel;

  @override
  void initState() {
    super.initState();
    _timeLabel = _formatTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _timeLabel = _formatTime());
    });
  }

  @override
  void didUpdateWidget(GreetingHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.citySource != widget.citySource ||
        oldWidget.data.dateLabel != widget.data.dateLabel) {
      _timeLabel = _formatTime();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final now =
        widget.clockNow?.call() ??
        AtlasDisplayClock.nowFor(citySource: widget.citySource);
    return AtlasDisplayClock.formatHm(now);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    void handleProfileTap() {
      if (widget.onProfileTap != null) {
        widget.onProfileTap!();
        return;
      }
      ShellNavigationScope.goToProfile(context);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour ${widget.data.userName} 👋',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.7,
                  height: 1.1,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              if (widget.data.city.trim().isNotEmpty) ...[
                Text(
                  widget.data.city,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    height: 1.2,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                '${widget.data.dateLabel} · $_timeLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: AtlasTextStyles.metadata(theme.colorScheme),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AtlasSpacing.md),
        _ProfileAvatarButton(
          displayName: widget.data.userName,
          onTap: handleProfileTap,
        ),
      ],
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.displayName,
    required this.onTap,
  });

  final String displayName;
  final VoidCallback onTap;

  String get _initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'V';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Profil',
      child: AtlasPressable(
        onTap: onTap,
        scale: AtlasMotion.pressScale,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AtlasColors.terracottaGhost.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: AtlasColors.sandMuted.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            _initial,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1,
              color: AtlasColors.terracottaDeep.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
