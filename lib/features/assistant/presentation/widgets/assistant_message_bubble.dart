import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/assistant_message.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
  });

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AssistantMessageRole.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          margin: const EdgeInsets.only(bottom: AtlasSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.lg,
            vertical: AtlasSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AtlasColors.terracotta,
            borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasColors.warmOffWhite,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AtlasSpacing.md),
          child: AtlasCard(
            emphasis: AtlasCardEmphasis.standard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: AtlasColors.subtleGold,
                    ),
                    const SizedBox(width: AtlasSpacing.sm),
                    Text(
                      'Atlas',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AtlasColors.midnightBlueMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message.status == AssistantMessageStatus.streaming) ...[
                      const SizedBox(width: AtlasSpacing.sm),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AtlasColors.terracotta,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  message.content.isEmpty &&
                          message.status == AssistantMessageStatus.streaming
                      ? 'Atlas réfléchit…'
                      : message.content,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
