import 'package:flutter/material.dart';

import '../../../../core/platform/atlas_build_info.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Bannière discrète « Atlas Private Beta » + version/build.
class AtlasBetaBanner extends StatelessWidget {
  const AtlasBetaBanner({
    super.key,
    required this.buildInfo,
    this.onSecretTap,
  });

  final AtlasBuildInfo buildInfo;
  final VoidCallback? onSecretTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: InkWell(
        onTap: onSecretTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.lg,
              vertical: AtlasSpacing.sm,
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
                    'Atlas Private Beta · ${buildInfo.versionLabel}',
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
