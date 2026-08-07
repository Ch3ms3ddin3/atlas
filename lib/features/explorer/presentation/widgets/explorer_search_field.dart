import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Champ de recherche premium — ombre douce et focus animé.
class ExplorerSearchField extends StatelessWidget {
  const ExplorerSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = focusNode.hasFocus;

    return AnimatedScale(
      scale: focused ? 1.01 : 1,
      duration: AtlasMotion.contentSwapDuration,
      curve: AtlasMotion.curveDefault,
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: AtlasMotion.contentSwapDuration,
        curve: AtlasMotion.curveDefault,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: focused ? 0.08 : 0.05),
              blurRadius: focused ? 18 : 12,
              offset: Offset(0, focused ? 6 : 4),
            ),
            if (focused)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => onChanged(),
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Rechercher un lieu…',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: focused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: AtlasColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.lg,
              vertical: AtlasSpacing.lg,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
          ),
        ),
      ),
    );
  }
}
