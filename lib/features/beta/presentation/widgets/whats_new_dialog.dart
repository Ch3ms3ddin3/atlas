import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_primary_button.dart';
import '../../domain/changelog_entry.dart';

Future<void> showWhatsNewDialog({
  required BuildContext context,
  required List<ChangelogEntry> entries,
}) {
  if (entries.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Nouveautés Atlas'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries) ...[
                  Text(
                    '${entry.title} · v${entry.version} (${entry.buildNumber})',
                    style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  for (final bullet in entry.bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(bullet)),
                        ],
                      ),
                    ),
                  const SizedBox(height: AtlasSpacing.lg),
                ],
              ],
            ),
          ),
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
