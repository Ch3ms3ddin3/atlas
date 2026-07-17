import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../procedures/domain/procedure_repository.dart';
import '../../../procedures/presentation/pages/procedures_page.dart';
import '../../data/at_bootstrap.dart';
import '../../data/at_calculator.dart';
import '../../domain/at_repository.dart';
import '../../domain/models/at_vehicle.dart';
import '../at_scope.dart';
import '../at_status_colors.dart';
import '../widgets/at_timeline.dart';
import '../widgets/at_vehicle_form_sheet.dart';

/// Ouvre le suivi « Mes véhicules au Maroc ».
Future<void> openVehiclesTracker(BuildContext context) {
  return Navigator.of(context).push<void>(
    AtlasPageRoute<void>(page: const AtTrackerPage()),
  );
}

/// Page complète de suivi des véhicules / admission temporaire.
class AtTrackerPage extends StatefulWidget {
  const AtTrackerPage({super.key});

  @override
  State<AtTrackerPage> createState() => _AtTrackerPageState();
}

class _AtTrackerPageState extends State<AtTrackerPage> {
  AtRepository? _repository;
  String? _selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AtScope.of(context);
    if (!identical(repository, _repository)) {
      _repository?.removeListener(_onRepoChanged);
      _repository = repository;
      _repository!.addListener(_onRepoChanged);
      _ensureSelection();
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    setState(_ensureSelection);
  }

  void _ensureSelection() {
    final active = _repository?.activeVehicles ?? const [];
    if (active.isEmpty) {
      _selectedId = null;
      return;
    }
    if (_selectedId == null ||
        !active.any((v) => v.id == _selectedId)) {
      _selectedId = AtCalculator.mostUrgent(active)?.id ?? active.first.id;
    }
  }

