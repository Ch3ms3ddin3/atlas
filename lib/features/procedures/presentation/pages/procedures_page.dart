import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_placeholder_page.dart';

/// Répond à : « Comment accomplir cette démarche administrative ? »
class ProceduresPage extends StatelessWidget {
  const ProceduresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtlasPlaceholderPage(
      icon: Icons.description_outlined,
      title: 'Démarches',
      subtitle:
          'Guides pas à pas pour vos démarches — '
          'visa, résidence, permis et plus encore.',
    );
  }
}
