import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/now_actions/home_now_actions_builder.dart';

/// Actions Accueil « Utile maintenant » — deep-links, jamais un mini-catalogue.
class HomeNowActionsSection extends StatelessWidget {
  const HomeNowActionsSection({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  final List<HomeNowAction> actions;
  final ValueChanged<HomeNowAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utile maintenant',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AtlasColors.surfaceWhite.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
            border: Border.all(
              color: AtlasColors.sandMuted.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AtlasColors.sandMuted.withValues(alpha: 0.45),
                  ),
                _ActionRow(
                  action: actions[i],
                  onTap: () => onActionTap(actions[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final HomeNowAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.lg,
            vertical: AtlasSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 22,
                color: AtlasColors.midnightBlue.withValues(alpha: 0.75),
              ),
              const SizedBox(width: AtlasSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.25,
                        color: AtlasTextStyles.helper(theme.colorScheme),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AtlasTextStyles.helper(theme.colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
