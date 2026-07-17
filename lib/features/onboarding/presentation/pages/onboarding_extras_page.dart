import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/notifications/prayer_notification_lead_time.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../auth/presentation/widgets/auth_form_sheet.dart';

/// Écran 3 — notifications optionnelles et compte optionnel.
class OnboardingExtrasPage extends StatefulWidget {
  const OnboardingExtrasPage({
    super.key,
    required this.onContinueWithoutAccount,
  });

  final Future<void> Function() onContinueWithoutAccount;

  @override
  State<OnboardingExtrasPage> createState() => _OnboardingExtrasPageState();
}

class _OnboardingExtrasPageState extends State<OnboardingExtrasPage> {
  bool _notificationsEnabled = false;
  bool _isBusy = false;

  Future<void> _onNotificationsChanged(bool value) async {
    if (!value) {
      setState(() => _notificationsEnabled = false);
      await prayerNotificationCoordinator
          .setLeadTime(PrayerNotificationLeadTime.disabled);
      return;
    }

    setState(() => _isBusy = true);
    final granted = await prayerNotificationCoordinator
        .setLeadTime(PrayerNotificationLeadTime.atPrayerTime);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _notificationsEnabled = granted || kIsWeb;
    });

    if (!granted && !kIsWeb) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications non activées — vous pourrez réessayer plus tard.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _finish() async {
    setState(() => _isBusy = true);
    await widget.onContinueWithoutAccount();
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: AtlasContentContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dernière étape',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                'Tout est optionnel — Atlas fonctionne sans compte.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AtlasColors.midnightBlueMuted,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xxl),
              Expanded(
                child: ListView(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rappels utiles'),
                      subtitle: const Text(
                        'Horaires de prière et alertes importantes. '
                        'La permission système n’est demandée que si vous activez.',
                      ),
                      value: _notificationsEnabled,
                      onChanged: _isBusy ? null : _onNotificationsChanged,
                    ),
                    const SizedBox(height: AtlasSpacing.xxl),
                    Text(
                      'Compte Atlas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      'Créez un compte pour synchroniser profil et favoris '
                      'entre vos appareils. Vous pouvez continuer sans.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AtlasColors.midnightBlueMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isBusy ? null : _finish,
                child: _isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuer sans compte'),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              OutlinedButton(
                onPressed: _isBusy
                    ? null
                    : () => AuthFormSheet.show(
                          context,
                          initialMode: AuthFormMode.signIn,
                        ),
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () => AuthFormSheet.show(
                          context,
                          initialMode: AuthFormMode.signUp,
                        ),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
