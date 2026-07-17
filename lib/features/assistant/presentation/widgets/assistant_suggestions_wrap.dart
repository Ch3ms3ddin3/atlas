import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/assistant_suggestion.dart';

class AssistantSuggestionsWrap extends StatelessWidget {
  const AssistantSuggestionsWrap({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.enabled = true,
  });

  final List<AssistantSuggestion> suggestions;
  final ValueChanged<AssistantSuggestion> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AtlasColors.midnightBlueMuted,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Wrap(
          spacing: AtlasSpacing.sm,
          runSpacing: AtlasSpacing.sm,
          children: [
            for (final suggestion in suggestions)
              FilterChip(
                label: Text(suggestion.label),
                selected: false,
                onSelected: enabled ? (_) => onSelected(suggestion) : null,
              ),
          ],
        ),
      ],
    );
  }
}
