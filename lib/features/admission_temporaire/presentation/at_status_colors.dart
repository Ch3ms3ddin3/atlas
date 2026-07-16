import 'package:flutter/material.dart';

import '../../../design_system/theme/atlas_colors.dart';
import '../domain/models/at_vehicle.dart';

/// Couleurs de statut pour le suivi AT.
abstract final class AtStatusColors {
  static Color forStatus(AtUrgencyStatus status) {
    return switch (status) {
      AtUrgencyStatus.ok => AtlasColors.success,
      AtUrgencyStatus.warning => AtlasColors.warning,
      AtUrgencyStatus.critical => AtlasColors.terracotta,
      AtUrgencyStatus.expired => AtlasColors.error,
    };
  }

  static Color mutedForStatus(AtUrgencyStatus status) {
    return switch (status) {
      AtUrgencyStatus.ok => AtlasColors.successMuted,
      AtUrgencyStatus.warning => AtlasColors.warningMuted,
      AtUrgencyStatus.critical => AtlasColors.terracottaGhost,
      AtUrgencyStatus.expired => AtlasColors.errorMuted,
    };
  }
}
