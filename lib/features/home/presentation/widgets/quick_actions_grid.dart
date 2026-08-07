import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_pressable.dart';
import '../../domain/models/home_models.dart';

/// Actions rapides compactes — secondaires, 4 raccourcis égaux.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  final List<QuickActionData> actions;
  final ValueChanged<QuickActionData>? onActionTap;

  @override
  Widget build(BuildContext context) {
    final visible = actions.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final tileWidth = (constraints.maxWidth - gap * 3) / 4;

        return Row(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: tileWidth,
                child: _CompactQuickActionTile(
                  action: visible[i],
                  onTap: () => onActionTap?.call(visible[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CompactQuickActionTile extends StatelessWidget {
  const _CompactQuickActionTile({
    required this.action,
    required this.onTap,
  });

  final QuickActionData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasPressable(
      onTap: onTap,
      scale: AtlasMotion.pressScale,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AtlasColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AtlasColors.sandMuted.withValues(alpha: 0.85),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(2, AtlasSpacing.sm, 2, AtlasSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  fontSize: 11.5,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
