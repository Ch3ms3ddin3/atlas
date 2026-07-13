import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';

/// Conteneur centré avec largeur maximale pour le responsive web.
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
        final isWide = constraints.maxWidth >= 720;
        final horizontalPadding = isWide
            ? AtlasSpacing.pageHorizontalWide
            : AtlasSpacing.pageHorizontal;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AtlasSpacing.maxContentWidth,
            ),
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
