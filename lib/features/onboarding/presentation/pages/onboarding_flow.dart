import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../auth/presentation/auth_scope.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../data/onboarding_preferences_store.dart';
import 'onboarding_extras_page.dart';
import 'onboarding_preferences_page.dart';
import 'onboarding_welcome_page.dart';

/// Parcours d'accueil — exactement 3 écrans.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.onCompleted,
    this.onboardingStore = const OnboardingPreferencesStore(),
  });

  final VoidCallback onCompleted;
  final OnboardingPreferencesStore onboardingStore;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  int _index = 0;
  bool _initialized = false;
  bool _completingFromAuth = false;

  late String _city;
  late AtlasLanguage _language;
  late AtlasUserType _userType;
  ProfileRepository? _profileRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileRepo = ProfileScope.of(context);
    if (!_initialized || !identical(profileRepo, _profileRepository)) {
      _profileRepository = profileRepo;
      final profile = profileRepo.profile;
      _city = _resolveInitialCity(profile);
      _language = profile.language;
      _userType = profile.userType;
      _initialized = true;
    }
  }

  String _resolveInitialCity(UserProfile profile) {
    final preferred = profile.preferredCity.trim();
    if (preferred.isNotEmpty) return preferred;
    return UserProfile.defaultPreferredCity;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _savePreferences() async {
    final repository = ProfileScope.of(context);
    final current = repository.profile;
    await repository.save(
      current.copyWith(
        preferredCity: _city,
        language: _language,
        userType: _userType,
      ),
    );
  }

  Future<void> _complete() async {
    await _savePreferences();
    await widget.onboardingStore.markCompleted();
    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.session.isSignedIn &&
            _index == 2 &&
            !_completingFromAuth) {
          _completingFromAuth = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _complete();
          });
        }

        return Material(
          color: AtlasColors.warmOffWhite,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AtlasSpacing.xl,
                    AtlasSpacing.md,
                    AtlasSpacing.xl,
                    AtlasSpacing.sm,
                  ),
                  child: _OnboardingProgress(index: _index, total: 3),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    OnboardingWelcomePage(
                      onContinue: () => _goTo(1),
                      onSkip: () => _goTo(1),
                    ),
                    OnboardingPreferencesPage(
                      city: _city,
                      language: _language,
                      userType: _userType,
                      onCityChanged: (value) => setState(() => _city = value),
                      onLanguageChanged: (value) =>
                          setState(() => _language = value),
                      onUserTypeChanged: (value) =>
                          setState(() => _userType = value),
                      onContinue: () async {
                        await _savePreferences();
                        if (!mounted) return;
                        _goTo(2);
                      },
                    ),
                    OnboardingExtrasPage(
                      onContinueWithoutAccount: _complete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({
    required this.index,
    required this.total,
  });

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${index + 1} sur $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: AtlasSpacing.sm),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= index
                      ? AtlasColors.terracotta
                      : AtlasColors.sandMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
