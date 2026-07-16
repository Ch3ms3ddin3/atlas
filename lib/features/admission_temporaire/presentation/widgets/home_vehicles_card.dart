import 'package:flutter/material.dart';

import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../data/at_calculator.dart';
import '../../domain/models/at_vehicle.dart';
import '../at_status_colors.dart';

/// Carte Home — véhicule le plus urgent ou CTA d'ajout.
class HomeVehiclesCard extends StatelessWidget {
  const HomeVehiclesCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onAddTap,
  });

  /// Null = état vide avec CTA.
  final AtVehicle? vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return _EmptyCard(onAddTap: onAddTap);
    }
    return _VehicleCard(vehicle: vehicle!, onTap: onTap);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({this.onAddTap});

  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onAddTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suivi local',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AtlasTextStyles.cardLabel(theme.colorScheme),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Text(
            'Suivez la validité de vos véhicules étrangers au Maroc.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasTextStyles.helper(theme.colorScheme),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Text(
                'Ajouter un véhicule',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    this.onTap,
  });

  final AtVehicle vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = AtCalculator.remainingDays(expiryDate: vehicle.expiryDate);
    final status = AtCalculator.status(expiryDate: vehicle.expiryDate);
    final progress = AtCalculator.progress(
      remainingDays: remaining,
      durationDays: vehicle.durationDays,
    );
    final statusColor = AtStatusColors.forStatus(status);

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vehicle.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _StatusChip(
                label: AtCalculator.statusLabel(status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            '${vehicle.plate} · ${vehicle.countryLabel}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasTextStyles.helper(theme.colorScheme),
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                remaining < 0 ? '0' : '$remaining',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1,
                  height: 1,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
                child: Text(
                  remaining < 0
                      ? AtCalculator.remainingLabel(remainingDays: remaining)
                      : (remaining == 1 ? 'jour restant' : 'jours restants'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AtlasTextStyles.helper(theme.colorScheme),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AtlasColors.sandMuted.withValues(alpha: 0.6),
              color: statusColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            'Admission temporaire · expire le '
            '${CasablancaDateFormatter.formatLongDate(vehicle.expiryDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AtlasTextStyles.metadata(theme.colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
