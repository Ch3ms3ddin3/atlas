import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';

/// Conteneur centré avec largeur maximale — mobile-first, confortable sur web.
class AtlasContentContainer extends StatelessWidget {
  const AtlasContentContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isExtraWide = width >= 1100;
        final isWide = width >= 720;
        final horizontalPadding = isExtraWide
            ? AtlasSpacing.pageHorizontalExtraWide
            : isWide
                ? AtlasSpacing.pageHorizontalWide
                : AtlasSpacing.pageHorizontal;
        final maxWidth = isExtraWide
            ? AtlasSpacing.maxContentWidthWide
            : AtlasSpacing.maxContentWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
