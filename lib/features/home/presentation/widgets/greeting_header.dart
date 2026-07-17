import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_mark.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../domain/models/home_models.dart';

/// En-tête d'accueil — marque, salutation et accès profil en un regard.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.data,
    this.onProfileTap,
  });

  final GreetingData data;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    void handleProfileTap() {
      if (onProfileTap != null) {
        onProfileTap!();
        return;
      }
      ShellNavigationScope.goToProfile(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AtlasMark(size: 28),
            const Spacer(),
            _ProfileAvatarButton(onTap: handleProfileTap),
          ],
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          'Bonjour, ${data.userName}',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.8,
            height: 1.1,
            color: onSurface,
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              data.city,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                height: 1.35,
                fontFeatures: const [FontFeature.enable('smcp')],
                color: AtlasTextStyles.subtitle(theme.colorScheme),
              ),
            ),
            Text(
              ' · Maroc',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0.6,
                height: 1.35,
                color: AtlasTextStyles.helper(theme.colorScheme),
              ),
            ),
          ],
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          data.dateLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
            height: 1.35,
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Profil',
      child: Material(
        color: AtlasColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AtlasColors.sandMuted.withValues(alpha: 0.8),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
