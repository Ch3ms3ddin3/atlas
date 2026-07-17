import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/assistant_quick_actions_catalog.dart';
import '../../domain/models/assistant_quick_action.dart';

class AssistantQuickActionsRow extends StatelessWidget {
  const AssistantQuickActionsRow({
    super.key,
    required this.onAction,
  });

  final ValueChanged<AssistantQuickAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Atlas',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AtlasColors.midnightBlueMuted,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final action in AssistantQuickActionsCatalog.actions) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AtlasSpacing.sm),
                  child: ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    onPressed: () => onAction(action),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
