import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../procedures/domain/models/procedure_models.dart';
import '../../../procedures/presentation/widgets/procedure_guide_card.dart';

/// Démarches utiles curatées sur l'accueil.
class HomeProceduresSection extends StatelessWidget {
  const HomeProceduresSection({
    super.key,
    required this.guides,
    required this.onGuideTap,
  });

  final List<ProcedureGuide> guides;
  final ValueChanged<ProcedureGuide> onGuideTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < guides.length; i++) ...[
          ProcedureGuideCard(
            guide: guides[i],
            onTap: () => onGuideTap(guides[i]),
          ),
          if (i < guides.length - 1) const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}
