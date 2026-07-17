import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/atlas_error_ui.dart';
import '../../../../core/performance/atlas_performance.dart';
import '../../../../core/platform/atlas_build_info.dart';
import '../../../../core/supabase/supabase_health_repository.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../../design_system/widgets/atlas_primary_button.dart';
import '../../../auth/domain/auth_session.dart';
import '../../../auth/presentation/auth_scope.dart';
import '../../../sync/domain/cloud_sync_status.dart';
import '../../../sync/presentation/sync_scope.dart';
import '../../data/beta_feedback_repository.dart';
import '../beta_feedback_scope.dart';

/// Page diagnostics cachée (accès via taps sur la bannière beta).
class BetaDiagnosticsPage extends StatefulWidget {
  const BetaDiagnosticsPage({super.key});

  @override
  State<BetaDiagnosticsPage> createState() => _BetaDiagnosticsPageState();
}

class _BetaDiagnosticsPageState extends State<BetaDiagnosticsPage> {
  AtlasBuildInfo? _info;
  String? _apiHealth;
  String? _cacheSize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await AtlasBuildInfo.load();
    final health = await SupabaseHealthRepository().checkHealth();
    final cache = await _estimateCacheSize();
    if (!mounted) return;
    setState(() {
      _info = info;
      _apiHealth = health.ok
          ? 'OK (${health.latency?.inMilliseconds ?? '?'} ms)'
          : 'KO — ${health.errorMessage ?? 'indisponible'}';
      _cacheSize = cache;
      _loading = false;
    });
  }

  Future<String> _estimateCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      var approx = 0;
      for (final key in keys) {
        approx += key.length;
        final value = prefs.get(key);
        if (value is String) {
          approx += value.length;
        } else if (value != null) {
          approx += value.toString().length;
        }
      }
      if (approx < 1024) return '~$approx B ($keys.length clés)';
      return '~${(approx / 1024).toStringAsFixed(1)} KB ($keys.length clés)';
    } catch (_) {
      return 'indisponible';
    }
  }

  Future<Map<String, dynamic>> _buildPayload({
    required AuthSession session,
    required CloudSyncStatus? sync,
    required BetaFeedbackRepository? feedback,
  }) async {
    final info = _info ?? await AtlasBuildInfo.load();
    return {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'app': {
        'name': info.appName,
        'package': info.packageName,
        'version': info.version,
        'build': info.buildNumber,
        'platform': info.platformLabel,
        'device': info.deviceLabel,
      },
      'auth': {
        'kind': session.kind.name,
        'signed_in': session.kind == AuthSessionKind.signedIn,
        'has_user_id': session.userId != null,
      },
      'sync': {
        'phase': sync?.phase.name,
        'label': sync?.labelFr,
        'last_synced_at': sync?.lastSyncedAt?.toIso8601String(),
        'error': sync?.errorMessage,
      },
      'api_health': _apiHealth,
      'cache_size': _cacheSize,
      'pending_feedback': feedback?.pending.length ?? 0,
      'performance': AtlasPerformance.snapshot(),
    };
  }

  Future<void> _exportJson() async {
    final session = AuthScope.of(context).session;
    final sync = SyncScope.maybeOf(context)?.status;
    final feedback = BetaFeedbackScope.maybeOf(context);
    final payload = await _buildPayload(
      session: session,
      sync: sync,
      feedback: feedback,
    );
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    showAtlasSuccessSnack(context, 'Diagnostics copiés dans le presse-papiers');
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session;
    final sync = SyncScope.maybeOf(context)?.status;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics beta'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AtlasSpacing.lg),
              children: [
                const AtlasPageHeader(
                  title: 'Diagnostics',
                  subtitle: 'Informations pour le support private beta',
                ),
                const SizedBox(height: AtlasSpacing.lg),
                AtlasCard(
                  child: Column(
                    children: [
                      _row(theme, 'Version', _info?.version ?? '—'),
                      _row(theme, 'Build', _info?.buildNumber ?? '—'),
                      _row(theme, 'Plateforme', _info?.platformLabel ?? '—'),
                      _row(theme, 'Appareil', _info?.deviceLabel ?? '—'),
                      _row(theme, 'Package', _info?.packageName ?? '—'),
                      _row(theme, 'Session', session.kind.name),
                      _row(
                        theme,
                        'Connecté',
                        session.kind == AuthSessionKind.signedIn ? 'oui' : 'non',
                      ),
                      _row(theme, 'Sync', sync?.labelFr ?? '—'),
                      _row(
                        theme,
                        'Dernière sync',
                        sync?.lastSyncedAt?.toIso8601String() ?? '—',
                      ),
                      _row(theme, 'API', _apiHealth ?? '—'),
                      _row(theme, 'Cache prefs', _cacheSize ?? '—'),
                      _row(
                        theme,
                        'Startup',
                        AtlasPerformance.startupToFirstFrame == null
                            ? '—'
                            : '${AtlasPerformance.startupToFirstFrame!.inMilliseconds} ms',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AtlasSpacing.lg),
                AtlasPrimaryButton(
                  label: 'Exporter JSON',
                  icon: Icons.copy_all_outlined,
                  onPressed: _exportJson,
                ),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasSecondaryButton(
                  label: 'Actualiser',
                  onPressed: _load,
                ),
              ],
            ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
