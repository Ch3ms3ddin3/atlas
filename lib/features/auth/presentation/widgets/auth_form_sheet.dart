import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/auth_credentials_validator.dart';
import '../auth_scope.dart';

enum AuthFormMode { signUp, signIn }

/// Formulaire de connexion / inscription dans une feuille modale.
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
      setState(() => _formError = validationError);
      return;
    }

    setState(() {
      _formError = null;
      _isSubmitting = true;
    });

    final repository = AuthScope.of(context);
    final result = _mode == AuthFormMode.signUp
        ? await repository.signUp(email: email, password: password)
        : await repository.signIn(email: email, password: password);

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
          content: Text(
            _mode == AuthFormMode.signUp
                ? 'Compte créé — vos données restent sur cet appareil.'
                : 'Connexion réussie.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == AuthFormMode.signUp
          ? AuthFormMode.signIn
          : AuthFormMode.signUp;
      _formError = null;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignUp = _mode == AuthFormMode.signUp;

    return SafeArea(
      child: Padding(
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
              isSignUp ? 'Créer un compte' : 'Se connecter',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              isSignUp
                  ? 'Liez votre session invitée à un e-mail pour retrouver '
                      'vos favoris sur d\'autres appareils.'
                  : 'Connectez-vous pour synchroniser vos données Atlas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'vous@exemple.com',
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
              ),
            ),
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
                  : Text(isSignUp ? 'Créer mon compte' : 'Se connecter'),
            ),
            const SizedBox(height: AtlasSpacing.md),
            TextButton(
              onPressed: _isSubmitting ? null : _toggleMode,
              child: Text(
                isSignUp
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
