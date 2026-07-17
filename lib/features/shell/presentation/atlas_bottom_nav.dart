import 'package:flutter/material.dart';

import '../../../design_system/theme/atlas_colors.dart';
import '../../../design_system/theme/atlas_motion.dart';
import '../../../design_system/theme/atlas_spacing.dart';

/// Destination de la barre de navigation principale.
class AtlasNavDestination {
  const AtlasNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barre de navigation principale — 5 onglets avec animation premium.
class AtlasBottomNav extends StatelessWidget {
  const AtlasBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const destinations = <AtlasNavDestination>[
    AtlasNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    AtlasNavDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      label: 'Explorer',
    ),
    AtlasNavDestination(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Carte',
    ),
    AtlasNavDestination(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      label: 'Démarches',
    ),
    AtlasNavDestination(
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
      label: 'Prix',
    ),
    AtlasNavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: AtlasColors.warmOffWhite,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              const indicatorWidth = 56.0;
              const indicatorHeight = 32.0;

              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  AnimatedPositioned(
                    duration: AtlasMotion.navAnimationDuration,
                    curve: AtlasMotion.curveDefault,
                    left: itemWidth * currentIndex + (itemWidth - indicatorWidth) / 2,
                    top: 8,
                    width: indicatorWidth,
                    height: indicatorHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AtlasColors.sandMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _AtlasNavItem(
                            destination: destinations[i],
                            isSelected: currentIndex == i,
                            labelStyle: textTheme.labelMedium,
                            onTap: () => onDestinationSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AtlasNavItem extends StatelessWidget {
  const _AtlasNavItem({
    required this.destination,
    required this.isSelected,
    required this.labelStyle,
    required this.onTap,
  });

  final AtlasNavDestination destination;
  final bool isSelected;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AtlasColors.terracotta
        : AtlasColors.midnightBlueMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? AtlasMotion.navIconActiveScale : 1,
                duration: AtlasMotion.navAnimationDuration,
                curve: AtlasMotion.curveDefault,
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: AtlasMotion.navAnimationDuration,
                curve: AtlasMotion.curveDefault,
                style: (labelStyle ?? const TextStyle()).copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
                child: Text(destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
