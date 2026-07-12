import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_placeholder_page.dart';

/// Répond à : « Que puis-je découvrir autour de moi ? »
class ExplorerPage extends StatelessWidget {
  const ExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtlasPlaceholderPage(
      icon: Icons.explore_outlined,
      title: 'Explorer',
      subtitle:
          'Lieux, quartiers et expériences — '
          'le Maroc à portée de main.',
    );
  }
}
