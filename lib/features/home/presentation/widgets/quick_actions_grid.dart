import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';

/// Grille d'actions rapides — accès direct aux intentions fréquentes.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AtlasSpacing.xl,
            crossAxisSpacing: AtlasSpacing.xl,
            childAspectRatio: columns >= 6 ? 0.9 : 0.95,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionButton(
              action: action,
              onTap: () => onActionTap?.call(action),
            );
          },
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 600) return 6;
    if (width >= 400) return 4;
    return 3;
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.action,
    this.onTap,
  });

  final QuickActionData action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AtlasColors.sandMuted.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
