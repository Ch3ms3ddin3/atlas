import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_primary_button.dart';

/// One-time private-beta framing for Marrakech TestFlight testers.
Future<void> showPrivateBetaExpectationsDialog({
  required BuildContext context,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Bienvenue dans la bêta Atlas'),
        content: const SingleChildScrollView(
          child: Text(
            'Atlas est en bêta privée, centrée sur Marrakech.\n\n'
            'Certaines informations et fonctions sont encore en cours '
            'd’enrichissement. Utilisez le bouton Signaler pour nous '
            'envoyer un bug, une info incorrecte ou un retour d’usage.',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AtlasSpacing.lg,
          0,
          AtlasSpacing.lg,
          AtlasSpacing.lg,
        ),
        actions: [
          AtlasPrimaryButton(
            label: 'Compris',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}
