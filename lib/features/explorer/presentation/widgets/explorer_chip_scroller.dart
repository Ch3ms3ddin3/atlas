import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';

/// Rangée de puces à défilement horizontal — libellés complets, momentum iOS.
class ExplorerChipScroller extends StatelessWidget {
  const ExplorerChipScroller({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AtlasSpacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
