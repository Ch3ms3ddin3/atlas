import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import 'home_section_header.dart';

/// Section d'accueil avec en-tête — masquée entièrement si [isEmpty].
class HomeOptionalSection extends StatelessWidget {
  const HomeOptionalSection({
    super.key,
    required this.title,
    required this.isEmpty,
    required this.child,
    this.actionLabel,
    this.onActionTap,
    this.topSpacing = AtlasSpacing.section,
    this.headerSpacing = AtlasSpacing.xl,
  });

  final String title;
  final bool isEmpty;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final double topSpacing;
  final double headerSpacing;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topSpacing),
        HomeSectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        SizedBox(height: headerSpacing),
        child,
      ],
    );
  }
}
