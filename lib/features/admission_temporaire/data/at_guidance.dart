import '../domain/models/at_vehicle.dart';
import 'at_calculator.dart';

/// Textes éditoriaux AT — guidance Atlas, pas un avis douanier.
///
/// Ne revendique aucune durée légale ni statut officiel.
abstract final class AtGuidance {
  static const officialSourceLabel = 'Douane Maroc (douane.gov.ma)';
  static const officialSourceUrl = 'https://www.douane.gov.ma/';
  static const procedureGuideId = 'admission-temporaire';

  /// Cadre d'usage — informatif, sans inventer de règle opposable.
  static const eligibilityBullets = <String>[
    'L\'admission temporaire concerne typiquement un véhicule immatriculé '
        'à l\'étranger utilisé temporairement au Maroc '
        '(voyageurs, MRE selon leur situation).',
    'Atlas ne détermine pas si l\'AT s\'applique à votre cas : '
        'seule la douane confirme votre situation.',
    'La durée suivie ici est celle que vous déclarez '
        '(presets 90 / 180 jours ou saisie libre) — '
        'ce n\'est pas une validation douanière.',
  ];

  static const rulesBullets = <String>[
    'Conservez votre document d\'admission temporaire dans le véhicule.',
    'Surveillez la date d\'expiration figurant sur votre document officiel.',
    'En cas de doute (renouvellement, prolongation, caution), '
        'adressez-vous à la douane ou consultez le guide Atlas.',
  ];

  /// Prochaine action selon l'urgence calculée sur les dates saisies.
  static String nextActionFor(AtUrgencyStatus status) {
    return switch (status) {
      AtUrgencyStatus.ok =>
        'Surveillez la date d\'expiration que vous avez saisie. '
            'Consultez le guide Admission temporaire pour la procédure '
            'officielle si besoin.',
      AtUrgencyStatus.warning =>
        'Échéance à surveiller (dates saisies). Anticipez votre démarche '
            'auprès de la douane ou votre sortie du territoire. '
            'Vérifiez votre document AT officiel.',
      AtUrgencyStatus.critical =>
        'Échéance proche selon vos dates déclarées. '
            'Consultez sans délai la douane ou le guide officiel Atlas.',
      AtUrgencyStatus.expired =>
        'La période que vous avez déclarée est écoulée. '
            'Atlas ne valide pas votre situation — contactez la douane.',
    };
  }

  static String provenanceFootnote({
    required AtVehicle vehicle,
    DateTime? now,
  }) {
    final remaining = AtCalculator.remainingDays(
      expiryDate: vehicle.expiryDate,
      now: now,
    );
    return 'Données saisies par vous · mise à jour locale '
        '${_formatStamp(vehicle.updatedAt)} · '
        '${AtCalculator.remainingLabel(remainingDays: remaining)} '
        'calculés par Atlas — aucune validation douanière.';
  }

  static String _formatStamp(DateTime utc) {
    final local = utc.toUtc().add(const Duration(hours: 1));
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }
}
