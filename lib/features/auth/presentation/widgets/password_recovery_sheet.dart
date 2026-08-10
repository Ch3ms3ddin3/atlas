import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../auth_scope.dart';
import 'auth_form_sheet.dart';

/// Feuille modale : définir un nouveau mot de passe après `PASSWORD_RECOVERY`.
class PasswordRecoverySheet extends StatefulWidget {
  const PasswordRecoverySheet({
    super.key,
    this.scaffoldMessenger,
  });

  final ScaffoldMessengerState? scaffoldMessenger;

  static Future<void> show(BuildContext context) {
    final repository = AuthScope.read(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showAtlasBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return AuthScope(
          repository: repository,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: PasswordRecoverySheet(
              scaffoldMessenger: scaffoldMessenger,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PasswordRecoverySheet> createState() => _PasswordRecoverySheetState();
}

class _PasswordRecoverySheetState extends State<PasswordRecoverySheet> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _isSubmitting = true;
    });

    final repository = AuthScope.of(context);
    final result = await repository.updatePassword(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      setState(() => _formError = result.errorMessage);
      return;
    }

    Navigator.of(context).pop();
    final messenger =
        widget.scaffoldMessenger ?? ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Mot de passe mis à jour. Connectez-vous avec le nouveau mot de passe.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

    if (!mounted) return;
    await AuthFormSheet.show(context, initialMode: AuthFormMode.signIn);
  }

  Future<void> _cancel() async {
    setState(() => _isSubmitting = true);
    await AuthScope.of(context).cancelPasswordRecovery();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.xl,
          AtlasSpacing.lg,
          AtlasSpacing.xl,
          AtlasSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouveau mot de passe',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              'Lien de réinitialisation validé. Choisissez un nouveau mot de passe '
              '(différent de l\'ancien), puis connectez-vous.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                helperText: 'Au moins 6 caractères (la politique Auth peut en exiger plus)',
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              autocorrect: false,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isSubmitting) {
                  _submit();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: AtlasSpacing.md),
              Text(
                _formError!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AtlasSpacing.xl),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer le mot de passe'),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            TextButton(
              onPressed: _isSubmitting ? null : _cancel,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
