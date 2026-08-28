import 'package:flutter/material.dart';

import '../../../../core/platform/atlas_build_info.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Bannière discrète « Atlas Private Beta » — ville seulement si localisation réelle.
class AtlasBetaBanner extends StatelessWidget {
  const AtlasBetaBanner({
    super.key,
    required this.buildInfo,
    this.locationLabel,
    this.onSecretTap,
  });

  final AtlasBuildInfo buildInfo;

  /// Ville détectée (auto) ou choisie (manuel). Vide / null → pas de ville.
  final String? locationLabel;
  final VoidCallback? onSecretTap;

  static String titleFor({String? locationLabel}) {
    final city = locationLabel?.trim() ?? '';
    if (city.isEmpty) return 'Atlas Private Beta';
    return 'Atlas Private Beta · $city';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = titleFor(locationLabel: locationLabel);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: InkWell(
        onTap: onSecretTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.lg,
              vertical: AtlasSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AtlasSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    semanticsLabel: '$title · ${buildInfo.versionLabel}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
