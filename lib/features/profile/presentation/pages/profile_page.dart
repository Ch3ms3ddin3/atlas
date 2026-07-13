import 'package:flutter/material.dart';

import '../../../../core/location/morocco_cities.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../data/profile_validator.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../profile_scope.dart';
import '../widgets/profile_prayer_section.dart';

/// Répond à : « Comment personnaliser mon expérience Atlas ? »
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

  void _validateFirstName() {
    setState(() {
      _firstNameError =
          ProfileValidator.validateFirstName(_firstNameController.text)?.message;
    });
  }

  Future<void> _saveProfile() async {
    _validateFirstName();
    if (!_isFormValid) return;

    setState(() => _isSaving = true);

    final repository = ProfileScope.of(context);
    final success = await repository.save(
      UserProfile(
        firstName: _firstNameController.text,
        preferredCity: _preferredCity,
        language: _language,
        userType: _userType,
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) return;

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

  void _onPermissionDenied() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Autorisez les notifications dans les réglages de votre '
            'téléphone pour activer les rappels de prière.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: AtlasContentContainer(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AtlasSpacing.section),
                    const AtlasPageHeader(
                      title: 'Profil',
                      subtitle:
                          'Personnalisez Atlas — sans compte, vos données restent '
                          'sur cet appareil.',
                    ),
                    const SizedBox(height: AtlasSpacing.xl),
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
                          Text(
                            'Prénom',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.sm),
                          TextField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Votre prénom',
                              errorText: _firstNameError,
                            ),
                            onChanged: (_) => _validateFirstName(),
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          Text(
                            'Ville préférée',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.sm),
                          InputDecorator(
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AtlasSpacing.md,
                                vertical: AtlasSpacing.sm,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _preferredCity,
                                isExpanded: true,
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
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.xs),
                          Text(
                            'Utilisée si la position GPS n\'est pas disponible.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          Text(
                            'Vous êtes',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                                  onTap: () => setState(() => _userType = type),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Langue',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          Wrap(
                            spacing: AtlasSpacing.sm,
                            runSpacing: AtlasSpacing.sm,
                            children: [
                              for (final language in AtlasLanguage.values)
                                AtlasFilterChip(
                                  label: language.label,
                                  isSelected: _language == language,
                                  onTap: () =>
                                      setState(() => _language = language),
                                ),
                            ],
                          ),
                          if (_language != AtlasLanguage.french) ...[
                            const SizedBox(height: AtlasSpacing.sm),
                            Text(
                              'Traduction complète bientôt disponible pour '
                              'English et العربية.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    AtlasCard(
                      child: ProfilePrayerSection(
                        coordinator: prayerNotificationCoordinator,
                        onPermissionDenied: _onPermissionDenied,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        Expanded(
                          child: Text(
                            'Aucun compte · données stockées localement',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AtlasSpacing.sectionLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
