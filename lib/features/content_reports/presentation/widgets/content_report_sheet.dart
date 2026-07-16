import 'package:flutter/material.dart';

import '../../../content_reports/domain/content_report_entity_type.dart';
import '../../../content_reports/domain/content_report_type.dart';
import '../../../content_reports/domain/content_reports_repository.dart';
import '../../../content_reports/presentation/content_reports_scope.dart';
import '../../../../design_system/theme/atlas_spacing.dart';

/// Affiche la feuille de signalement et soumet via [ContentReportsRepository].
Future<void> showContentReportSheet({
  required BuildContext context,
  required ContentReportEntityType entityType,
  required String entitySlug,
  ContentReportsRepository? repository,
}) {
  final reports =
      repository ?? ContentReportsScope.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _ContentReportSheet(
          entityType: entityType,
          entitySlug: entitySlug,
          repository: reports,
        ),
      );
    },
  );
}

class _ContentReportSheet extends StatefulWidget {
  const _ContentReportSheet({
    required this.entityType,
    required this.entitySlug,
    required this.repository,
  });

  final ContentReportEntityType entityType;
  final String entitySlug;
  final ContentReportsRepository repository;

  @override
  State<_ContentReportSheet> createState() => _ContentReportSheetState();
}

class _ContentReportSheetState extends State<_ContentReportSheet> {
  ContentReportType _type = ContentReportType.incorrect;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final rawDetails = _detailsController.text.trim();
    final details = rawDetails.isEmpty ? _type.displayLabel : rawDetails;

    final ok = await widget.repository.submitReport(
      entityType: widget.entityType,
      entitySlug: widget.entitySlug,
      reportType: _type,
      details: details,
    );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Signalement enregistré. Merci.'
              : 'Impossible d\'enregistrer le signalement.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.lg,
          AtlasSpacing.sm,
          AtlasSpacing.lg,
          AtlasSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Signaler un problème',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              'Aidez-nous à améliorer Atlas — aucun faux contenu n\'est inventé.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            RadioGroup<ContentReportType>(
              groupValue: _type,
              onChanged: _submitting
                  ? (_) {}
                  : (value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
              child: Column(
                children: [
                  for (final type in ContentReportType.values)
                    RadioListTile<ContentReportType>(
                      value: type,
                      title: Text(type.displayLabel),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            TextField(
              controller: _detailsController,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Précisions (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