  AtVehicle? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final v in _repository?.activeVehicles ?? const []) {
      if (v.id == id) return v;
    }
    return null;
  }

  Future<void> _addVehicle() async {
    final drafted = await AtVehicleFormSheet.show(context);
    if (drafted == null || !mounted) return;

    final wasEmpty = _repository!.activeVehicles.isEmpty;
    final ok = await _repository!.addVehicle(drafted);
    if (!ok || !mounted) return;

    setState(() => _selectedId = drafted.id);
    unawaited(atNotificationCoordinator.sync(force: true));

    if (wasEmpty && !_repository!.notificationPromptShown) {
      await _askNotificationsOnce();
    }
  }

  Future<void> _editVehicle(AtVehicle vehicle) async {
    final drafted = await AtVehicleFormSheet.show(context, initial: vehicle);
    if (drafted == null || !mounted) return;
    await _repository!.updateVehicle(drafted);
    unawaited(atNotificationCoordinator.sync(force: true));
  }

  Future<void> _deleteVehicle(AtVehicle vehicle) async {
    final confirmed = await showAtlasDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(
          '${vehicle.label} (${vehicle.plate}) sera retiré du suivi local.',
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
      ),
    );
    if (confirmed != true || !mounted) return;
    await _repository!.deleteVehicle(vehicle.id);
    unawaited(atNotificationCoordinator.sync(force: true));
  }

  Future<void> _askNotificationsOnce() async {
    await _repository!.markNotificationPromptShown();
    if (!mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les rappels ne sont pas disponibles sur le web.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final enable = await showAtlasDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activer les rappels ?'),
        content: const Text(
          'Atlas peut vous rappeler 30, 15, 7, 3 et 1 jour avant '
          'l\'expiration, ainsi que le jour J. '
          'Les rappels restent désactivés tant que vous n\'acceptez pas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (enable == true) {
      final granted = await atNotificationCoordinator.enableNotifications();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autorisez les notifications dans les réglages de votre téléphone.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      final granted = await atNotificationCoordinator.enableNotifications();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autorisez les notifications dans les réglages de votre téléphone.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await atNotificationCoordinator.disableNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = _repository;
    final vehicles = repo?.activeVehicles ?? const [];
    final selected = _selected;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes véhicules au Maroc'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un véhicule',
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: AtlasContentContainer(
          child: vehicles.isEmpty
              ? _EmptyTracker(onAdd: _addVehicle)
              : ListView(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
                  children: [
                    const SizedBox(height: AtlasSpacing.lg),
                    AtlasPageHeader(
                      title: selected?.label ?? 'Mes véhicules',
                      subtitle: selected == null
                          ? 'Suivi de vos admissions temporaires'
                          : '${selected.plate} · ${selected.countryLabel} · '
                              '${selected.type.labelFr}',
                      footnote:
                          'Suivi personnel local — aucune validation douanière.',
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    if (isWide && selected != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _HeroStatus(vehicle: selected)),
                          const SizedBox(width: AtlasSpacing.xl),
                          Expanded(child: AtTimeline(vehicle: selected)),
                        ],
                      )
                    else ...[
                      if (selected != null) ...[
                        _HeroStatus(vehicle: selected),
                        const SizedBox(height: AtlasSpacing.section),
                        Text(
                          'Timeline',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        AtTimeline(vehicle: selected),
                      ],
                    ],
                    if (selected?.notes != null &&
                        selected!.notes!.isNotEmpty) ...[
                      const SizedBox(height: AtlasSpacing.section),
                      AtlasCard(
                        child: Text(
                          selected.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    if (selected != null) ...[
                      const SizedBox(height: AtlasSpacing.xl),
                      Wrap(
                        spacing: AtlasSpacing.md,
                        runSpacing: AtlasSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _editVehicle(selected),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Modifier'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _deleteVehicle(selected),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Supprimer'),
                          ),
                          TextButton(
                            onPressed: () => openProcedureGuideById(
                              context,
                              ProcedureRepository(),
                              'admission-temporaire',
                            ),
                            child: const Text('Guide Admission temporaire'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AtlasSpacing.section),
                    Text(
                      'Tous mes véhicules',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    for (final vehicle in vehicles) ...[
                      _VehicleListTile(
                        vehicle: vehicle,
                        selected: vehicle.id == _selectedId,
                        onTap: () => setState(() => _selectedId = vehicle.id),
                      ),
                      const SizedBox(height: AtlasSpacing.md),
                    ],
                    const SizedBox(height: AtlasSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: _addVehicle,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un autre véhicule'),
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rappels d\'échéance'),
                      subtitle: Text(
                        kIsWeb
                            ? 'Indisponible sur le web'
                            : '30, 15, 7, 3, 1 jour et jour J — désactivés par défaut',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AtlasTextStyles.helper(theme.colorScheme),
                        ),
                      ),
                      value: repo?.notificationsEnabled ?? false,
                      onChanged: kIsWeb ? null : _toggleNotifications,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyTracker extends StatelessWidget {
  const _EmptyTracker({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AtlasSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: AtlasColors.midnightBlueFaint,
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Text(
              'Aucun véhicule suivi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              'Ajoutez votre véhicule pour suivre l\'admission temporaire '
              'et recevoir des rappels avant l\'expiration.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AtlasTextStyles.helper(theme.colorScheme),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtlasSpacing.xxl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un véhicule'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.vehicle});

  final AtVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining =
        AtCalculator.remainingDays(expiryDate: vehicle.expiryDate);
    final status = AtCalculator.status(expiryDate: vehicle.expiryDate);
    final progress = AtCalculator.progress(
      remainingDays: remaining,
      durationDays: vehicle.durationDays,
    );
    final color = AtStatusColors.forStatus(status);

    return AtlasCard(
      emphasis: AtlasCardEmphasis.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Admission temporaire',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AtlasTextStyles.cardLabel(theme.colorScheme),
                  ),
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.md,
                  vertical: AtlasSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AtCalculator.statusLabel(status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Text(
            AtCalculator.remainingLabel(remainingDays: remaining),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AtlasColors.sandMuted.withValues(alpha: 0.6),
              color: color,
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            'Durée déclarée : ${vehicle.durationDays} jours',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AtlasTextStyles.metadata(theme.colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleListTile extends StatelessWidget {
  const _VehicleListTile({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final AtVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining =
        AtCalculator.remainingDays(expiryDate: vehicle.expiryDate);
    final status = AtCalculator.status(expiryDate: vehicle.expiryDate);
    final color = AtStatusColors.forStatus(status);

    return AtlasCard(
      onTap: onTap,
      emphasis: selected ? AtlasCardEmphasis.standard : AtlasCardEmphasis.compact,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  '${vehicle.plate} · '
                  '${AtCalculator.remainingLabel(remainingDays: remaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AtlasTextStyles.helper(theme.colorScheme),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.circle, size: 10, color: color),
        ],
      ),
    );
  }
}
