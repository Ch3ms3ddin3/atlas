import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/auth_session.dart';
import '../../domain/auth_repository.dart';
import '../auth_scope.dart';
import 'auth_form_sheet.dart';

/// Section compte sur l'écran profil — connexion et synchronisation cloud.
class ProfileAccountSection extends StatefulWidget {
  const ProfileAccountSection({super.key});

  @override
  State<ProfileAccountSection> createState() => _ProfileAccountSectionState();
}

class _ProfileAccountSectionState extends State<ProfileAccountSection> {
  AuthRepository? _authRepository;
  bool _isSigningOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AuthScope.of(context);
    if (!identical(repository, _authRepository)) {
      _authRepository?.removeListener(_onAuthChanged);
      _authRepository = repository;
      _authRepository!.addListener(_onAuthChanged);
    }
  }

  @override
  void dispose() {
    _authRepository?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    final result = await _authRepository!.signOut();
    if (!mounted) return;
    setState(() => _isSigningOut = false);

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Déconnexion impossible.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Déconnecté — vos données locales sont conservées.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _authRepository?.session ?? const AuthSession.unavailable();

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Compte Atlas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            _statusLabel(session),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (session.isSignedIn && session.email != null) ...[
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              session.email!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AtlasSpacing.lg),
          ..._actionsForSession(context, session),
          const SizedBox(height: AtlasSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: AtlasTextStyles.metadata(theme.colorScheme),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Expanded(
                child: Text(
                  _footerLabel(session),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AtlasTextStyles.metadata(theme.colorScheme),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AuthSession session) {
    return switch (session.kind) {
      AuthSessionKind.unavailable =>
        'Mode hors ligne — vos préférences restent sur cet appareil.',
      AuthSessionKind.anonymous =>
        'Session invitée active — créez un compte pour synchroniser '
            'vos données entre appareils.',
      AuthSessionKind.signedIn =>
        'Compte connecté — profil, favoris et signalements se synchronisent '
            'en arrière-plan.',
    };
  }

  String _footerLabel(AuthSession session) {
    return switch (session.kind) {
      AuthSessionKind.unavailable =>
        'Aucun compte · données stockées localement',
      AuthSessionKind.anonymous =>
        'Données locales conservées · synchronisation optionnelle',
      AuthSessionKind.signedIn =>
        'Données locales conservées · synchronisation cloud active',
    };
  }

  List<Widget> _actionsForSession(BuildContext context, AuthSession session) {
    return switch (session.kind) {
      AuthSessionKind.unavailable => const [],
      AuthSessionKind.anonymous => [
        FilledButton(
          onPressed: () => AuthFormSheet.show(
            context,
            initialMode: AuthFormMode.signUp,
          ),
          child: const Text('Créer un compte'),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        OutlinedButton(
          onPressed: () => AuthFormSheet.show(
            context,
            initialMode: AuthFormMode.signIn,
          ),
          child: const Text('Se connecter'),
        ),
      ],
      AuthSessionKind.signedIn => [
        OutlinedButton(
          onPressed: _isSigningOut ? null : _signOut,
          child: _isSigningOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Se déconnecter'),
        ),
      ],
    };
  }
}
