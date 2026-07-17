import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_mark.dart';

/// Écran 1 — proposition de valeur Atlas.
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: AtlasContentContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('Passer'),
                ),
              ),
              const Spacer(),
              const Center(child: AtlasMark(size: 72)),
              const SizedBox(height: AtlasSpacing.xxl),
              Text(
                'Votre compagnon au Maroc',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AtlasColors.midnightBlue,
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),
              Text(
                'Repères utiles, démarches et infos du jour — '
                'sans bruit inutile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AtlasColors.midnightBlueMuted,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onContinue,
                child: const Text('Commencer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
