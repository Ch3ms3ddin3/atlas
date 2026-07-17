import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../profile/domain/models/user_profile.dart';

/// Écran 2 — ville, langue et profil (obligatoires).
class OnboardingPreferencesPage extends StatelessWidget {
  const OnboardingPreferencesPage({
    super.key,
    required this.city,
    required this.language,
    required this.userType,
    required this.onCityChanged,
    required this.onLanguageChanged,
    required this.onUserTypeChanged,
    required this.onContinue,
  });

  final String city;
  final AtlasLanguage language;
  final AtlasUserType userType;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<AtlasLanguage> onLanguageChanged;
  final ValueChanged<AtlasUserType> onUserTypeChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: AtlasContentContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personnalisez Atlas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                'Ville, langue et profil — pour des conseils adaptés.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AtlasColors.midnightBlueMuted,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xxl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ville principale',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AtlasSpacing.sm),
                      Wrap(
                        spacing: AtlasSpacing.sm,
                        runSpacing: AtlasSpacing.sm,
                        children: [
                          for (final name in MoroccoCities.supportedNames)
                            AtlasFilterChip(
                              label: name,
                              isSelected: city == name,
                              onTap: () => onCityChanged(name),
                            ),
                        ],
                      ),
                      const SizedBox(height: AtlasSpacing.xxl),
                      Text(
                        'Langue',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AtlasSpacing.sm),
                      Wrap(
                        spacing: AtlasSpacing.sm,
                        runSpacing: AtlasSpacing.sm,
                        children: [
                          for (final option
                              in AtlasLanguageLabels.v1Selectable)
                            AtlasFilterChip(
                              label: option.label,
                              isSelected: language == option,
                              onTap: () => onLanguageChanged(option),
                            ),
                        ],
                      ),
                      const SizedBox(height: AtlasSpacing.xxl),
                      Text(
                        'Vous êtes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AtlasSpacing.sm),
                      Wrap(
                        spacing: AtlasSpacing.sm,
                        runSpacing: AtlasSpacing.sm,
                        children: [
                          for (final type in AtlasUserType.values)
                            AtlasFilterChip(
                              label: type.label,
                              isSelected: userType == type,
                              onTap: () => onUserTypeChanged(type),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AtlasSpacing.lg),
              FilledButton(
                onPressed: onContinue,
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
