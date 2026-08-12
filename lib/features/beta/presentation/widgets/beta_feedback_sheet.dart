import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/errors/atlas_error_ui.dart';
import '../../../../core/platform/atlas_build_info.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../design_system/widgets/atlas_primary_button.dart';
import '../../data/beta_feedback_repository.dart';
import '../../domain/models/beta_feedback.dart';
import '../beta_feedback_scope.dart';

/// Motif de signalement — préfixé au message (pas de colonne backend dédiée).
enum BetaFeedbackCategory {
  bug('Bug', 'Bug'),
  incorrectInfo('Info incorrecte', 'Information incorrecte'),
  ux('Problème d’usage', 'Problème d’usage'),
  other('Autre', 'Autre retour');

  const BetaFeedbackCategory(this.chipLabel, this.messagePrefix);

  final String chipLabel;
  final String messagePrefix;
}

Future<void> showBetaFeedbackSheet({
  required BuildContext context,
  required String screenName,
  GlobalKey? screenshotKey,
  BetaFeedbackRepository? repository,
}) async {
  if (!context.mounted) return;

  final BetaFeedbackRepository repo;
  try {
    repo = repository ?? BetaFeedbackScope.of(context);
  } catch (_) {
    _showFeedbackErrorSnack(
      context,
      'Signaler indisponible. Relancez l’app.',
    );
    return;
  }

  if (Navigator.maybeOf(context, rootNavigator: true) == null) {
    _showFeedbackErrorSnack(
      context,
      'Signaler indisponible. Relancez l’app.',
    );
    return;
  }

  try {
    await showAtlasBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _BetaFeedbackSheet(
            screenName: screenName,
            repository: repo,
            screenshotKey: screenshotKey,
          ),
        );
      },
    );
  } catch (_) {
    if (context.mounted) {
      _showFeedbackErrorSnack(
        context,
        'Impossible d’ouvrir Signaler. Réessayez.',
      );
    }
  }
}

void _showFeedbackErrorSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _BetaFeedbackSheet extends StatefulWidget {
  const _BetaFeedbackSheet({
    required this.screenName,
    required this.repository,
    this.screenshotKey,
  });

  final String screenName;
  final BetaFeedbackRepository repository;
  final GlobalKey? screenshotKey;

  @override
  State<_BetaFeedbackSheet> createState() => _BetaFeedbackSheetState();
}

class _BetaFeedbackSheetState extends State<_BetaFeedbackSheet> {
  final _controller = TextEditingController();
  BetaFeedbackCategory _category = BetaFeedbackCategory.bug;
  bool _includeScreenshot = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _captureScreenshot() async {
    final key = widget.screenshotKey;
    if (key?.currentContext == null) return null;
    try {
      final boundary =
          key!.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      final encoded = base64Encode(bytes.buffer.asUint8List());
      // Cap ~650KB base64 for PostgREST safety.
      if (encoded.length > 650000) return null;
      return encoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    final info = await AtlasBuildInfo.load();
    String? shot;
    if (_includeScreenshot) {
      shot = await _captureScreenshot();
    }

    final feedback = BetaFeedback.create(
      screenName: widget.screenName,
      message: '[${_category.messagePrefix}] $message',
      appVersion: info.version,
      buildNumber: info.buildNumber,
      platform: info.platformLabel,
      includeScreenshot: _includeScreenshot && shot != null,
      screenshotBase64: shot,
    );

    final ok = await widget.repository.submit(feedback);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAtlasSuccessSnack(
      context,
      ok
          ? 'Merci — votre signalement a été envoyé.'
          : 'Signalement enregistré localement — envoi dès que possible.',
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
              'Signaler (bêta privée)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              'Écran : ${widget.screenName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Wrap(
              spacing: AtlasSpacing.sm,
              runSpacing: AtlasSpacing.sm,
              children: [
                for (final category in BetaFeedbackCategory.values)
                  AtlasFilterChip(
                    label: category.chipLabel,
                    isSelected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 4000,
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème…',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Joindre une capture d’écran'),
              subtitle: const Text('Optionnel — aide au diagnostic'),
              value: _includeScreenshot,
              onChanged: (value) => setState(() => _includeScreenshot = value),
            ),
            const SizedBox(height: AtlasSpacing.md),
            AtlasPrimaryButton(
              label: 'Envoyer',
              isLoading: _submitting,
              onPressed: _controller.text.trim().isEmpty || _submitting
                  ? null
                  : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
