import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_placeholder_page.dart';

/// Répond à : « Combien coûte la vie ici ? »
class PricesPage extends StatelessWidget {
  const PricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtlasPlaceholderPage(
      icon: Icons.payments_outlined,
      title: 'Prix',
      subtitle:
          'Coût de la vie et repères utiles — '
          'pour planifier sereinement votre quotidien.',
    );
  }
}
