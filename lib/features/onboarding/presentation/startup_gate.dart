import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../auth/presentation/widgets/auth_password_recovery_listener.dart';
import '../../content_reports/domain/content_reports_repository.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../profile/data/syncing_profile_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/presentation/profile_scope.dart';
import '../../shell/presentation/app_shell.dart';
import '../data/onboarding_preferences_store.dart';
import 'pages/onboarding_flow.dart';
import 'widgets/atlas_splash_view.dart';

enum _StartupDestination { splash, onboarding, home }

/// Porte d'entrée : splash → onboarding (si besoin) → coque principale.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.authRepository,
    this.profileRepository,
    this.favoritesRepository,
    this.contentReportsRepository,
    this.onboardingStore = const OnboardingPreferencesStore(),
  });

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;

  /// Shared with [AtlasApp]'s scopes above the navigator when set.
  final FavoritesRepository? favoritesRepository;
  final ContentReportsRepository? contentReportsRepository;
  final OnboardingPreferencesStore onboardingStore;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final bool _ownsAuthRepository;
  late final bool _ownsProfileRepository;

  _StartupDestination _destination = _StartupDestination.splash;

  @override
  void initState() {
    super.initState();
    _ownsAuthRepository = widget.authRepository == null;
    _ownsProfileRepository = widget.profileRepository == null;
    _authRepository = widget.authRepository ?? SupabaseAuthRepository();
    _profileRepository =
        widget.profileRepository ?? SyncingProfileRepository();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _authRepository.load(),
      _profileRepository.load(),
    ]);
    final completed = await widget.onboardingStore.isCompleted();

    if (!mounted) return;

    if (completed || _authRepository.session.isSignedIn) {
      if (!completed) {
        await widget.onboardingStore.markCompleted();
      }
      setState(() => _destination = _StartupDestination.home);
      return;
    }

    setState(() => _destination = _StartupDestination.onboarding);
  }

  void _onOnboardingCompleted() {
    setState(() => _destination = _StartupDestination.home);
  }

  @override
  void dispose() {
    if (_ownsAuthRepository) {
      _authRepository.dispose();
    }
    if (_ownsProfileRepository) {
      _profileRepository.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion = (media?.disableAnimations ?? false) ||
        SchedulerBinding
            .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    final child = switch (_destination) {
      _StartupDestination.splash => AtlasSplashView(reduceMotion: reduceMotion),
      _StartupDestination.onboarding => ProfileScope(
          repository: _profileRepository,
          child: OnboardingFlow(
            onboardingStore: widget.onboardingStore,
            onCompleted: _onOnboardingCompleted,
          ),
        ),
      _StartupDestination.home => AppShell(
          authRepository: _authRepository,
          profileRepository: _profileRepository,
          favoritesRepository: widget.favoritesRepository,
          contentReportsRepository: widget.contentReportsRepository,
        ),
    };

    return AuthScope(
      repository: _authRepository,
      child: AuthPasswordRecoveryListener(
        child: AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          child: KeyedSubtree(
            key: ValueKey(_destination),
            child: child,
          ),
        ),
      ),
    );
  }
}
