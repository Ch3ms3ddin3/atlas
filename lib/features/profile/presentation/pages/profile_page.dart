import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../admission_temporaire/presentation/at_scope.dart';
import '../../../assistant/presentation/pages/assistant_page.dart';
import '../../../auth/domain/auth_session.dart';
import '../../../auth/presentation/auth_scope.dart';
import '../../../auth/presentation/widgets/auth_form_sheet.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../../itineraries/presentation/itinerary_scope.dart';
import '../../../itineraries/presentation/pages/trip_list_page.dart';
import '../../../onboarding/data/onboarding_preferences_store.dart';
import '../../../sync/data/atlas_data_export.dart';
import '../../../sync/domain/cloud_sync_status.dart';
import '../../../sync/presentation/sync_scope.dart';
import '../../data/profile_validator.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/profile_repository.dart';
import '../profile_scope.dart';
import '../widgets/profile_prayer_section.dart';

/// Profil premium — identité, sync, compte et données.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firstNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _preferredCity = UserProfile.defaultPreferredCity;
  AtlasUserType _userType = UserProfile.defaultUserType;
  AtlasLanguage _language = UserProfile.defaultLanguage;
  String? _firstNameError;
  bool _isSaving = false;
  bool _busy = false;
  ProfileRepository? _profileRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = ProfileScope.of(context);
    if (!identical(repository, _profileRepository)) {
      _profileRepository?.removeListener(_syncFromProfile);
      _profileRepository = repository;
      _profileRepository!.addListener(_syncFromProfile);
      _syncFromProfile();
    }
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_syncFromProfile);
    _firstNameController.dispose();
    super.dispose();
  }

  void _syncFromProfile() {
    if (!mounted) return;
    final profile = _profileRepository!.profile;
    setState(() {
      _firstNameController.text = profile.firstName;
      _preferredCity = profile.preferredCity;
      _userType = profile.userType;
      _language = profile.language;
      _firstNameError = null;
    });
  }

  bool get _isFormValid {
    return ProfileValidator.isFormValid(
      firstName: _firstNameController.text,
      preferredCity: _preferredCity,
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _firstNameError =
          ProfileValidator.validateFirstName(_firstNameController.text)
              ?.message;
    });
    if (!_isFormValid) return;

    setState(() => _isSaving = true);
    final current = ProfileScope.of(context).profile;
    final success = await ProfileScope.of(context).save(
      current.copyWith(
        firstName: _firstNameController.text,
        preferredCity: _preferredCity,
        language: _language,
        userType: _userType,
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!success) return;

    await SyncScope.maybeOf(context)?.persistFromUi();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Profil enregistré'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _exportData() async {
    setState(() => _busy = true);
    final json = await AtlasDataExport.buildJson(
      session: AuthScope.of(context).session,
      profile: ProfileScope.of(context),
      favorites: FavoritesScope.of(context),
      atRepository: AtScope.of(context),
      itineraryRepository: ItineraryScope.maybeOf(context),
      syncStatus: SyncScope.maybeOf(context)?.status,
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Export copié dans le presse-papiers'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showAtlasDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer mon compte ?'),
          content: const Text(
            'Cette action est définitive. Vos données cloud seront effacées. '
            'Les données locales restent sur cet appareil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await AuthScope.of(context).deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Compte supprimé — mode local conservé.'
                : result.errorMessage ?? 'Suppression impossible.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.of(context);
    final session = auth.session;
    final sync = SyncScope.maybeOf(context);
    final syncStatus = sync?.status ?? const CloudSyncStatus.idle();

    if (_profileRepository != null && !_profileRepository!.isLoaded) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = session.displayName?.trim().isNotEmpty == true
        ? session.displayName!
        : (_profileRepository?.profile.resolvedDisplayName ??
            (_firstNameController.text.trim().isNotEmpty
                ? _firstNameController.text.trim()
                : 'Voyageur Atlas'));

    final avatarUrl = session.avatarUrl ?? _profileRepository?.profile.avatarUrl;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const PageStorageKey<String>('profile_scroll'),
          padding: const EdgeInsets.only(bottom: AtlasSpacing.sectionLarge),
          children: [
            AtlasContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AtlasPageHeader(
                    title: 'Profil',
                    subtitle:
                        'Identité, synchronisation et préférences Atlas.',
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  _IdentityHero(
                    displayName: displayName,
                    email: session.email,
                    avatarUrl: avatarUrl,
                    session: session,
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  _SyncStatusCard(status: syncStatus),
                  const SizedBox(height: AtlasSpacing.lg),
                  _AssistantEntryCard(
                    onOpen: () => AssistantPage.open(context),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  _ItineraryEntryCard(
                    onOpen: () => TripListPage.open(context),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identité',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Prénom / nom affiché',
                            errorText: _firstNameError,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        Text(
                          'Ville principale',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_preferredCity),
                          initialValue: MoroccoCities.supportedNames
                                  .contains(_preferredCity)
                              ? _preferredCity
                              : UserProfile.defaultPreferredCity,
                          items: [
                            for (final city in MoroccoCities.supportedNames)
                              DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _preferredCity = value);
                          },
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        Text(
                          'Vous êtes',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                        Wrap(
                          spacing: AtlasSpacing.sm,
                          runSpacing: AtlasSpacing.sm,
                          children: [
                            for (final type in AtlasUserType.values)
                              AtlasFilterChip(
                                label: type.label,
                                isSelected: _userType == type,
                                onTap: () =>
                                    setState(() => _userType = type),
                              ),
                          ],
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        Text(
                          'Langue',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                        Wrap(
                          spacing: AtlasSpacing.sm,
                          runSpacing: AtlasSpacing.sm,
                          children: [
                            for (final language
                                in AtlasLanguageLabels.v1Selectable)
                              AtlasFilterChip(
                                label: language.label,
                                isSelected: _language == language,
                                onTap: () =>
                                    setState(() => _language = language),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  AtlasCard(
                    child: ProfilePrayerSection(
                      coordinator: prayerNotificationCoordinator,
                      onPermissionDenied: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Autorisez les notifications dans les réglages.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  _AccountCard(session: session),
                  const SizedBox(height: AtlasSpacing.lg),
                  AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Données & confidentialité',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        Text(
                          'Aucun mot de passe n’est stocké localement. '
                          'La session cloud est gérée par Supabase Auth.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AtlasTextStyles.helper(theme.colorScheme),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        OutlinedButton(
                          onPressed: _busy ? null : _exportData,
                          child: const Text('Exporter mes données'),
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                        TextButton(
                          onPressed: () async {
                            await const OnboardingPreferencesStore().reset();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Introduction réinitialisée. '
                                  'Redémarrez Atlas pour la revoir.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Réafficher l\'introduction'),
                        ),
                        if (session.isSignedIn) ...[
                          const SizedBox(height: AtlasSpacing.sm),
                          TextButton(
                            onPressed: _busy ? null : _deleteAccount,
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Supprimer mon compte'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  FilledButton(
                    onPressed:
                        _isSaving || !_isFormValid ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryEntryCard extends StatelessWidget {
  const _ItineraryEntryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AtlasColors.terracottaGhost,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AtlasColors.terracotta,
            ),
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itinéraires Atlas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  'Planifiez un voyage multi-jours, hors ligne et synchronisé.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AtlasColors.midnightBlueMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _AssistantEntryCard extends StatelessWidget {
  const _AssistantEntryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AtlasColors.subtleGoldMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: AtlasColors.subtleGold,
            ),
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant Atlas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  'Conseils contextualisés à partir de vos données Atlas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AtlasColors.midnightBlueMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.session,
  });

  final String displayName;
  final String? email;
  final String? avatarUrl;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : 'A';

    return AtlasCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AtlasColors.terracottaGhost,
            foregroundColor: AtlasColors.terracotta,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    initial,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    session.isSignedIn
                        ? 'Compte connecté'
                        : 'Mode local / invité',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.status});

  final CloudSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (status.phase) {
      CloudSyncPhase.synced => Icons.cloud_done_outlined,
      CloudSyncPhase.syncing => Icons.cloud_sync_outlined,
      CloudSyncPhase.offline => Icons.cloud_off_outlined,
      CloudSyncPhase.error => Icons.error_outline,
      CloudSyncPhase.idle => Icons.cloud_queue_outlined,
    };

    return AtlasCard(
      child: Row(
        children: [
          Icon(icon, color: AtlasColors.midnightBlueMuted),
          const SizedBox(width: AtlasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synchronisation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  status.labelFr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (status.lastSyncedAt != null) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    'Dernière sync : '
                    '${CasablancaDateFormatter.formatLongDate(status.lastSyncedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AtlasTextStyles.metadata(theme.colorScheme),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({required this.session});

  final AuthSession session;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final result = await AuthScope.of(context).signOut();
    if (!mounted) return;
    setState(() => _signingOut = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Déconnecté — données locales conservées.'
              : result.errorMessage ?? 'Déconnexion impossible.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;

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
          if (session.providers.isNotEmpty) ...[
            Text(
              'Connecté via : '
              '${session.providers.map((p) => p.label).join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AtlasSpacing.md),
          ],
          if (!session.isCloudAvailable)
            const AtlasEmptyState(
              icon: Icons.lock_outline,
              message:
                  'Mode hors ligne — créez un compte lorsque le cloud '
                  'sera disponible.',
            )
          else if (session.isAnonymous) ...[
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
          ] else ...[
            OutlinedButton(
              onPressed: _signingOut ? null : _signOut,
              child: _signingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Se déconnecter'),
            ),
          ],
        ],
      ),
    );
  }
}
