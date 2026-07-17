import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/auth_credentials_validator.dart';
import '../../domain/auth_action_result.dart';
import '../auth_scope.dart';

enum AuthFormMode { signUp, signIn, resetPassword }

/// Formulaire de connexion / inscription / reset dans une feuille modale.
class AuthFormSheet extends StatefulWidget {
  const AuthFormSheet({
    super.key,
    required this.initialMode,
    this.scaffoldMessenger,
  });

  final AuthFormMode initialMode;
  final ScaffoldMessengerState? scaffoldMessenger;

  static Future<void> show(
    BuildContext context, {
    required AuthFormMode initialMode,
  }) {
    final repository = AuthScope.read(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return AuthScope(
          repository: repository,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: AuthFormSheet(
              initialMode: initialMode,
              scaffoldMessenger: scaffoldMessenger,
            ),
          ),
        );
      },
    );
  }

  @override
  State<AuthFormSheet> createState() => _AuthFormSheetState();
}

class _AuthFormSheetState extends State<AuthFormSheet> {
  late AuthFormMode _mode;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _formError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
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
    late final AuthActionResult result;

    if (_mode == AuthFormMode.resetPassword) {
      result = await repository.resetPassword(email: _emailController.text);
    } else {
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      final validationError = _mode == AuthFormMode.signUp
          ? AuthCredentialsValidator.validateSignUp(
              email: email,
              password: password,
              confirmPassword: confirmPassword,
            )
          : AuthCredentialsValidator.validateSignIn(
              email: email,
              password: password,
            );

      if (validationError != null) {
        setState(() {
          _formError = validationError;
          _isSubmitting = false;
        });
        return;
      }

      result = _mode == AuthFormMode.signUp
          ? await repository.signUp(email: email, password: password)
          : await repository.signIn(email: email, password: password);
    }

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
        SnackBar(
          content: Text(_successMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String get _successMessage => switch (_mode) {
        AuthFormMode.signUp =>
          'Compte créé — vos données restent sur cet appareil.',
        AuthFormMode.signIn => 'Connexion réussie.',
        AuthFormMode.resetPassword =>
          'Lien de réinitialisation envoyé si le compte existe.',
      };

  Future<void> _oauth(Future<AuthActionResult> Function() action) async {
    setState(() {
      _formError = null;
      _isSubmitting = true;
    });
    final result = await action();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!result.success) {
      setState(() => _formError = result.errorMessage);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignUp = _mode == AuthFormMode.signUp;
    final isReset = _mode == AuthFormMode.resetPassword;
    final repository = AuthScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.xl,
          AtlasSpacing.sm,
          AtlasSpacing.xl,
          AtlasSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isReset
                  ? 'Réinitialiser le mot de passe'
                  : isSignUp
                      ? 'Créer un compte'
                      : 'Se connecter',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              isReset
                  ? 'Nous vous enverrons un lien sécurisé par e-mail.'
                  : isSignUp
                      ? 'Liez votre session invitée à un e-mail pour retrouver '
                          'vos favoris sur d\'autres appareils.'
                      : 'Connectez-vous pour synchroniser vos données Atlas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (!isReset) ...[
              const SizedBox(height: AtlasSpacing.lg),
              OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _oauth(repository.signInWithApple),
                icon: const Icon(Icons.apple),
                label: const Text('Continuer avec Apple'),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _oauth(repository.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continuer avec Google'),
              ),
              const SizedBox(height: AtlasSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.md,
                    ),
                    child: Text(
                      'ou',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ],
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'vous@exemple.com',
              ),
            ),
            if (!isReset) ...[
              const SizedBox(height: AtlasSpacing.lg),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                ),
              ),
            ],
            if (isSignUp) ...[
              const SizedBox(height: AtlasSpacing.lg),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                ),
              ),
            ],
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
                  : Text(
                      isReset
                          ? 'Envoyer le lien'
                          : isSignUp
                              ? 'Créer mon compte'
                              : 'Se connecter',
                    ),
            ),
            if (!isReset && !isSignUp) ...[
              const SizedBox(height: AtlasSpacing.sm),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                          _mode = AuthFormMode.resetPassword;
                          _formError = null;
                        }),
                child: const Text('Mot de passe oublié ?'),
              ),
            ],
            const SizedBox(height: AtlasSpacing.md),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _mode = isSignUp || isReset
                            ? AuthFormMode.signIn
                            : AuthFormMode.signUp;
                        _formError = null;
                      }),
              child: Text(
                isReset
                    ? 'Retour à la connexion'
                    : isSignUp
                        ? 'Déjà un compte ? Se connecter'
                        : 'Pas de compte ? Créer un compte',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
